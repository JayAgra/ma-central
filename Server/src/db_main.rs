use actix_web::{error, web, Error};
use rusqlite::{params, Statement};
use serde::Serialize;

#[derive(Serialize, Clone)]
pub struct Event {
    pub id: i64,
    pub start_time: i64,
    pub end_time: i64,
    pub title: String,
    pub human_location: String,
    pub latitude: f64,
    pub longitude: f64,
    pub details: String,
    pub image: String, // 640x320 or 1280x640
    pub ticket_price: i64,
    pub last_sale_date: i64,
}

#[derive(Serialize, Clone)]
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
    GetFutureEvents,
    GetEventById
}

pub async fn execute_events(pool: &Pool, query: EventQuery, unix_time: u128) -> Result<Vec<Event>, Error> {
    let pool = pool.clone();

    let conn = web::block(move || pool.get()).await?.map_err(error::ErrorInternalServerError)?;

    web::block(move || {
        match query {
            EventQuery::GetAllEvents => get_all_events(conn),
            EventQuery::GetFutureEvents => get_future_events(conn, unix_time),
            EventQuery::GetEventById => get_event_by_id(conn, unix_time as i64)
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

fn get_event_by_id(conn: Connection, event_id: i64) -> Result<Vec<Event>, rusqlite::Error> {
    let stmt = conn.prepare(format!("SELECT * FROM events WHERE id = {};", event_id).as_str())?;
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
                ticket_price: row.get(9)?,
                last_sale_date: row.get(10)?,
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
    GetTicketById,
    GetUserEventTickets
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
            TicketQuery::GetTicketById => get_ticket_id(conn, parameter),
            TicketQuery::GetUserEventTickets => get_user_event_tickets(conn, parameter),
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
    let stmt = conn.prepare(format!("SELECT * FROM tickets WHERE event_id={} ORDER BY creation_date DESC;", event_id.parse::<i64>().unwrap_or(0)).as_str())?;
    get_ticket_rows(stmt)
}

fn get_user_tickets(conn: Connection, holder_id: String) -> Result<Vec<Ticket>, rusqlite::Error> {
    let stmt = conn.prepare(format!("SELECT * FROM tickets WHERE holder_id={} ORDER BY creation_date DESC;", holder_id.parse::<i64>().unwrap_or(0)).as_str())?;
    get_ticket_rows(stmt)
}

fn get_valid_event_tickets(conn: Connection, event_id: String) -> Result<Vec<Ticket>, rusqlite::Error> {
    let stmt = conn.prepare(format!("SELECT * FROM tickets WHERE event_id={} AND expended=0 ORDER BY creation_date DESC;", event_id.parse::<i64>().unwrap_or(0)).as_str())?;
    get_ticket_rows(stmt)
}

fn get_valid_user_tickets(conn: Connection, holder_id: String) -> Result<Vec<Ticket>, rusqlite::Error> {
    let stmt = conn.prepare(format!("SELECT * FROM tickets WHERE holder_id={} AND expended=0 ORDER BY creation_date DESC;", holder_id.parse::<i64>().unwrap_or(0)).as_str())?;
    get_ticket_rows(stmt)
}

fn get_ticket_id(conn: Connection, ticket_id: String) -> Result<Vec<Ticket>, rusqlite::Error> {
    let stmt = conn.prepare(format!("SELECT * FROM tickets WHERE id={} AND expended=0;", ticket_id).as_str())?;
    get_ticket_rows(stmt)
}

fn get_user_event_tickets(conn: Connection, user_event: String) -> Result<Vec<Ticket>, rusqlite::Error> {
    let user_event_data: Vec<&str> = user_event.split("_").collect();
    let stmt = conn.prepare(format!("SELECT * FROM tickets WHERE holder_id={} AND event_id={};", user_event_data[0], user_event_data[1]).as_str())?;
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

pub async fn create_ticket(pool: &Pool, event_id: i64, user_id: i64, creation_date: u128) -> Result<Ticket, Error> {
    let pool = pool.clone();

    let conn = web::block(move || pool.get()).await?.map_err(error::ErrorInternalServerError)?;

    web::block(move || {
        get_ticket_sql(conn, event_id, user_id, creation_date)
    })
    .await?
    .map_err(error::ErrorInternalServerError)
}

fn get_ticket_sql(conn: Connection, event_id: i64, user_id: i64, creation_date: u128) -> Result<Ticket, rusqlite::Error> {
    let ticket_id: i64 = format!("{}{}{}", event_id.to_string(), format!("{:0>9}", user_id.to_string()), format!("{:0>5}", (creation_date % 1000).to_string())).parse::<i64>().unwrap();
    let mut stmt = conn.prepare("INSERT INTO tickets (id, event_id, holder_id, single_entry, expended, creation_date) VALUES (?, ?, ?, ?, ?, ?)")?;
    stmt.execute(params![
        ticket_id,
        event_id,
        user_id,
        1,
        0,
        creation_date as i64
    ])?;
    Ok(Ticket { id: ticket_id, event_id, holder_id: user_id, single_entry: 1, expended: 0, creation_date: creation_date as i64 })
}
