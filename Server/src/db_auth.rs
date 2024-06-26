use actix_web::{error, web, Error};
use argon2::{
    password_hash::{rand_core::OsRng, PasswordHasher, SaltString},
    Argon2,
};
use rusqlite::{params, Statement};
use serde::{Deserialize, Serialize};
use serde_json;
use std::str;

#[derive(Serialize)]
pub struct UserPoints {
    pub id: i64,
    pub username: String,
    pub lifetime: i64,
    pub score: i64,
}

#[derive(Serialize)]
pub struct Id {
    pub id: i64
}

pub type Pool = r2d2::Pool<r2d2_sqlite::SqliteConnectionManager>;
pub type Connection = r2d2::PooledConnection<r2d2_sqlite::SqliteConnectionManager>;
type PointQueryResult = Result<Vec<UserPoints>, rusqlite::Error>;

pub enum AuthData {
    GetUserScores,
}

pub async fn execute_scores(pool: &Pool, query: AuthData) -> Result<Vec<UserPoints>, Error> {
    let pool = pool.clone();

    let conn = web::block(move || pool.get()).await?.map_err(error::ErrorInternalServerError)?;

    web::block(move || {
        match query {
            AuthData::GetUserScores => get_user_scores(conn),
        }
    })
    .await?
    .map_err(error::ErrorInternalServerError)
}

fn get_user_scores(conn: Connection) -> PointQueryResult {
    let stmt = conn.prepare("SELECT id, username, lifetime, score FROM users ORDER BY lifetime DESC;")?;
    get_score_rows(stmt)
}

fn get_score_rows(mut statement: Statement) -> PointQueryResult {
    statement
        .query_map([], |row| {
            Ok(UserPoints {
                id: row.get(0)?,
                username: row.get(1)?,
                lifetime: row.get(2)?,
                score: row.get(3)?,
            })
        })
        .and_then(Iterator::collect)
}

#[derive(Serialize, Deserialize, Clone)]
pub struct User {
    pub id: i64,
    pub student_id: String,
    pub username: String,
    pub full_name: String,
    pub pass_hash: String,
    pub lifetime: i64,
    pub score: i64,
    pub data: String,
}

pub async fn get_user_id(pool: &Pool, id: String) -> Result<User, Error> {
    let pool = pool.clone();

    let conn = web::block(move || pool.get()).await?.map_err(error::ErrorInternalServerError)?;

    web::block(move || get_user_id_entry(conn, id))
        .await?
        .map_err(error::ErrorInternalServerError)
}

fn get_user_id_entry(conn: Connection, id: String) -> Result<User, rusqlite::Error> {
    let mut stmt = conn.prepare("SELECT * FROM users WHERE id=?1")?;
    stmt.query_row([id], |row| {
        Ok(User {
            id: row.get(0)?,
            student_id: row.get(1)?,
            username: row.get(2)?,
            full_name: row.get(3)?,
            pass_hash: row.get(4)?,
            lifetime: row.get(5)?,
            score: row.get(6)?,
            data: row.get(7)?,
        })
    })
}

pub async fn get_user_username(pool: &Pool, username: String) -> Result<User, Error> {
    let pool = pool.clone();

    let conn = web::block(move || pool.get()).await?.map_err(error::ErrorInternalServerError)?;

    web::block(move || get_user_username_entry(conn, username))
        .await?
        .map_err(error::ErrorInternalServerError)
}

fn get_user_username_entry(conn: Connection, id: String) -> Result<User, rusqlite::Error> {
    let mut stmt = conn.prepare("SELECT * FROM users WHERE username=?1")?;
    stmt.query_row([id], |row| {
        Ok(User {
            id: row.get(0)?,
            student_id: row.get(1)?,
            username: row.get(2)?,
            full_name: row.get(3)?,
            pass_hash: row.get(4)?,
            lifetime: row.get(5)?,
            score: row.get(6)?,
            data: row.get(7)?,
        })
    })
}

pub async fn create_user(pool: &Pool, student_id: String, full_name: String, username: String, password: String) -> Result<User, Error> {
    let pool = pool.clone();
    let conn = web::block(move || pool.get()).await?.map_err(error::ErrorInternalServerError)?;
    web::block(move || {
        let generated_salt = SaltString::generate(&mut OsRng);
        // argon2id v19
        let argon2ins = Argon2::default();
        // hash into phc string
        let hashed_password = argon2ins.hash_password(password.as_bytes(), &generated_salt);
        if hashed_password.is_err() {
            return Ok(User {
                id: 0,
                student_id,
                username,
                full_name,
                pass_hash: "".to_string(),
                lifetime: 0,
                score: 0,
                data: "".to_string(),
            })
            .map_err(rusqlite::Error::NulError);
        }
        create_user_entry(conn, student_id, username, full_name, hashed_password.unwrap().to_string())
    })
    .await?
    .map_err(error::ErrorInternalServerError)
}

fn create_user_entry(conn: Connection, student_id: String, username: String, full_name: String, password_hash: String) -> Result<User, rusqlite::Error> {
    let mut stmt = conn.prepare("INSERT INTO users (student_id, username, full_name, pass_hash, lifetime, score, data) VALUES (?, ?, ?, ?, 0, 0, '');")?;
    let mut new_user = User {
        id: 0,
        student_id,
        username,
        full_name,
        pass_hash: password_hash,
        lifetime: 0,
        score: 0,
        data: "".to_string(),
    };
    stmt.execute(params![new_user.student_id, new_user.username, new_user.full_name, new_user.pass_hash])?;
    new_user.id = conn.last_insert_rowid();
    Ok(new_user)
}

pub fn update_points(conn: Connection, user_id: i64, inc: i64) -> Result<bool, rusqlite::Error> {
    let mut stmt = conn.prepare("UPDATE users SET score = score + ?1 WHERE id = ?2;")?;
    stmt.execute(params![inc, user_id])?;
    if inc > 0 {
        let mut stmt_life = conn.prepare("UPDATE users SET lifetime = lifetime + ?1 WHERE id = ?2;")?;
        stmt_life.execute(params![inc, user_id])?;
    }
    Ok(true)
}

pub async fn execute_manage_user(pool: &Pool, params: [String; 1]) -> Result<String, Error> {
    let pool = pool.clone();

    let conn = web::block(move || pool.get()).await?.map_err(error::ErrorInternalServerError)?;

    web::block(move || {
        manage_delete_user(conn, params)
    })
    .await?
    .map_err(error::ErrorInternalServerError)
}

fn manage_delete_user(connection: Connection, params: [String; 1]) -> Result<String, rusqlite::Error> {
    let stmt = connection.prepare("DELETE FROM users WHERE id=?1;")?;
    execute_manage_action(stmt, params)
}

fn execute_manage_action(mut statement: Statement, params: [String; 1]) -> Result<String, rusqlite::Error> {
    if statement.execute(params).is_ok() {
        Ok("{\"status\":3206}".to_string())
    } else {
        Ok("{\"status\":8002}".to_string())
    }
}
