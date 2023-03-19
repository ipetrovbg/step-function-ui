module Api exposing (..)

import Json.Decode as Jdec
import Json.Decode.Pipeline as Jpipe
import Json.Encode
import RemoteData.Http as RemoteHttp exposing (Config, acceptJson, defaultConfig)
import Types exposing (Base, Event(..), EventsResponse, Execution, LambdaFunctionFailed, LambdaFunctionFailedDetails, LambdaFunctionScheduled, LambdaScheduledDetails, Msg(..), StartedEvent, StartedEventDetails, StateEntered, StateEnteredDetails, StateExited, StateExitedDetails, StateMachine, StateMachineExecutionsResponse, StateMachineResponse, SucceededEvent, SucceededEventDetails)


baseUrl =
    "http://localhost:6969"


jsonConfig : Config
jsonConfig =
    { defaultConfig | headers = [ acceptJson ] }



-- ENDPOINTS


getStateMachines : String -> Cmd Msg
getStateMachines region =
    RemoteHttp.getWithConfig jsonConfig
        (baseUrl ++ "/" ++ region ++ "/state-machines")
        HandleFetchingStateMachines
        stateMachinesResponseDecoder


getStateMachine : String -> String -> Cmd Msg
getStateMachine region arn =
    RemoteHttp.getWithConfig jsonConfig
        (baseUrl ++ "/" ++ region ++ "/" ++ arn ++ "/state-machine")
        HandleFetchingStateMachine
        stateMachineDecoder


getStateMachineExecutions : String -> String -> Cmd Msg
getStateMachineExecutions region arn =
    RemoteHttp.getWithConfig jsonConfig
        (baseUrl ++ "/" ++ region ++ "/" ++ arn ++ "/executions")
        HandleFetchingStateMachineExecutions
        stateMachineExecutionsResponseDecoder


getEvents : String -> String -> Cmd Msg
getEvents region arn =
    RemoteHttp.getWithConfig jsonConfig
        (baseUrl ++ "/" ++ region ++ "/" ++ arn ++ "/history")
        HandleFetchingEvents
        eventsResponse


deleteStateMachine : String -> String -> Cmd Msg
deleteStateMachine region arn =
    RemoteHttp.deleteWithConfig jsonConfig
        (baseUrl ++ "/" ++ region ++ "/" ++ arn ++ "/state-machine")
        HandleDeleteStateMachine
        (Json.Encode.string "")



-- DECODERS


eventsResponse : Jdec.Decoder EventsResponse
eventsResponse =
    Jdec.map EventsResponse
        (Jdec.field "events" <| Jdec.list eventDecoder)


eventDecoder : Jdec.Decoder Event
eventDecoder =
    Jdec.oneOf
        [ Jdec.map Start <| startEventDecoder
        , Jdec.map Entered <| stateEnteredDecoder
        , Jdec.map Exited <| stateExitedDecoder
        , Jdec.map LambdaScheduled <| lambdaScheduledDecoder
        , Jdec.map BaseEvent <| baseEventDecoder
        , Jdec.map LambdaFailed <| lambdaFailedDecoder
        , Jdec.map Succeeded <| succeededDecoder
        ]


succeededDecoder : Jdec.Decoder SucceededEvent
succeededDecoder =
    let
        fieldSet0 =
            Jdec.map8 SucceededEvent
                (Jdec.field "executionStartedEventDetails" <| Jdec.null ())
                (Jdec.field "executionSucceededEventDetails" succeededDetailsDecoder)
                (Jdec.field "id" Jdec.int)
                (Jdec.field "lambdaFunctionFailedEventDetails" <| Jdec.null ())
                (Jdec.field "lambdaFunctionScheduledEventDetails" <| Jdec.null ())
                (Jdec.field "previousEventId" Jdec.int)
                (Jdec.field "stateEnteredEventDetails" <| Jdec.null ())
                (Jdec.field "stateExitedEventDetails" <| Jdec.null ())
    in
    Jdec.map3 (<|)
        fieldSet0
        (Jdec.field "timestamp" Jdec.string)
        (Jdec.field "type" Jdec.string)


succeededDetailsDecoder : Jdec.Decoder SucceededEventDetails
succeededDetailsDecoder =
    Jdec.map SucceededEventDetails
        (Jdec.field "output" Jdec.string)


lambdaFailedDecoder : Jdec.Decoder LambdaFunctionFailed
lambdaFailedDecoder =
    let
        fieldSet0 =
            Jdec.map8 LambdaFunctionFailed
                (Jdec.field "executionStartedEventDetails" <| Jdec.null ())
                (Jdec.field "executionSucceededEventDetails" <| Jdec.null ())
                (Jdec.field "id" Jdec.int)
                (Jdec.field "lambdaFunctionFailedEventDetails" lambdaFailedDetailsDecoder)
                (Jdec.field "lambdaFunctionScheduledEventDetails" <| Jdec.null ())
                (Jdec.field "previousEventId" Jdec.int)
                (Jdec.field "stateEnteredEventDetails" <| Jdec.null ())
                (Jdec.field "stateExitedEventDetails" <| Jdec.null ())
    in
    Jdec.map3 (<|)
        fieldSet0
        (Jdec.field "timestamp" Jdec.string)
        (Jdec.field "type" Jdec.string)


lambdaFailedDetailsDecoder : Jdec.Decoder LambdaFunctionFailedDetails
lambdaFailedDetailsDecoder =
    Jdec.map2 LambdaFunctionFailedDetails
        (Jdec.field "cause" Jdec.string)
        (Jdec.field "error" Jdec.string)


baseEventDecoder : Jdec.Decoder Base
baseEventDecoder =
    let
        fieldSet0 =
            Jdec.map8 Base
                (Jdec.field "executionStartedEventDetails" <| Jdec.null ())
                (Jdec.field "executionSucceededEventDetails" <| Jdec.null ())
                (Jdec.field "id" Jdec.int)
                (Jdec.field "lambdaFunctionFailedEventDetails" <| Jdec.null ())
                (Jdec.field "lambdaFunctionScheduledEventDetails" <| Jdec.null ())
                (Jdec.field "previousEventId" Jdec.int)
                (Jdec.field "stateEnteredEventDetails" <| Jdec.null ())
                (Jdec.field "stateExitedEventDetails" <| Jdec.null ())
    in
    Jdec.map3 (<|)
        fieldSet0
        (Jdec.field "timestamp" Jdec.string)
        (Jdec.field "type" Jdec.string)


lambdaScheduledDecoder : Jdec.Decoder LambdaFunctionScheduled
lambdaScheduledDecoder =
    let
        fieldSet0 =
            Jdec.map8 LambdaFunctionScheduled
                (Jdec.field "executionStartedEventDetails" <| Jdec.null ())
                (Jdec.field "executionSucceededEventDetails" <| Jdec.null ())
                (Jdec.field "id" Jdec.int)
                (Jdec.field "lambdaFunctionFailedEventDetails" <| Jdec.null ())
                (Jdec.field "lambdaFunctionScheduledEventDetails" lambdaScheduledDetailsDecoder)
                (Jdec.field "previousEventId" Jdec.int)
                (Jdec.field "stateEnteredEventDetails" <| Jdec.null ())
                (Jdec.field "stateExitedEventDetails" <| Jdec.null ())
    in
    Jdec.map3 (<|)
        fieldSet0
        (Jdec.field "timestamp" Jdec.string)
        (Jdec.field "type" Jdec.string)


lambdaScheduledDetailsDecoder : Jdec.Decoder LambdaScheduledDetails
lambdaScheduledDetailsDecoder =
    Jdec.map2 LambdaScheduledDetails
        (Jdec.field "input" Jdec.string)
        (Jdec.field "resource" Jdec.string)


stateExitedDecoder : Jdec.Decoder StateExited
stateExitedDecoder =
    let
        fieldSet0 =
            Jdec.map8 StateExited
                (Jdec.field "executionStartedEventDetails" <| Jdec.null ())
                (Jdec.field "executionSucceededEventDetails" <| Jdec.null ())
                (Jdec.field "id" Jdec.int)
                (Jdec.field "lambdaFunctionFailedEventDetails" <| Jdec.null ())
                (Jdec.field "lambdaFunctionScheduledEventDetails" <| Jdec.null ())
                (Jdec.field "previousEventId" Jdec.int)
                (Jdec.field "stateEnteredEventDetails" <| Jdec.null ())
                (Jdec.field "stateExitedEventDetails" stateExitedDetailsDecoder)
    in
    Jdec.map3 (<|)
        fieldSet0
        (Jdec.field "timestamp" Jdec.string)
        (Jdec.field "type" Jdec.string)


stateExitedDetailsDecoder : Jdec.Decoder StateExitedDetails
stateExitedDetailsDecoder =
    Jdec.map2 StateExitedDetails
        (Jdec.field "name" Jdec.string)
        (Jdec.field "output" Jdec.string)


stateEnteredDecoder : Jdec.Decoder StateEntered
stateEnteredDecoder =
    let
        fieldSet0 =
            Jdec.map8 StateEntered
                (Jdec.field "executionStartedEventDetails" <| Jdec.null ())
                (Jdec.field "executionSucceededEventDetails" <| Jdec.null ())
                (Jdec.field "id" Jdec.int)
                (Jdec.field "lambdaFunctionFailedEventDetails" <| Jdec.null ())
                (Jdec.field "lambdaFunctionScheduledEventDetails" <| Jdec.null ())
                (Jdec.field "previousEventId" Jdec.int)
                (Jdec.field "stateEnteredEventDetails" stateEnteredDetailsDecoder)
                (Jdec.field "stateExitedEventDetails" <| Jdec.null ())
    in
    Jdec.map3 (<|)
        fieldSet0
        (Jdec.field "timestamp" Jdec.string)
        (Jdec.field "type" Jdec.string)


stateEnteredDetailsDecoder : Jdec.Decoder StateEnteredDetails
stateEnteredDetailsDecoder =
    Jdec.map2 StateEnteredDetails
        (Jdec.field "input" Jdec.string)
        (Jdec.field "name" Jdec.string)


startEventDecoder : Jdec.Decoder StartedEvent
startEventDecoder =
    let
        fieldSet0 =
            Jdec.map8 StartedEvent
                (Jdec.field "executionStartedEventDetails" startEventDetailsDecoder)
                (Jdec.field "executionSucceededEventDetails" <| Jdec.null ())
                (Jdec.field "id" Jdec.int)
                (Jdec.field "lambdaFunctionFailedEventDetails" <| Jdec.null ())
                (Jdec.field "lambdaFunctionScheduledEventDetails" <| Jdec.null ())
                (Jdec.field "previousEventId" Jdec.int)
                (Jdec.field "stateEnteredEventDetails" <| Jdec.null ())
                (Jdec.field "stateExitedEventDetails" <| Jdec.null ())
    in
    Jdec.map3 (<|)
        fieldSet0
        (Jdec.field "timestamp" Jdec.string)
        (Jdec.field "type" Jdec.string)


startEventDetailsDecoder : Jdec.Decoder StartedEventDetails
startEventDetailsDecoder =
    Jdec.map2 StartedEventDetails
        (Jdec.field "input" Jdec.string)
        (Jdec.field "roleArn" Jdec.string)


stateMachineExecutionsResponseDecoder : Jdec.Decoder StateMachineExecutionsResponse
stateMachineExecutionsResponseDecoder =
    Jdec.succeed StateMachineExecutionsResponse
        |> Jpipe.required "executions" stateMachineExecutionsDecoder


stateMachineExecutionsDecoder : Jdec.Decoder (List Execution)
stateMachineExecutionsDecoder =
    Jdec.list executionDecoder


executionDecoder : Jdec.Decoder Execution
executionDecoder =
    Jdec.succeed Execution
        |> Jpipe.required "executionArn" Jdec.string
        |> Jpipe.required "stateMachineArn" Jdec.string
        |> Jpipe.required "name" Jdec.string
        |> Jpipe.required "status" Jdec.string
        |> Jpipe.required "startDate" Jdec.string
        |> Jpipe.optional "stopDate" Jdec.string "N/A"


stateMachinesResponseDecoder : Jdec.Decoder StateMachineResponse
stateMachinesResponseDecoder =
    Jdec.succeed StateMachineResponse
        |> Jpipe.required "stateMachines" stateMachinesDecoder


stateMachinesDecoder : Jdec.Decoder (List StateMachine)
stateMachinesDecoder =
    Jdec.list stateMachineDecoder


stateMachineDecoder : Jdec.Decoder StateMachine
stateMachineDecoder =
    Jdec.succeed StateMachine
        |> Jpipe.required "name" Jdec.string
        |> Jpipe.required "stateMachineArn" Jdec.string
        |> Jpipe.required "type" Jdec.string
        |> Jpipe.required "creationDate" Jdec.string
