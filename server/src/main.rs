use crate::model::{
     EventResponse, ExecutionsResponse, ServerError, StateMachine, StateMachineResponse,
};
use actix_cors::Cors;
use actix_web::http::header::ContentType;
use actix_web::{delete, get, http, post, web, App, HttpRequest, HttpResponse, HttpServer};
use std::process::Command;
use std::str;

mod model;

#[get("/{region}/state-machines")]
async fn get_state_machines(region: web::Path<String>) -> HttpResponse {
    println!("[STATE MACHINES]: {}", region);

    return match Command::new("sh")
        .arg("-c")
        .arg(format!("aws stepfunctions list-state-machines --endpoint-url http://localhost:8083 --region {}", region.as_str()))
        .output() {
        Ok(o) => {
            println!("[STATE MACHINES]: {:?}", o);
            if o.status.success() {
                match str::from_utf8(&o.stdout) {
                    Ok(o) => {
                        match serde_json::from_str::<StateMachineResponse>(o) {
                            Ok(machines) => {
                                HttpResponse::Ok()
                                    .content_type(ContentType::json())
                                    .json(machines)
                            },
                            Err(e) => {
                                HttpResponse::InternalServerError()
                                    .content_type(ContentType::json())
                                    .json(ServerError {message: format!("ERROR: Failed to parse state machines. {:?}", e)})
                            }
                        }
                    },
                    Err(err) => {
                        HttpResponse::InternalServerError()
                            .content_type(ContentType::json())
                            .json(ServerError {message: format!("ERROR: Output convert failed due to: {err}")})
                    }
                }
            } else {
                HttpResponse::InternalServerError()
                    .content_type(ContentType::json())
                    .json(ServerError {message: format!("ERROR: Step Function exited with status code: {}", o.status.code().unwrap())})
            }
        },
        Err(e) => {
            HttpResponse::InternalServerError()
                .content_type(ContentType::json())
                .json(ServerError {message: format!("ERROR: Executing Step Function CLI command. {:?}", e)})
        }
    };
}

#[get("/{region}/{arn}/state-machine")]
async fn get_state_machine(req: HttpRequest) -> HttpResponse {
    let region: String = req.match_info().get("region").unwrap().parse().unwrap();
    let arn: String = req.match_info().get("arn").unwrap().parse().unwrap();
    println!("[STATE MACHINE]: {}, {}", region, arn);
    return match Command::new("sh")
        .arg("-c")
        .arg(format!("aws stepfunctions describe-state-machine --endpoint-url http://localhost:8083 --region {} --state-machine-arn {}", region.as_str(), arn.as_str()))
        .output() {
        Ok(o) => {
            println!("[STATE MACHINE]: {:?}", o);
            if o.status.success() {
                match str::from_utf8(&o.stdout) {
                    Ok(o) => {
                        match serde_json::from_str::<StateMachine>(o) {
                            Ok(machine) => {
                                HttpResponse::Ok()
                                    .content_type(ContentType::json())
                                    .json(machine)
                            },
                            Err(e) => {
                                HttpResponse::InternalServerError()
                                    .content_type(ContentType::json())
                                    .json(ServerError {message: format!("ERROR: Failed to parse state machine. {:?}", e)})
                            }
                        }
                    },
                    Err(err) => {
                        HttpResponse::InternalServerError()
                            .content_type(ContentType::json())
                            .json(ServerError {message: format!("ERROR: Output convert failed due to: {err}")})
                    }
                }
            } else {
                HttpResponse::InternalServerError()
                    .content_type(ContentType::json())
                    .json(ServerError {message: format!("ERROR: Step Function exited with status code: {}", o.status.code().unwrap())})
            }
        },
        Err(e) => {
            HttpResponse::InternalServerError()
                .content_type(ContentType::json())
                .json(ServerError {message: format!("ERROR: Executing Step Function CLI \"describe-state-machine\" command. {:?}", e)})
        }
    };
}

#[get("/{region}/{arn}/executions")]
async fn get_executions(req: HttpRequest) -> HttpResponse {
    let region: String = req.match_info().get("region").unwrap().parse().unwrap();
    let arn: String = req.match_info().get("arn").unwrap().parse().unwrap();
    println!("[EXECUTIONS]: {}, {}", region, arn);
    match Command::new("sh")
        .arg("-c")
        .arg(format!("aws stepfunctions list-executions --endpoint-url http://localhost:8083 --region {} --no-paginate --state-machine-arn {}", region, arn))
        .output() {
        Ok(o) => {
            println!("[EXECUTIONS]: {:?}", o);
            if o.status.success() {
                match str::from_utf8(&o.stdout) {
                    Ok(output) => {
                        match serde_json::from_str::<ExecutionsResponse>(output) {
                            Ok(executions) => {
                                HttpResponse::Ok()
                                    .content_type(ContentType::json())
                                    .json(executions)
                            },
                            Err(e) => {
                                HttpResponse::InternalServerError()
                                    .content_type(ContentType::json())
                                    .json(ServerError {message: format!("ERROR: Failed to parse executions. {:?}", e)})
                            }
                        }
                    }
                    Err(error) => HttpResponse::InternalServerError()
                        .content_type(ContentType::json())
                        .json(ServerError {message: format!("ERROR: Output convert failed due to: {error}")})
                }
            } else {
                HttpResponse::InternalServerError()
                    .content_type(ContentType::json())
                    .json(ServerError {message: format!("ERROR: Step Function exited with status code: {}", o.status.code().unwrap())})
            }
        }
        Err(error) => {
            HttpResponse::InternalServerError()
                .content_type(ContentType::json())
                .json(ServerError { message: format!("ERROR: Executing Step Function CLI \"list-executions\" failed due to {:?}", error) })
        }
    }
}

#[get("/{region}/{arn}/history")]
async fn execution(req: HttpRequest) -> HttpResponse {
    let region: String = req.match_info().get("region").unwrap().parse().unwrap();
    let arn: String = req.match_info().get("arn").unwrap().parse().unwrap();
    println!("[EXECUTION HISTORY]: {}, {}", region, arn);
    match Command::new("sh")
        .arg("-c")
        .arg(format!("aws stepfunctions get-execution-history --endpoint-url http://localhost:8083 --region {} --no-paginate --execution-arn {}", region, arn))
        .output() {
        Ok(o) => {
            println!("[EXECUTION HISTORY]: {:?}", o);
            if o.status.success() {
                match str::from_utf8(&o.stdout) {
                    Ok(output) => {
                        match serde_json::from_str::<EventResponse>(output) {
                            Ok(executions) => {
                                HttpResponse::Ok()
                                    .content_type(ContentType::json())
                                    .json(executions)
                            },
                            Err(e) => {
                                HttpResponse::InternalServerError()
                                    .content_type(ContentType::json())
                                    .json(ServerError {message: format!("ERROR: Failed to parse execution events. {:?}", e)})
                            }
                        }
                    }
                    Err(error) => HttpResponse::InternalServerError()
                        .content_type(ContentType::json())
                        .json(ServerError {message: format!("ERROR: Output convert failed due to: {error}")})
                }
            } else {
                HttpResponse::InternalServerError()
                    .content_type(ContentType::json())
                    .json(ServerError {message: format!("ERROR: Step Function exited with status code: {}", o.status.code().unwrap())})
            }

        }
        Err(error) => {
            HttpResponse::InternalServerError()
                .content_type(ContentType::json())
                .json(ServerError { message: format!("ERROR: Executing Step Function CLI \"get-execution-history\" failed due to {:?}", error) })
        }
    }
}

#[delete("/{region}/{arn}/state-machine")]
async fn delete_state_machine(req: HttpRequest) -> HttpResponse {
    let region: String = req.match_info().get("region").unwrap().parse().unwrap();
    let arn: String = req.match_info().get("arn").unwrap().parse().unwrap();
    println!("[DELETE STATE MACHINE]: {} {}", region, arn);
    return match Command::new("sh")
        .arg("-c")
        .arg(format!("aws stepfunctions delete-state-machine --endpoint-url http://localhost:8083 --region {} --state-machine-arn {}", region.as_str(), arn.as_str()))
        .output() {
        Ok(o) => {
            println!("[DELETE STATE MACHINE]: {:?}", o.status.success());
            HttpResponse::Ok()
                .content_type(ContentType::json())
                .json(0)
        }
        Err(e) => {
            HttpResponse::InternalServerError()
                .content_type(ContentType::json())
                .json(ServerError {message: format!("ERROR: Executing Step Function CLI \"delete-state-machine\" command. {:?}", e)})
        }
    };
}

#[post("/{region}/{arn}/stop-execution")]
async fn stop_execution(req: HttpRequest) -> HttpResponse {
    let region: String = req.match_info().get("region").unwrap().parse().unwrap();
    let arn: String = req.match_info().get("arn").unwrap().parse().unwrap();

    println!("[STOP EXECUTION]: {} {}", region, arn);

    return match Command::new("sh")
        .arg("-c")
        .arg(format!("aws stepfunctions stop-execution --endpoint-url http://localhost:8083 --region {} --execution-arn {} --cause \"Manual Step Functions Local stop\" --error ManualStop", region.as_str(), arn.as_str()))
        .output() {
        Ok(o) => {
            println!("[STOP EXECUTION]: {:?}", o);
            if o.status.success() {
                HttpResponse::Ok()
                    .content_type(ContentType::json())
                    .json(0)
            } else {
                HttpResponse::InternalServerError()
                    .content_type(ContentType::json())
                    .json(ServerError {message: format!("ERROR: Executing Step Function CLI \"stop-execution\" command. {:?}", o.status)})
            }
        }
        Err(e) => {
            HttpResponse::InternalServerError()
                .content_type(ContentType::json())
                .json(ServerError {message: format!("ERROR: Executing Step Function CLI \"stop-execution\" command. {:?}", e)})
        }
    };
}

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    HttpServer::new(|| {
        let cors = Cors::default()
            .allowed_origin("http://localhost:8080")
            .allowed_headers(vec![http::header::AUTHORIZATION, http::header::ACCEPT])
            .allowed_header(http::header::CONTENT_TYPE)
            .allow_any_method();

        App::new()
            .wrap(cors)
            .service(get_state_machines)
            .service(get_state_machine)
            .service(get_executions)
            .service(execution)
            .service(stop_execution)
            .service(delete_state_machine)
    })
    .bind(("127.0.0.1", 6969))?
    .run()
    .await
}
