module Types exposing
    ( Active(..)
    , Base
    , BaseNotification
    , Event(..)
    , EventsResponse
    , Execution
    , Flags
    , LambdaFunctionFailed
    , LambdaFunctionFailedDetails
    , LambdaFunctionScheduled
    , LambdaScheduledDetails
    , Model
    , Msg(..)
    , Notification(..)
    , NotificationVisibility(..)
    , Region(..)
    , StartedEvent
    , StartedEventDetails
    , StateEntered
    , StateEnteredDetails
    , StateExited
    , StateExitedDetails
    , StateMachine
    , StateMachineExecutionsResponse
    , StateMachineResponse
    , SucceededEvent
    , SucceededEventDetails
    )

import Browser exposing (UrlRequest)
import RemoteData exposing (WebData)
import UUID exposing (UUID)
import Url exposing (Url)


type alias Flags =
    ()


type alias Execution =
    { executionArn : String
    , stateMachineArn : String
    , name : String

    -- TODO: use type
    , status : String

    -- TODO: use some date types
    , startDate : String
    , stopDate : String
    }


type alias EventsResponse =
    { events : List Event
    }


type alias StartedEventDetails =
    { input : String
    , roleArn : String
    }


type alias StartedEvent =
    { executionStartedEventDetails : StartedEventDetails
    , executionSucceededEventDetails : ()
    , id : Int
    , lambdaFunctionFailedEventDetails : ()
    , lambdaFunctionScheduledEventDetails : ()
    , previousEventId : Maybe Int
    , stateEnteredEventDetails : ()
    , stateExitedEventDetails : ()
    , timestamp : String
    , type_ : String
    }


type alias StateEntered =
    { executionStartedEventDetails : ()
    , executionSucceededEventDetails : ()
    , id : Int
    , lambdaFunctionFailedEventDetails : ()
    , lambdaFunctionScheduledEventDetails : ()
    , previousEventId : Maybe Int
    , stateEnteredEventDetails : StateEnteredDetails
    , stateExitedEventDetails : ()
    , timestamp : String
    , type_ : String
    }


type alias StateEnteredDetails =
    { input : String
    , name : String
    }


type alias StateExited =
    { executionStartedEventDetails : ()
    , executionSucceededEventDetails : ()
    , id : Int
    , lambdaFunctionFailedEventDetails : ()
    , lambdaFunctionScheduledEventDetails : ()
    , previousEventId : Maybe Int
    , stateEnteredEventDetails : ()
    , stateExitedEventDetails : StateExitedDetails
    , timestamp : String
    , type_ : String
    }


type alias StateExitedDetails =
    { name : String
    , output : String
    }


type alias LambdaFunctionScheduled =
    { executionStartedEventDetails : ()
    , executionSucceededEventDetails : ()
    , id : Int
    , lambdaFunctionFailedEventDetails : ()
    , lambdaFunctionScheduledEventDetails : LambdaScheduledDetails
    , previousEventId : Maybe Int
    , stateEnteredEventDetails : ()
    , stateExitedEventDetails : ()
    , timestamp : String
    , type_ : String
    }


type alias LambdaScheduledDetails =
    { input : String
    , resource : String
    }


type alias Base =
    { executionStartedEventDetails : ()
    , executionSucceededEventDetails : ()
    , id : Int
    , lambdaFunctionFailedEventDetails : ()
    , lambdaFunctionScheduledEventDetails : ()
    , previousEventId : Maybe Int
    , stateEnteredEventDetails : ()
    , stateExitedEventDetails : ()
    , timestamp : String
    , type_ : String
    }


type alias LambdaFunctionFailed =
    { executionStartedEventDetails : ()
    , executionSucceededEventDetails : ()
    , id : Int
    , lambdaFunctionFailedEventDetails : LambdaFunctionFailedDetails
    , lambdaFunctionScheduledEventDetails : ()
    , previousEventId : Maybe Int
    , stateEnteredEventDetails : ()
    , stateExitedEventDetails : ()
    , timestamp : String
    , type_ : String
    }


type alias LambdaFunctionFailedDetails =
    { cause : String
    , error : String
    }


type alias SucceededEventDetails =
    { output : String
    }


type alias SucceededEvent =
    { executionStartedEventDetails : ()
    , executionSucceededEventDetails : SucceededEventDetails
    , id : Int
    , lambdaFunctionFailedEventDetails : ()
    , lambdaFunctionScheduledEventDetails : ()
    , previousEventId : Maybe Int
    , stateEnteredEventDetails : ()
    , stateExitedEventDetails : ()
    , timestamp : String
    , type_ : String
    }


type Event
    = Start StartedEvent
    | Entered StateEntered
    | Exited StateExited
    | LambdaScheduled LambdaFunctionScheduled
    | BaseEvent Base
    | LambdaFailed LambdaFunctionFailed
    | Succeeded SucceededEvent


type alias StateMachine =
    { name : String
    , stateMachineArn : String
    , kind : String
    , creationDate : String
    }


type alias StateMachineResponse =
    { stateMachines : List StateMachine }


type alias StateMachineExecutionsResponse =
    { executions : List Execution }


type Active
    = StateMachineView
    | ExecutionsView StateMachine
    | ExecutionHistoryView Execution


type alias BaseNotification =
    { message : String
    , uuid : UUID
    }


type Notification
    = ErrorNotification BaseNotification
    | InfoNotification BaseNotification
    | SuccessNotification BaseNotification


type Region
    = Region String


type NotificationVisibility
    = Visible (List Notification)
    | Hidden (List Notification)
    | Cleared


type alias Model =
    { stateMachines : WebData (List StateMachine)
    , active : Active
    , executions : WebData (List Execution)
    , events : WebData (List Event)
    , notifications : NotificationVisibility
    , randomInt : Int
    }


type Msg
    = ChangeUrl Url
    | ClickLink UrlRequest
    | HandleFetchingStateMachines (WebData StateMachineResponse)
    | HandleFetchingStateMachine (WebData StateMachine)
    | HandleFetchingStateMachineExecutions (WebData StateMachineExecutionsResponse)
    | HandleFetchingEvents (WebData EventsResponse)
    | FetchStateMachines
    | FetchStateMachine Region String
    | FetchStateMachinesExecutions
    | FetchEvents
    | NoOp
    | SelectStateMachine StateMachine
    | SelectExecution Execution
    | SelectView Active
    | HandleDeleteStateMachine (WebData String)
    | HandlePostMachine (WebData Int)
    | DeleteStateMachine Region String
    | StopRunningExecution Region String
    | ClearNotification UUID
    | PostSuccessNotification String
    | PostErrorNotification String
    | PostInfoNotification String
    | GotSeed Int
    | ShowNotifications
    | HideNotifications
