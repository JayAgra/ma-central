use chrono::prelude::{DateTime, Utc};
use serde_json::{json, Value};
use std::time::{SystemTime, UNIX_EPOCH, Duration};

use crate::{db_main, db_auth};

fn millis_to_system_time(millis: i64) -> SystemTime {
    UNIX_EPOCH + Duration::new(millis as u64 / 1000, ((millis % 1000) * 1_000_000) as u32)
}

fn iso8601(st: &std::time::SystemTime) -> String {
    let dt: DateTime<Utc> = st.clone().into();
    format!("{}", dt.format("%+"))
}

pub fn generate_pass_json(ticket: db_main::Ticket, event: db_main::Event, user: db_auth::User) -> Value {
    json!(
        {
            "formatVersion": 1,
            "passTypeIdentifier": "pass.com.jayagra.ma-central",
            "serialNumber": format!("{}", ticket.id),
            "teamIdentifier": "D6MFYYVHA8",
            "relevantDate": iso8601(&millis_to_system_time(event.start_time)),
            "locations": [
                {
                    "longitude": event.longitude,
                    "latitude": event.latitude
                }
            ],
            "barcode": {
                "message": format!("{}", ticket.id),
                "format": "PKBarcodeFormatPDF417",
                "messageEncoding": "iso-8859-1"
            },
            "organizationName": "Jayen Agrawal",
            "description": "Menlo-Atherton High School Event Ticket",
            "foregroundColor": "rgb(255, 255, 255)",
            "backgroundColor": "rgb(255, 255, 255)",
            "eventTicket": {
                "primaryFields": [
                    {
                        "key": "event",
                        "label": "EVENT",
                        "value": format!("{}", event.title)
                    }
                ],
                "secondaryFields" : [
                    {
                        "dateStyle": "PKDateStyleMedium",
                        "isRelative": true,
                        "key": "date",
                        "label": "DATE",
                        "timeStyle": "PKDateStyleShort",
                        "value": iso8601(&millis_to_system_time(event.start_time))
                    },
                    {
                        "key": "loc",
                        "label": "LOCATION",
                        "value": format!("{}", event.human_location)
                    }
                ],
                "auxiliaryFields": [
                    {
                        "key": "holder",
                        "label": "HOLDER",
                        "value": format!("{} - {}", user.student_id, user.username)
                    }
                ],
                "backFields" : [
                    {
                        "key": "description",
                        "label": "Event Description",
                        "value": format!("{}", event.details)
                    },
                    {
                        "key": "terms",
                        "label": "Terms and Conditions",
                        "value": "THIS TICKET IS A REVOCABLE LICENSE/USER ACCEPTS ALL RISK OF INJURY\n\nThe holder voluntarily assumes all risks incident to the event, including the risk of lost, stolen or damaged property, personal injury or illness. Menlo-Atherton High School (MAHS) may revoke this license and eject or refuse entry to the holder for reasons including, but not limited to, violation of venue rules, illegal activity, misconduct, safety concerns or failure to comply with security measures. There are no refunds or exchanges. MAHS reserves the right, without refund of any portion of the purchase price, to revoke the license granted by this ticket and refuse admission or eject any person whose conduct is deemed by MAHS or its agents to be disorderly or indecent, or whose language is vulgar or abusive. Use of this ticket constitutes acceptance of these terms."
                    },
                    {
                        "key": "creation_date",
                        "label": "Creation Timestamp",
                        "value": format!("{}", ticket.creation_date)
                    }
                ]
            }
        }
    )
}