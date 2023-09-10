module Types exposing
    ( Active(..)
    , Base
    , BaseNotification
    , ChoiceBranch
    , ChoiceModel
    , Event(..)
    , EventsResponse
    , Execution
    , Flags
    , LambdaFunctionFailed
    , LambdaFunctionFailedDetails
    , LambdaFunctionScheduled
    , LambdaScheduledDetails
    , LinePoint
    , Model
    , Msg(..)
    , NodeKind(..)
    , Notification(..)
    , NotificationVisibility(..)
    , Point
    , Region(..)
    , StartedEvent
    , StartedEventDetails
    , StateEntered
    , StateEnteredDetails
    , StateExited
    , StateExitedDetails
    , StateMachine
    , StateMachineDescriptor
    , StateMachineExecutionsResponse
    , StateMachineResponse
    , StateMachineState(..)
    , SucceededEvent
    , SucceededEventDetails
    )

import Browser exposing (UrlRequest)
import Dict exposing (Dict)
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


type alias ChoiceBranch =
    { variable : String
    , isPresent : Maybe Bool
    , booleanEquals : Bool
    , next : String
    }


type alias ChoiceModel =
    { kind : String
    , end : Maybe Bool
    , next : Maybe String
    , choices : Maybe (List ChoiceBranch)
    }


type StateMachineState
    = Choice ChoiceModel


type alias StateMachineDescriptor =
    { comment : String
    , startAt : String
    , states : Dict String StateMachineState
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
    | ExecutionHistoryGraphView Execution


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


type NodeKind
    = Rect Point
    | Line LinePoint


type alias LinePoint =
    { x1 : Int
    , x2 : Int
    , y1 : Int
    , y2 : Int
    }


type alias Point =
    { x : Int
    , y : Int
    }


type alias Model =
    { stateMachines : WebData (List StateMachine)
    , active : Active
    , executions : WebData (List Execution)
    , events : WebData (List Event)
    , stateMachineDescriptorForExecution : WebData StateMachineDescriptor
    , notifications : NotificationVisibility
    , randomInt : Int
    , axis : Point
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
    | SelectGraphExecution Execution
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
    | HandleDescribeStateMachine (WebData StateMachineDescriptor)
    | GraphMoveUp
    | GraphMoveDown
