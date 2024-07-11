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
use openssl::ssl::{SslAcceptor, SslFiletype, SslMethod};
use r2d2_sqlite::{self, SqliteConnectionManager};
use serde::{Deserialize, Serialize};
use std::{collections::HashMap, env, io, pin::Pin, sync::RwLock, time::{SystemTime, UNIX_EPOCH}};

mod auth;
mod db_main;
mod db_auth;
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
    auth::login(&db.auth, session, identity, data).await
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

async fn tickets_get_query(req: HttpRequest, db: web::Data<Databases>, user: db_auth::User) -> Result<HttpResponse, AWError> {
    match req.match_info().get("query_type").unwrap() {
        "event" => {
            if user.data == "admin" {
                Ok(HttpResponse::Ok()
                    .insert_header(("Cache-Control", "no-cache"))
                    .json(
                        db_main::execute_tickets(
                            &db.main,
                            db_main::TicketQuery::GetEventTickets,
                            req.match_info().get("query_data").unwrap().to_string()
                        ).await?
                    )
                )
            } else {
                Err(error::ErrorUnauthorized("{\"status\": \"unauthorized\"}"))
            }
        }
        "user" => {
            if user.data == "admin" {
                Ok(HttpResponse::Ok()
                    .insert_header(("Cache-Control", "no-cache"))
                    .json(
                        db_main::execute_tickets(
                            &db.main,
                            db_main::TicketQuery::GetUserTickets,
                            req.match_info().get("query_data").unwrap().to_string()
                        ).await?
                    )
                )
            } else {
                Ok(HttpResponse::Ok()
                    .insert_header(("Cache-Control", "no-cache"))
                    .json(
                        db_main::execute_tickets(
                            &db.main,
                            db_main::TicketQuery::GetUserTickets,
                            user.id.to_string()
                        ).await?
                    )
                )
            }
        }
        "event_valid" => {
            if user.data == "admin" {
                Ok(HttpResponse::Ok()
                    .insert_header(("Cache-Control", "no-cache"))
                    .json(
                        db_main::execute_tickets(
                            &db.main,
                            db_main::TicketQuery::GetValidEventTickets,
                            req.match_info().get("query_data").unwrap().to_string()
                        ).await?
                    )
                )
            } else {
                Err(error::ErrorUnauthorized("{\"status\": \"unauthorized\"}"))
            }
        }
        "user_valid" => {
            if user.data == "admin" {
                Ok(HttpResponse::Ok()
                    .insert_header(("Cache-Control", "no-cache"))
                    .json(
                        db_main::execute_tickets(
                            &db.main,
                            db_main::TicketQuery::GetValidUserTickets,
                            req.match_info().get("query_data").unwrap().to_string(),
                        ).await?
                    )
                )
            } else {
                Ok(HttpResponse::Ok()
                    .insert_header(("Cache-Control", "no-cache"))
                    .json(
                        db_main::execute_tickets(
                            &db.main,
                            db_main::TicketQuery::GetValidUserTickets,
                            user.id.to_string(),
                        ).await?
                    )
                )
            }
        }
        _ => {
            Err(error::ErrorBadRequest("{\"status\": \"bad_query_type\"}"))
        }
    }
}

async fn tickets_create_ticket(req: HttpRequest, db: web::Data<Databases>, user: db_auth::User) -> Result<HttpResponse, AWError> {
    let event_id_raw = req.match_info().get("event_id");
    match event_id_raw {
        Some(event_id_string) => {
            let event_id_conversion = event_id_string.parse::<i64>();
            if event_id_conversion.is_ok() {
                let event = db_main::execute_events(&db.main, db_main::EventQuery::GetEventById, event_id_conversion.unwrap_or(0) as u128).await?;
                if !event.is_empty() {
                    let start = SystemTime::now();
                    let since_the_epoch = start
                        .duration_since(UNIX_EPOCH)
                        .expect("time just went fucking backwards");
                    if event[0].last_sale_date > since_the_epoch.as_millis() as i64 {
                        let user_results = db_auth::execute_scores(&db.auth, db_auth::AuthData::GetCurrentUserScore, user.id).await?;
                        if user_results[0].score >= event[0].ticket_price {
                            let point_deduction = db_auth::update_points(&db.auth, user.id, event[0].ticket_price * -1).await?;
                            if point_deduction {
                                Ok(HttpResponse::Ok()
                                    .insert_header(("Cache-Control", "no-cache"))
                                    .json(db_main::create_ticket(&db.main, event[0].id, user.id, since_the_epoch.as_millis()).await?))
                            } else {
                                println!("false on deduction??");
                                Err(error::ErrorInternalServerError("{\"status\": \"point_transaction_failed\"}"))
                            }
                        } else {
                            println!("balance too low");
                            Err(error::ErrorForbidden("{\"status\": \"balance_too_low\"}"))
                        }
                    } else {
                        println!("ticket sale date expired");
                        Err(error::ErrorLocked("{\"status\": \"ticket_sale_ended\"}"))
                    }
                } else {
                    println!("got empty event results");
                    Err(error::ErrorBadRequest("{\"status\": \"bad_event_id\"}"))
                }
            } else {
                println!("got error on int parsing");
                Err(error::ErrorBadRequest("{\"status\": \"bad_event_id\"}"))
            }
        }
        None => {
            println!("got none on event id param");
            Err(error::ErrorBadRequest("{\"status\": \"bad_event_id\"}"))
        }
    }
}

const APPLE_APP_SITE_ASSOC: &str = "{\"webcredentials\":{\"apps\":[\"D6MFYYVHA8.com.jayagra.ma-central\"]}}";
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
                web::resource("/api/v1/auth/delete")
                    .route(web::post().to(auth_post_delete)),
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
                web::resource("/api/v1/tickets/{query_type}/{query_data}")
                    .route(web::get().to(tickets_get_query)),
            )
            .service(
                web::resource("/api/v1/tickets/create/{event_id}")
                    .route(web::get().to(tickets_create_ticket)),
            )
    })
    .bind_openssl(format!("{}:443", env::var("HOSTNAME").unwrap_or_else(|_| "localhost".to_string())), builder)?
    .bind((env::var("HOSTNAME").unwrap_or_else(|_| "localhost".to_string()), 80))?
    .workers(8)
    .run()
    .await
}
