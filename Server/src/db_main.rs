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
    pub human_location: String,
    pub latitude: f64,
    pub longitude: f64,
    pub details: String,
    pub image: String
}

#[derive(Serialize)]
pub struct Ticket {
    pub id: i64,
    pub event_id: i64,
    pub holder_id: i64,
    pub single_entry: i8, // 0 or 1
    pub expended: i8, // 0 or 1
    pub creation_date: i64,
}

pub type Pool = r2d2::Pool<r2d2_sqlite::SqliteConnectionManager>;
pub type Connection = r2d2::PooledConnection<r2d2_sqlite::SqliteConnectionManager>;

pub enum EventQuery {
    GetAllEvents,
    GetFutureEvents
}

pub async fn execute_events(pool: &Pool, query: EventQuery, unix_time: u128) -> Result<Vec<Event>, Error> {
    let pool = pool.clone();

    let conn = web::block(move || pool.get()).await?.map_err(error::ErrorInternalServerError)?;

    web::block(move || {
        match query {
            EventQuery::GetAllEvents => get_all_events(conn),
            EventQuery::GetFutureEvents => get_future_events(conn, unix_time),
        }
    })
    .await?
    .map_err(error::ErrorInternalServerError)
}

fn get_all_events(conn: Connection) -> Result<Vec<Event>, rusqlite::Error> {
    let stmt = conn.prepare("SELECT * FROM events ORDER BY start_time DESC;")?;
    get_event_rows(stmt)
}

fn get_future_events(conn: Connection, unix_time: u128) -> Result<Vec<Event>, rusqlite::Error> {
    let stmt = conn.prepare(format!("SELECT * FROM events WHERE start_time > {} ORDER BY start_time DESC;", unix_time).as_str())?;
    get_event_rows(stmt)
}

fn get_event_rows(mut statement: Statement) -> Result<Vec<Event>, rusqlite::Error> {
    statement
        .query_map([], |row| {
            Ok(Event {
                id: row.get(0)?,
                start_time: row.get(1)?,
                end_time: row.get(2)?,
                title: row.get(3)?,
                human_location: row.get(4)?,
                latitude: row.get(5)?,
                longitude: row.get(6)?,
                details: row.get(7)?,
                image: row.get(8)?,
            })
        })
        .and_then(Iterator::collect)
}

pub enum TicketQuery {
    GetAllTickets,
    GetEventTickets,
    GetUserTickets,
    GetValidEventTickets,
    GetValidUserTickets,
}

pub async fn execute_tickets(pool: &Pool, query: TicketQuery, parameter: String) -> Result<Vec<Ticket>, Error> {
    let pool = pool.clone();

    let conn = web::block(move || pool.get()).await?.map_err(error::ErrorInternalServerError)?;

    web::block(move || {
        match query {
            TicketQuery::GetAllTickets => get_all_tickets(conn),
            TicketQuery::GetEventTickets => get_event_tickets(conn, parameter),
            TicketQuery::GetUserTickets => get_user_tickets(conn, parameter),
            TicketQuery::GetValidEventTickets => get_valid_event_tickets(conn, parameter),
            TicketQuery::GetValidUserTickets => get_valid_user_tickets(conn, parameter),
        }
    })
    .await?
    .map_err(error::ErrorInternalServerError)
}

fn get_all_tickets(conn: Connection) -> Result<Vec<Ticket>, rusqlite::Error> {
    let stmt = conn.prepare("SELECT * FROM events ORDER BY start_time DESC;")?;
    get_ticket_rows(stmt)
}

fn get_event_tickets(conn: Connection, event_id: String) -> Result<Vec<Ticket>, rusqlite::Error> {
    let stmt = conn.prepare(format!("SELECT * FROM tickets WHERE event_id={} ORDER BY creation_date ASC;", event_id.parse::<i64>().unwrap_or(0)).as_str())?;
    get_ticket_rows(stmt)
}

fn get_user_tickets(conn: Connection, holder_id: String) -> Result<Vec<Ticket>, rusqlite::Error> {
    let stmt = conn.prepare(format!("SELECT * FROM tickets WHERE holder_id={} ORDER BY creation_date ASC;", holder_id.parse::<i64>().unwrap_or(0)).as_str())?;
    get_ticket_rows(stmt)
}

fn get_valid_event_tickets(conn: Connection, event_id: String) -> Result<Vec<Ticket>, rusqlite::Error> {
    let stmt = conn.prepare(format!("SELECT * FROM tickets WHERE event_id={} AND expended=0 ORDER BY creation_date ASC;", event_id.parse::<i64>().unwrap_or(0)).as_str())?;
    get_ticket_rows(stmt)
}

fn get_valid_user_tickets(conn: Connection, holder_id: String) -> Result<Vec<Ticket>, rusqlite::Error> {
    let stmt = conn.prepare(format!("SELECT * FROM tickets WHERE holder_id={} AND expended=0 ORDER BY creation_date ASC;", holder_id.parse::<i64>().unwrap_or(0)).as_str())?;
    get_ticket_rows(stmt)
}

fn get_ticket_rows(mut statement: Statement) -> Result<Vec<Ticket>, rusqlite::Error> {
    statement
        .query_map([], |row| {
            Ok(Ticket {
                id: row.get(0)?,
                event_id: row.get(1)?,
                holder_id: row.get(2)?,
                single_entry: row.get(3)?,
                expended: row.get(4)?,
                creation_date: row.get(5)?,
            })
        })
        .and_then(Iterator::collect)
}
