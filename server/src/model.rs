use std::collections::BTreeMap;

use chrono::DateTime;
use serde::{de, Deserialize, Deserializer, Serialize};
use serde_json::Value;

pub fn float_to_date_string<'de, D: Deserializer<'de>>(
    deserializer: D,
) -> Result<String, D::Error> {
    Ok(match Value::deserialize(deserializer)? {
        Value::Number(num) => {
            let num = num
                .as_f64()
                .ok_or_else(|| de::Error::custom("Invalid number"))?;
            format!(
                "{}",
                DateTime::from_timestamp(num as i64, 0)
                    .ok_or_else(|| de::Error::custom("Invalid number"))?
                    .format("%Y-%m-%d %H:%M")
            )
        }
        e => return Err(de::Error::custom(e)),
    })
}

#[derive(Deserialize, Serialize, Debug)]
struct S {
    #[serde(deserialize_with = "float_to_date_string")]
    time: String,
}

#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn int_float_to_date_string_works() {
        let as_string = r#"{"time":1699612567.763}"#;

        let my_s: S = serde_json::from_str(&as_string).unwrap();
        assert_eq!(
            my_s.time,
            format!(
                "{}",
                DateTime::from_timestamp(1699612567, 0)
                    .unwrap()
                    .format("%Y-%m-%d %H:%M")
            )
        );
    }
}

#[derive(Deserialize, Serialize)]
pub struct StateMachineResponse {
    #[serde(rename = "stateMachines")]
    pub state_machines: Vec<StateMachine>,
}

#[derive(Deserialize, Serialize)]
pub struct StateMachine {
    pub name: String,
    #[serde(rename = "stateMachineArn")]
    pub state_machine_arn: String,
    #[serde(rename = "type")]
    pub kind: String,
    #[serde(deserialize_with = "float_to_date_string")]
    #[serde(rename = "creationDate")]
    pub creation_date: String,
}

#[derive(Deserialize, Serialize)]
pub struct Executions {
    #[serde(rename = "executionArn")]
    pub execution_arn: String,
    #[serde(rename = "stateMachineArn")]
    pub state_machine_arn: String,
    pub name: String,
    pub status: String,
    #[serde(rename = "startDate")]
    pub start_date: String,
    #[serde(rename = "stopDate")]
    pub stop_date: Option<String>,
}

#[derive(Deserialize, Serialize)]
pub struct ExecutionsResponse {
    pub executions: Vec<Executions>,
}

#[derive(Debug, Deserialize, Serialize)]
pub struct Event {
    pub timestamp: String,
    #[serde(rename = "type")]
    pub kind: String,
    pub id: u64,
    #[serde(rename = "previousEventId")]
    pub previous_event_id: Option<u16>,
    #[serde(rename = "executionStartedEventDetails")]
    pub execution_started_event_details: Option<ExecutionStartedEventDetails>,
    #[serde(rename = "stateEnteredEventDetails")]
    pub state_entered_event_details: Option<StateEnteredEventDetails>,
    #[serde(rename = "stateExitedEventDetails")]
    pub state_exited_event_details: Option<StateExitedEventDetails>,
    #[serde(rename = "lambdaFunctionScheduledEventDetails")]
    pub lambda_function_scheduled_event_details: Option<LambdaFunctionScheduledEventDetails>,
    #[serde(rename = "lambdaFunctionFailedEventDetails")]
    pub lambda_function_failed_event_details: Option<LambdaFunctionFailedEventDetails>,
    #[serde(rename = "executionSucceededEventDetails")]
    pub execution_succeeded_event_details: Option<ExecutionSucceededEventDetails>,
}

#[derive(Debug, Deserialize, Serialize)]
pub struct ExecutionStartedEventDetails {
    pub input: String,
    #[serde(rename = "roleArn")]
    pub role_arn: String,
}

#[derive(Debug, Deserialize, Serialize)]
pub struct StateEnteredEventDetails {
    pub name: String,
    pub input: String,
}

#[derive(Debug, Deserialize, Serialize)]
pub struct StateExitedEventDetails {
    pub name: String,
    pub output: String,
}

#[derive(Debug, Deserialize, Serialize)]
pub struct LambdaFunctionScheduledEventDetails {
    pub resource: String,
    pub input: String,
}

#[derive(Debug, Deserialize, Serialize)]
pub struct LambdaFunctionFailedEventDetails {
    pub error: String,
    pub cause: String,
}

#[derive(Debug, Deserialize, Serialize)]
pub struct ExecutionSucceededEventDetails {
    pub output: String,
}

#[derive(Deserialize, Serialize)]
pub struct EventResponse {
    pub events: Vec<Event>,
}

#[derive(Serialize)]
pub struct ServerError {
    pub message: String,
}

#[derive(Debug, PartialEq, Serialize, Deserialize)]
pub enum Type {
    Task,
    Pass,
    Choice,
    Fail,
    Succeed,
    Wait,
    Map,
    Parallel,
}

#[derive(Debug, PartialEq, Serialize, Deserialize)]
pub struct Choice {
    #[serde(rename = "Variable")]
    variable: String,

    #[serde(rename = "IsPresent")]
    is_present: Option<bool>,

    #[serde(rename = "BooleanEquals")]
    bool_equals: Option<bool>,

    #[serde(rename = "Next")]
    pub next: Option<String>,
}

#[derive(Debug, PartialEq, Serialize, Deserialize)]
pub struct Catch {
    #[serde(rename = "ErrorEquals")]
    pub error_equals: Vec<String>,
    #[serde(rename = "Next")]
    pub next: String,
    #[serde(rename = "ResultPath")]
    pub result_path: String,
}

#[derive(Debug, PartialEq, Serialize, Deserialize)]
pub struct Step {
    #[serde(rename = "Type")]
    pub step_type: Type,

    #[serde(rename = "End")]
    pub end: Option<bool>,

    #[serde(rename = "Next")]
    pub next: Option<String>,

    #[serde(rename = "Resource")]
    pub resource: Option<Value>,

    #[serde(rename = "ResultPath")]
    pub result_path: Option<String>,

    #[serde(rename = "Choices")]
    pub choices: Option<Vec<Choice>>,

    #[serde(rename = "Catch")]
    pub catch: Option<Vec<Catch>>,

    #[serde(rename = "Default")]
    pub default: Option<String>,
}

#[derive(Debug, PartialEq, Serialize, Deserialize)]
pub struct StateMachineDefinition {
    #[serde(rename = "Comment")]
    pub comment: String,
    #[serde(rename = "StartAt")]
    pub start_at: String,
    #[serde(rename = "States")]
    pub states: BTreeMap<String, Step>,
}

#[derive(Debug, PartialEq, Serialize, Deserialize)]
pub struct StateMachineDescriptor {
    #[serde(rename = "stateMachineArn")]
    pub state_machine_arn: String,
    pub name: String,
    pub definition: String,
}
