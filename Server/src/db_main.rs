use actix_web::{error, web, Error};
use rusqlite::{params, Statement};
use serde::{Deserialize, Serialize};
use serde_json;
use std::str;

#[derive(Serialize)]
pub struct Event {
    pub id: i64,
    pub start_time: i64,
    pub end_time: i64,
    pub title: String,
    pub location: String,
    pub details: String,
    pub image: String
}

pub type Pool = r2d2::Pool<r2d2_sqlite::SqliteConnectionManager>;
pub type Connection = r2d2::PooledConnection<r2d2_sqlite::SqliteConnectionManager>;

