use actix_governor::{Governor, GovernorConfigBuilder};
use actix_identity::{CookieIdentityPolicy, Identity, IdentityService};
use actix_session::{config::PersistentSession, SessionMiddleware};
use actix_web::{
    cookie::Key,
    dev::Payload,
    error,
    http::header::ContentType,
    middleware::{self, DefaultHeaders},
    web, App, Error as AWError, FromRequest, HttpRequest, HttpResponse, HttpServer, Responder,
};
use dotenv::dotenv;
use openssl::{
    ssl::{SslAcceptor, SslFiletype, SslMethod},
    hash::MessageDigest,
    pkcs7::Pkcs7Flags,
    pkcs12::Pkcs12,
    stack::Stack,
};
use r2d2_sqlite::{self, SqliteConnectionManager};
use serde::{Deserialize, Serialize};
use serde_json::json;
use std::{collections::HashMap, env, fs, io, pin::Pin, sync::RwLock, time::{SystemTime, UNIX_EPOCH}, path::PathBuf};
use tempfile::tempdir;

mod auth;
mod db_main;
mod db_auth;
mod pass;
mod session;

// hashmap containing user session IDs
#[derive(Serialize, Deserialize, Default, Clone)]
struct Sessions {
    user_map: HashMap<String, db_auth::User>,
}

// gets a user object from requests. needed for db_auth::User param in handlers
impl FromRequest for db_auth::User {
    type Error = actix_web::Error;
    type Future = Pin<Box<dyn futures_util::Future<Output = Result<db_auth::User, Self::Error>>>>;

    fn from_request(req: &HttpRequest, payload: &mut Payload) -> Self::Future {
        let fut = Identity::from_request(req, payload);
        let session: Option<&web::Data<RwLock<Sessions>>> = req.app_data();
        if session.is_none() {
            return Box::pin(async { Err(error::ErrorUnauthorized("{\"status\": \"unauthorized\"}")) });
        }
        let session = session.unwrap().clone();
        Box::pin(async move {
            if let Some(identity) = fut.await?.identity() {
                if let Some(user) = session.read().unwrap().user_map.get(&identity).map(|x| x.clone()) {
                    return Ok(user);
                }
            };
            Err(error::ErrorUnauthorized("{\"status\": \"unauthorized\"}"))
        })
    }
}

struct Databases {
    auth: db_auth::Pool,
    main: db_main::Pool,
}

fn get_secret_key() -> Key {
    Key::generate()
}

async fn auth_post_create(db: web::Data<Databases>, data: web::Json<auth::CreateForm>) -> impl Responder {
    auth::create_account(&db.auth, data).await
}

// login endpoint
async fn auth_post_login(db: web::Data<Databases>, session: web::Data<RwLock<Sessions>>, identity: Identity, data: web::Json<auth::LoginForm>) -> impl Responder {
    auth::login(&db.auth, session, identity, data, false).await
}

async fn auth_post_login_admin(db: web::Data<Databases>, session: web::Data<RwLock<Sessions>>, identity: Identity, data: web::Json<auth::LoginForm>) -> impl Responder {
    auth::login(&db.auth, session, identity, data, true).await
}

// delete account endpoint
async fn auth_post_delete(db: web::Data<Databases>, data: web::Json<auth::LoginForm>, session: web::Data<RwLock<crate::Sessions>>, identity: Identity) -> Result<HttpResponse, AWError> {
    Ok(auth::delete_account(&db.auth, data, session, identity).await?)
}

// destroy session endpoint
async fn auth_get_logout(session: web::Data<RwLock<Sessions>>, identity: Identity) -> impl Responder {
    auth::logout(session, identity).await
}

// get to confirm session status and obtain current user id
async fn auth_get_whoami(db: web::Data<Databases>, user: db_auth::User) -> Result<HttpResponse, AWError> {
    Ok(HttpResponse::Ok()
        .insert_header(("Cache-Control", "no-cache"))
        .json(db_auth::execute_scores(&db.auth, db_auth::AuthData::GetCurrentUserScore, user.id).await?))
}

async fn auth_get_admin(user: db_auth::User) -> Result<HttpResponse, AWError> {
    if user.data == "admin" {
        Ok(HttpResponse::Ok()
            .insert_header(("Cache-Control", "no-cache"))
            .body("true"))
    } else {
        Ok(HttpResponse::Forbidden()
            .insert_header(("Cache-Control", "no-cache"))
            .body("false"))
    }
}

async fn board_get_lifetime_top(db: web::Data<Databases>) -> Result<HttpResponse, AWError> {
    Ok(HttpResponse::Ok()
        .insert_header(("Cache-Control", "max-age=60"))
        .json(db_auth::execute_scores(&db.auth, db_auth::AuthData::GetUserScores, 0).await?)
    )
}

async fn board_get_lifetime_all(db: web::Data<Databases>, user: db_auth::User) -> Result<HttpResponse, AWError> {
    Ok(HttpResponse::Ok()
        .insert_header(("Cache-Control", "max-age=60"))
        .json(db_auth::execute_scores(&db.auth, db_auth::AuthData::GetUserScores, user.id).await?)
    )
}

async fn events_get_all(db: web::Data<Databases>, user: db_auth::User) -> Result<HttpResponse, AWError> {
    if user.data == "admin" {
        Ok(HttpResponse::Ok()
            .insert_header(("Cache-Control", "max-age=150"))
            .json(db_main::execute_events(&db.main, db_main::EventQuery::GetAllEvents, 0).await?)
        )
    } else {
        Err(error::ErrorUnauthorized("{\"status\": \"unauthorized\"}"))
    }
}

async fn events_get_future(db: web::Data<Databases>) -> Result<HttpResponse, AWError> {
    let start = SystemTime::now();
    let since_the_epoch = start
        .duration_since(UNIX_EPOCH)
        .expect("time just went fucking backwards");

    Ok(HttpResponse::Ok()
        .insert_header(("Cache-Control", "max-age=150"))
        .json(db_main::execute_events(&db.main, db_main::EventQuery::GetFutureEvents, since_the_epoch.as_millis()).await?)
    )
}

async fn tickets_get_all(db: web::Data<Databases>, user: db_auth::User) -> Result<HttpResponse, AWError> {
    if user.data == "admin" {
        Ok(HttpResponse::Ok()
            .insert_header(("Cache-Control", "no-cache"))
            .json(db_main::execute_tickets(&db.main, db_main::TicketQuery::GetAllTickets, "".to_string()).await?))
    } else {
        Err(error::ErrorUnauthorized("{\"status\": \"unauthorized\"}"))
    }
}

async fn tickets_create_ticket(req: HttpRequest, db: web::Data<Databases>, user: db_auth::User) -> Result<HttpResponse, AWError> {
    if user.data == "admin" {
        let event = db_main::execute_events(&db.main, db_main::EventQuery::GetEventById, req.match_info().get("event_id").unwrap().parse::<i64>().unwrap() as u128).await?;
        let student_id = req.match_info().get("user_id").unwrap();
        let target_user = db_auth::get_user_student_id(&db.auth, student_id.to_string()).await?;
        if event.len() == 1 {
            let start = SystemTime::now();
            let since_the_epoch = start
                .duration_since(UNIX_EPOCH)
                .expect("time just went fucking backwards");
            let owned_tickets = db_main::execute_tickets(&db.main, db_main::TicketQuery::GetUserEventTickets, format!("{}_{}", target_user.id, event[0].id)).await?;
            if owned_tickets.len() == 0 {
                let point_deduction = db_auth::update_points(&db.auth, target_user.id, event[0].point_reward).await?;
                if point_deduction {
                    Ok(HttpResponse::Ok()
                        .insert_header(("Cache-Control", "no-cache"))
                        .json(db_main::create_ticket(&db.main, event[0].id, target_user.id, since_the_epoch.as_millis()).await?))
                } else {
                    Err(error::ErrorInternalServerError("{\"status\": \"point_transaction_failed\"}"))
                }
            } else {
                Err(error::ErrorLocked("{\"status\": \"ticket_sale_ended\"}"))
            }
        } else {
            Err(error::ErrorBadRequest("{\"status\": \"bad_event_id\"}"))
        }

    } else {
        Err(error::ErrorUnauthorized("{\"status\": \"unauthorized\"}"))
    }
}

async fn tickets_generate_pass(req: HttpRequest, db: web::Data<Databases>, user: db_auth::User) -> impl Responder {
    let ticket_id = req.match_info().get("ticket_id").unwrap();
    let ticket_results = db_main::execute_tickets(&db.main, db_main::TicketQuery::GetTicketById, ticket_id.to_string()).await.expect("failed to get ticket");
    if ticket_results.len() == 1 {
        if ticket_results[0].holder_id == user.id {
            let pass_dir = tempdir().expect("tmp dir creation failure");
            let pass_dir_path = pass_dir.path().to_owned();
            let corresponding_event = db_main::execute_events(&db.main, db_main::EventQuery::GetEventById, ticket_results[0].event_id as u128).await.expect("failed to get event");
            let pass_json = pass::generate_pass_json(ticket_results[0].clone(), corresponding_event[0].clone(), user);
            // write pass data
            fs::write(pass_dir_path.join("pass.json"), &pass_json.to_string()).expect("failed to write pass");
            // copy images
            let _ = fs::copy("./passes/background@2x.png", pass_dir_path.join("background@2x.png"));
            let _ = fs::copy("./passes/icon@2x.png", pass_dir_path.join("icon@2x.png"));
            let _ = fs::copy("./passes/logo@2x.png", pass_dir_path.join("logo@2x.png"));
            // make manifest
            let manifest_json = json!({
                "pass.json": calculate_hash(pass_dir_path.join("pass.json")),
                "background@2x.png": calculate_hash(pass_dir_path.join("background@2x.png")),
                "icon@2x.png": calculate_hash(pass_dir_path.join("icon@2x.png")),
                "logo@2x.png": calculate_hash(pass_dir_path.join("logo@2x.png")),
            });
            fs::write(pass_dir_path.join("manifest.json"), manifest_json.to_string()).expect("failed to write manifest");
            let _ = sign_pass(&pass_dir_path);
            let output_dir = tempdir().expect("could not create dir for pass");
            let pkpass_path = package_pass(&pass_dir_path, output_dir.path().to_path_buf());
            let pkpass_bytes = fs::read(pkpass_path).expect("Failed to read .pkpass file");
            HttpResponse::Ok()
                .content_type("application/vnd.apple.pkpass")
                .body(pkpass_bytes)
        } else {
            HttpResponse::Unauthorized()
                .content_type(ContentType::json())
                .body("{\"status\": \"unauthorized\"}")
        }
    } else {
        HttpResponse::BadRequest()
            .content_type(ContentType::json())
            .body("{\"status\": \"invalid_id\"}")
    }
}

// part of pass creation
fn calculate_hash(file_path: PathBuf) -> String {
    let content = fs::read(&file_path).expect("failed to read pass file");
    let digest = openssl::hash::hash(MessageDigest::sha1(), &content).expect("failed to has pass file");
    let hex_digest = digest.iter().map(|b| format!("{:02x}", b)).collect::<Vec<_>>().join("");
    hex_digest
}
fn sign_pass(pass_dir_path: &PathBuf) -> PathBuf {
    let manifest_json_path = pass_dir_path.join("manifest.json");
    let manifest_json_data = fs::read(&manifest_json_path)
        .expect("failed to read manifest.json file");

    let pkcs12_file = fs::read("./passes/certs/Certificates.p12")
        .expect("failed to read PKCS #12 file");
    let pkcs12 = Pkcs12::from_der(&pkcs12_file)
        .expect("failed to parse PKCS #12 file");

    let pkcs12_data = pkcs12.parse2("")
        .expect("failed to parse PKCS #12 data");

    let pkcs7 = openssl::pkcs7::Pkcs7::sign(&pkcs12_data.cert.unwrap(), &pkcs12_data.pkey.unwrap(), &pkcs12_data.ca.unwrap_or(Stack::new().unwrap()), &manifest_json_data, Pkcs7Flags::empty())
        .expect("failed to sign manifest.json");

    let signature_path = pass_dir_path.join("signature");
    
    let pkcs7_der = pkcs7.to_der()
        .expect("failed to serialize PKCS #7 to DER");
    fs::write(pass_dir_path.join("signature"), pkcs7_der)
        .expect("failed to write PKCS #7 signature to file");

    signature_path
}
fn package_pass(pass_dir_path: &PathBuf, output_dir: PathBuf) -> PathBuf {
    let status = std::process::Command::new("zip")
        .args(&["-r", "-q", "-0", "-X", output_dir.join("pass.pkpass").to_str().unwrap(), "."])
        .current_dir(&pass_dir_path)
        .status()
        .expect("failed to execute zip");

    if !status.success() {
        panic!("failed to package pass");
    }

    output_dir.join("pass.pkpass")
}
// end pass creation extras

const APPLE_APP_SITE_ASSOC: &str = "{\"webcredentials\":{\"apps\":[\"D6MFYYVHA8.com.jayagra.ma-central\", \"D6MFYYVHA8.com.jayagra.ma-central-admin\"]}}";
async fn misc_apple_app_site_association() -> Result<HttpResponse, AWError> {
    Ok(HttpResponse::Ok().content_type(ContentType::json()).body(APPLE_APP_SITE_ASSOC))
}

#[actix_web::main]
async fn main() -> io::Result<()> {
    // load environment variables from .env file
    dotenv().ok();

    // hashmap w: web::Data<RwLock<Sessions>>ith user sessions in it
    let sessions: web::Data<RwLock<Sessions>> = web::Data::new(RwLock::new(Sessions { user_map: HashMap::new() }));

    // auth database connection
    let auth_db_manager = SqliteConnectionManager::file("data_auth.db");
    let auth_db_pool = db_auth::Pool::new(auth_db_manager).unwrap();
    let auth_db_connection = auth_db_pool.get().expect("auth db: connection failed");
    auth_db_connection.execute_batch("PRAGMA journal_mode=WAL;").expect("auth db: WAL failed");
    drop(auth_db_connection);

    // man database connection
    let main_db_manager = SqliteConnectionManager::file("data_main.db");
    let main_db_pool = db_auth::Pool::new(main_db_manager).unwrap();
    let main_db_connection = main_db_pool.get().expect("main db: connection failed");
    main_db_connection.execute_batch("PRAGMA journal_mode=WAL;").expect("main db: WAL failed");
    drop(main_db_connection);

    let secret_key = get_secret_key();

    // ratelimiting with governor
    let governor_conf = GovernorConfigBuilder::default()
        // these may be a lil high but whatever
        .per_nanosecond(100)
        .burst_size(25000)
        .finish()
        .unwrap();

    /*
     *  generate a self-signed certificate for localhost (run from bearTracks directory):
     *  openssl req -x509 -newkey rsa:4096 -nodes -keyout ./ssl/key.pem -out ./ssl/cert.pem -days 365 -subj '/CN=localhost'
     */
    // create ssl builder for tls config
    let mut builder = SslAcceptor::mozilla_intermediate(SslMethod::tls()).unwrap();
    builder.set_private_key_file("./ssl/key.pem", SslFiletype::PEM).unwrap();
    builder.set_certificate_chain_file("./ssl/cert.pem").unwrap();

    // config done. now, create the new HttpServer
    log::info!("[OK] starting M-A Central Services (macsvc) on port 443 and 80");

    HttpServer::new(move || {
        // other static directories
        App::new()
            // add databases to app data
            .app_data(web::Data::new(Databases {
                auth: auth_db_pool.clone(),
                main: main_db_pool.clone(),
            }))
            // add sessions to app data
            .app_data(sessions.clone())
            // use governor ratelimiting as middleware
            .wrap(Governor::new(&governor_conf))
            // ident service
            .wrap(IdentityService::new(
                CookieIdentityPolicy::new(&[0; 32])
                    .name("bear_tracks")
                    .max_age_secs(actix_web::cookie::time::Duration::weeks(2).whole_seconds())
                    .secure(false),
            ))
            // logging middleware
            .wrap(middleware::Logger::default())
            // session middleware
            .wrap(
                SessionMiddleware::builder(session::MemorySession, secret_key.clone())
                    .cookie_name("bear_tracks-ms".to_string())
                    .cookie_http_only(true)
                    .cookie_secure(false)
                    .session_lifecycle(
                        PersistentSession::default()
                            .session_ttl(actix_web::cookie::time::Duration::weeks(2)),
                    )
                    .build(),
            )
            // default headers for caching. overridden on most all api endpoints
            .wrap(
                DefaultHeaders::new()
                    .add(("Cache-Control", "public, max-age=23328000"))
                    .add(("X-macsvc", "1.0.0")),
            )
            .service(
                web::resource("/apple-app-site-association")
                    .route(web::get().to(misc_apple_app_site_association)),
            )
            .service(
                web::resource("/api/v1/auth/logout")
                    .route(web::get().to(auth_get_logout))
            )
            .service(
                web::resource("/api/v1/auth/whoami")
                    .route(web::get().to(auth_get_whoami))
            )
            // post
            .service(
                web::resource("/api/v1/auth/create")
                    .route(web::post().to(auth_post_create)),
            )
            .service(
                web::resource("/api/v1/auth/login")
                    .route(web::post().to(auth_post_login)),
            )
            .service(
                web::resource("/api/v1/auth/login/admin")
                    .route(web::post().to(auth_post_login_admin)),
            )
            .service(
                web::resource("/api/v1/auth/delete")
                    .route(web::post().to(auth_post_delete)),
            )
            .service(
                web::resource("/api/v1/auth/admin")
                    .route(web::post().to(auth_get_admin)),
            )
            .service(
                web::resource("/api/v1/board/lifetime/top")
                    .route(web::get().to(board_get_lifetime_top)),
            )
            .service(
                web::resource("/api/v1/board/lifetime/all")
                    .route(web::get().to(board_get_lifetime_all)),
            )
            .service(
                web::resource("/api/v1/events/all")
                    .route(web::get().to(events_get_all)),
            )
            .service(
                web::resource("/api/v1/events/future")
                    .route(web::get().to(events_get_future)),
            )
            .service(
                web::resource("/api/v1/tickets_all")
                    .route(web::get().to(tickets_get_all)),
            )
            .service(
                web::resource("/api/v1/tickets_create/{user_id}/{event_id}")
                    .route(web::get().to(tickets_create_ticket)),
            )
            .service(
                web::resource("/api/v1/ticketing/pkpass/{ticket_id}")
                    .route(web::get().to(tickets_generate_pass)),
            )
    })
    .bind_openssl(format!("{}:443", env::var("HOSTNAME").unwrap_or_else(|_| "localhost".to_string())), builder)?
    .bind((env::var("HOSTNAME").unwrap_or_else(|_| "localhost".to_string()), 80))?
    .workers(8)
    .run()
    .await
}
