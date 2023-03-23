module Main exposing (..)

import Api exposing (deleteStateMachine, getEvents, getStateMachine, getStateMachineExecutions, getStateMachines, stopRunningExecution)
import Browser exposing (Document)
import Browser.Navigation exposing (Key)
import Colors
import Constants exposing (each, london)
import Debug exposing (toString)
import Element exposing (Color, Element)
import Element.Background
import Element.Border
import Element.Font
import Element.Input
import Html.Attributes
import Random
import RemoteData exposing (RemoteData(..), WebData)
import Types exposing (Active(..), Base, BaseNotification, Event(..), Execution, Flags, LambdaFunctionFailedDetails, LambdaScheduledDetails, Model, Msg(..), Notification(..), NotificationVisibility(..), Region(..), StartedEventDetails, StateEnteredDetails, StateExitedDetails, StateMachine, SucceededEventDetails)
import UUID exposing (UUID)
import Url exposing (Url)
import Utils exposing (perform)


errorNotificationView : BaseNotification -> Element Msg
errorNotificationView error =
    Element.row
        [ Element.width Element.fill
        , Element.Background.color <| Colors.whiteColor <| Just 1
        , Element.Border.rounded 4
        ]
        [ Element.row
            [ Element.width Element.fill
            , Element.Background.color <| Colors.errorColor <| Just 0.1
            ]
            [ Element.el
                [ Element.Font.color <| Colors.darkBody <| Just 1.0
                , Element.padding 16
                ]
              <|
                Element.text error.message
            , Element.Input.button
                [ Element.padding 8, Element.alignRight ]
                { label =
                    Element.image [ Element.width <| Element.px 16 ]
                        { src = "src/static/close.svg"
                        , description = "Clear Notification button"
                        }
                , onPress = Just <| ClearNotification error.uuid
                }
            ]
        ]


infoNotificationView : BaseNotification -> Element Msg
infoNotificationView notification =
    Element.row
        [ Element.width Element.fill
        , Element.Background.color <| Colors.whiteColor <| Just 1
        , Element.Border.rounded 4
        ]
        [ Element.row
            [ Element.width Element.fill
            , Element.Background.color <| Colors.primaryColor <| Just 0.2
            ]
            [ Element.el
                [ Element.Font.color <| Colors.darkBody <| Just 1.0
                , Element.padding 16
                ]
              <|
                Element.text notification.message
            , Element.Input.button
                [ Element.padding 8
                , Element.alignRight
                ]
                { label =
                    Element.image [ Element.width <| Element.px 16 ]
                        { src = "src/static/close.svg"
                        , description = "Clear Notification button"
                        }
                , onPress = Just <| ClearNotification notification.uuid
                }
            ]
        ]


successNotificationView : BaseNotification -> Element Msg
successNotificationView notification =
    Element.row
        [ Element.width Element.fill
        , Element.Background.color <| Colors.whiteColor <| Just 1
        , Element.Border.rounded 4
        ]
        [ Element.row
            [ Element.width Element.fill
            , Element.Background.color <| Colors.successColor <| Just 0.1
            ]
            [ Element.el
                [ Element.Font.color <| Colors.darkBody <| Just 1.0
                , Element.padding 16
                ]
              <|
                Element.text notification.message
            , Element.Input.button
                [ Element.padding 8
                , Element.alignRight
                ]
                { label =
                    Element.image [ Element.width <| Element.px 16 ]
                        { src = "src/static/close.svg"
                        , description = "Clear Notification button"
                        }
                , onPress = Just <| ClearNotification notification.uuid
                }
            ]
        ]


renderNotificationBell : List Notification -> Element Msg
renderNotificationBell notifications =
    case List.length notifications of
        0 ->
            Element.Input.button []
                { label =
                    Element.image [ Element.width <| Element.px 20 ]
                        { src = "src/static/bell-off.svg"
                        , description = "Toggle notification button"
                        }
                , onPress = Just NoOp
                }

        _ ->
            Element.Input.button []
                { label =
                    Element.image [ Element.width <| Element.px 20 ]
                        { src = "src/static/bell-off.svg"
                        , description = "Toggle notification button"
                        }
                , onPress = Just NoOp
                }


notificationListView : NotificationVisibility -> Element Msg
notificationListView messages =
    let
        bellBtn =
            case messages of
                Visible n ->
                    let
                        icon =
                            case List.length n of
                                0 ->
                                    "bell-off.svg"

                                _ ->
                                    "bell-on.svg"
                    in
                    Element.Input.button []
                        { label =
                            Element.image [ Element.width <| Element.px 20 ]
                                { src = "src/static/" ++ icon
                                , description = "Toggle notification button"
                                }
                        , onPress = Just HideNotifications
                        }

                Hidden n ->
                    let
                        icon =
                            case List.length n of
                                0 ->
                                    "bell-off.svg"

                                _ ->
                                    "bell-on.svg"
                    in
                    Element.Input.button []
                        { label =
                            Element.image [ Element.width <| Element.px 20 ]
                                { src = "src/static/" ++ icon
                                , description = "Toggle notification button"
                                }
                        , onPress = Just ShowNotifications
                        }

                Cleared ->
                    Element.Input.button []
                        { label =
                            Element.image [ Element.width <| Element.px 20 ]
                                { src = "src/static/bell-off.svg"
                                , description = "Toggle notification button"
                                }
                        , onPress = Nothing
                        }
    in
    Element.column
        [ Element.height <| Element.px 700
        , Element.padding 16
        ]
        [ bellBtn
        , Element.column
            [ Element.height (Element.fill |> Element.maximum 700)
            , Element.scrollbarX
            , Element.spacing 16
            , Element.padding 16
            ]
            (case messages of
                Visible notifications ->
                    notifications
                        |> List.map
                            (\msg ->
                                case msg of
                                    ErrorNotification notification ->
                                        errorNotificationView notification

                                    InfoNotification notification ->
                                        infoNotificationView notification

                                    SuccessNotification notification ->
                                        successNotificationView notification
                            )

                _ ->
                    [ Element.none ]
            )
        ]


header : Model -> Element Msg
header model =
    Element.row
        [ Element.width Element.fill
        , Element.height <| Element.px 80
        , Element.Background.color <| Colors.primaryColor Nothing
        , Element.Font.color <| Colors.lightBody Nothing
        , Element.paddingEach Constants.standardPadding16
        , Element.spaceEvenly
        , Element.below (notificationListView model.notifications)
        ]
        [ Element.el [] <| Element.text "Step Functions - Local"
        , Element.image [ Element.width <| Element.px 40 ]
            { src = "src/static/aws-step-functions-seeklogo.com2.svg"
            , description = "AWS Step Functions Logo"
            }
        ]


stateMachineDataView : List StateMachine -> Element Msg
stateMachineDataView stateMachines =
    Element.table []
        { data = stateMachines
        , columns =
            [ { header =
                    Element.el
                        [ Element.padding 8
                        , Element.Font.bold
                        , Element.Font.size 18
                        , Element.Border.color (Colors.darkBody <| Just 1.0)
                        , Element.Border.widthEach { each | bottom = 1 }
                        ]
                    <|
                        Element.text "Name"
              , width = Element.px 257
              , view =
                    \stateMachine ->
                        Element.Input.button [ Element.scrollbarX ]
                            { label =
                                Element.el
                                    [ Element.Font.size 16
                                    , Element.padding 8
                                    ]
                                <|
                                    Element.text stateMachine.name
                            , onPress = Just <| SelectStateMachine stateMachine
                            }
              }
            , { header =
                    Element.el
                        [ Element.Font.bold
                        , Element.padding 8
                        , Element.Font.size 18
                        , Element.Border.color (Colors.darkBody <| Just 1.0)
                        , Element.Border.widthEach { each | bottom = 1 }
                        ]
                    <|
                        Element.text "Created"
              , width = Element.fill
              , view =
                    \stateMachine ->
                        Element.el
                            [ Element.padding 8
                            , Element.Font.size 16
                            , Element.spacing 8
                            ]
                        <|
                            Element.text <|
                                String.slice 0 19 stateMachine.creationDate
              }
            , { header =
                    Element.el
                        [ Element.Font.bold
                        , Element.padding 8
                        , Element.Font.size 18
                        , Element.Border.color (Colors.darkBody <| Just 1.0)
                        , Element.Border.widthEach { each | bottom = 1 }
                        ]
                    <|
                        Element.text "Action"
              , width = Element.fill
              , view =
                    \stateMachine ->
                        Element.Input.button
                            [ Element.padding 8
                            , Element.Font.size 16
                            , Element.Font.color <| Colors.errorColor <| Just 1.0
                            ]
                            { label = Element.text "Delete"
                            , onPress =
                                Just <| DeleteStateMachine london stateMachine.stateMachineArn
                            }
              }
            ]
        }


stateMachinesView : WebData (List StateMachine) -> Element Msg
stateMachinesView stateMachine =
    Element.column
        [ Element.width Element.fill
        , Element.height Element.fill
        , Element.paddingEach Constants.standardPadding16
        , Element.Border.color <| Colors.primaryColor Nothing
        , Element.Border.width 1
        , Element.Border.rounded 4
        ]
        (case stateMachine of
            NotAsked ->
                [ Element.el [] <| Element.text "NotAsked" ]

            Loading ->
                [ Element.el [] <| Element.text "Loading..." ]

            Failure error ->
                [ Element.el [] <| Element.text ("Error" ++ toString error) ]

            Success stateMachines ->
                [ Element.el [ Element.width Element.fill ] <|
                    Element.row [ Element.width Element.fill ]
                        [ Element.el [ Element.Font.bold, Element.alignLeft ] <|
                            Element.text "State Machines:"
                        , Element.Input.button [ Element.alignRight ]
                            { onPress = Just FetchStateMachines
                            , label =
                                Element.image [ Element.width <| Element.px 20 ]
                                    { src = "src/static/refresh.svg"
                                    , description = "Refresh State Machines button"
                                    }
                            }
                        ]
                , stateMachineDataView stateMachines
                ]
        )


getStatusColor : String -> Color
getStatusColor status =
    case status of
        "SUCCEEDED" ->
            Colors.successColor <| Just 1.0

        "FAILED" ->
            Colors.errorColor <| Just 1.0

        "ABORTED" ->
            Colors.errorColor <| Just 1.0

        _ ->
            Colors.primaryColor <| Just 1.0


executionsTableView : List Execution -> Element Msg
executionsTableView executions =
    Element.table [ Element.paddingXY 0 16, Element.width Element.fill ]
        { data = executions
        , columns =
            [ { header =
                    Element.el
                        [ Element.padding 8
                        , Element.Font.bold
                        , Element.Font.size 18
                        , Element.Border.color (Colors.darkBody <| Just 1.0)
                        , Element.Border.widthEach { each | bottom = 1 }
                        ]
                    <|
                        Element.text "Name"
              , width = Element.fill
              , view =
                    \execution ->
                        Element.Input.button []
                            { label =
                                Element.el
                                    [ Element.padding 8
                                    , Element.Font.size 16
                                    , Element.spacing 8
                                    ]
                                <|
                                    Element.text <|
                                        String.slice 0 8 execution.name
                                            ++ "..."
                            , onPress = Just <| SelectExecution execution
                            }
              }
            , { header =
                    Element.el
                        [ Element.padding 8
                        , Element.Font.bold
                        , Element.Font.size 18
                        , Element.Border.color (Colors.darkBody <| Just 1.0)
                        , Element.Border.widthEach { each | bottom = 1 }
                        ]
                    <|
                        Element.text "Status"
              , width = Element.fill
              , view =
                    \execution ->
                        Element.el
                            [ Element.padding 8
                            , Element.Font.size 16
                            , Element.spacing 8
                            , Element.Font.color <| getStatusColor execution.status
                            ]
                        <|
                            Element.text execution.status
              }
            , { header =
                    Element.el
                        [ Element.padding 8
                        , Element.Font.bold
                        , Element.Font.size 18
                        , Element.Border.color (Colors.darkBody <| Just 1.0)
                        , Element.Border.widthEach { each | bottom = 1 }
                        ]
                    <|
                        Element.text "Started"
              , width = Element.fill
              , view =
                    \execution ->
                        Element.el
                            [ Element.padding 8
                            , Element.Font.size 16
                            , Element.spacing 8
                            ]
                        <|
                            Element.text <|
                                String.slice 0 19 execution.startDate
              }
            , { header =
                    Element.el
                        [ Element.padding 8
                        , Element.Font.bold
                        , Element.Font.size 18
                        , Element.Border.color (Colors.darkBody <| Just 1.0)
                        , Element.Border.widthEach { each | bottom = 1 }
                        ]
                    <|
                        Element.text "Stopped"
              , width = Element.fill
              , view =
                    \execution ->
                        Element.el
                            [ Element.padding 8
                            , Element.Font.size 16
                            , Element.spacing 8
                            ]
                        <|
                            Element.text <|
                                String.slice 0 19 execution.startDate
              }
            , { header =
                    Element.el
                        [ Element.padding 8
                        , Element.Font.bold
                        , Element.Font.size 18
                        , Element.Border.color (Colors.darkBody <| Just 1.0)
                        , Element.Border.widthEach { each | bottom = 1 }
                        ]
                    <|
                        Element.text "Action"
              , width = Element.fill
              , view =
                    \execution ->
                        case execution.status of
                            "RUNNING" ->
                                Element.el
                                    [ Element.padding 8
                                    , Element.Font.size 16
                                    , Element.spacing 8
                                    ]
                                <|
                                    Element.Input.button []
                                        { label =
                                            Element.el
                                                [ Element.Font.color <|
                                                    Colors.errorColor <|
                                                        Just 1.0
                                                ]
                                            <|
                                                Element.text "Stop"
                                        , onPress =
                                            Just <|
                                                StopRunningExecution london execution.executionArn
                                        }

                            _ ->
                                Element.none
              }
            ]
        }


executionsView : Model -> Element Msg
executionsView model =
    Element.column
        [ Element.width Element.fill
        , Element.paddingEach Constants.standardPadding16
        , Element.Border.color <| Colors.primaryColor Nothing
        , Element.Border.width 1
        , Element.Border.rounded 4
        ]
        [ Element.row [ Element.width Element.fill ]
            [ Element.el [ Element.alignLeft, Element.Font.bold ] <| Element.text "Executions:"
            , Element.row [ Element.alignRight, Element.spacing 16 ]
                [ Element.Input.button []
                    { label =
                        Element.image [ Element.width <| Element.px 20 ]
                            { src = "src/static/back.svg"
                            , description = "Back to State Machines button"
                            }
                    , onPress = Just <| SelectView StateMachineView
                    }
                , Element.Input.button []
                    { label =
                        Element.image [ Element.width <| Element.px 20 ]
                            { src = "src/static/refresh.svg"
                            , description = "Refresh Executions button"
                            }
                    , onPress = Just <| FetchStateMachinesExecutions
                    }
                ]
            ]
        , Element.column [ Element.paddingXY 0 16, Element.width Element.fill ]
            (case model.active of
                StateMachineView ->
                    [ Element.none ]

                ExecutionsView stateMachine ->
                    [ Element.el [] <| Element.text stateMachine.name
                    , case model.executions of
                        NotAsked ->
                            Element.el [] <| Element.text "NotAsked"

                        Loading ->
                            Element.el [ Element.paddingXY 0 16 ] <| Element.text "Loading..."

                        Failure e ->
                            Element.el [] <| Element.text <| toString e

                        Success executions ->
                            executionsTableView executions
                    ]

                ExecutionHistoryView _ ->
                    [ Element.none ]
            )
        ]


getProperAppWidth : Active -> Int
getProperAppWidth active =
    case active of
        StateMachineView ->
            Constants.defaultWidth

        ExecutionsView _ ->
            Constants.executionsWidth

        ExecutionHistoryView _ ->
            Constants.executionHistoryWidth


stepColor : Event -> Color
stepColor event =
    case event of
        Start _ ->
            Colors.primaryColor <| Just 1.0

        Entered _ ->
            Colors.primaryColor <| Just 1.0

        Exited _ ->
            Colors.primaryColor <| Just 1.0

        LambdaScheduled _ ->
            Colors.primaryColor <| Just 1.0

        BaseEvent ev ->
            let
                color =
                    case ev.type_ of
                        "ExecutionFailed" ->
                            Colors.errorColor <| Just 1.0

                        "ExecutionAborted" ->
                            Colors.errorColor <| Just 1.0

                        "TaskSubmitFailed" ->
                            Colors.errorColor <| Just 1.0

                        _ ->
                            Colors.primaryColor <| Just 1.0
            in
            color

        LambdaFailed _ ->
            Colors.errorColor <| Just 1.0

        Succeeded _ ->
            Colors.successColor <| Just 1.0


executionHistoryTableView : List Event -> Element Msg
executionHistoryTableView events =
    Element.table
        [ Element.paddingXY 0 16
        , Element.width Element.fill
        , Element.height <| Element.px 680
        , Element.scrollbarX
        ]
        { data = events
        , columns =
            [ { header =
                    Element.el
                        [ Element.padding 8
                        , Element.Font.bold
                        , Element.Font.size 18
                        , Element.Border.color (Colors.darkBody <| Just 1.0)
                        , Element.Border.widthEach { each | bottom = 1 }
                        ]
                    <|
                        Element.text "Name"
              , width = Element.fill
              , view =
                    \event ->
                        let
                            t =
                                case event of
                                    Start ev ->
                                        ev.type_

                                    Entered ev ->
                                        ev.type_

                                    Exited ev ->
                                        ev.type_

                                    LambdaScheduled ev ->
                                        ev.type_

                                    BaseEvent ev ->
                                        ev.type_

                                    LambdaFailed ev ->
                                        ev.type_

                                    Succeeded ev ->
                                        ev.type_
                        in
                        Element.Input.button
                            [ Element.scrollbarX ]
                            { label =
                                Element.el
                                    [ Element.Font.size 16
                                    , Element.padding 8
                                    , Element.Font.color <| stepColor event
                                    ]
                                <|
                                    Element.text t
                            , onPress = Just <| NoOp
                            }
              }
            , { header =
                    Element.el
                        [ Element.padding 8
                        , Element.Font.bold
                        , Element.Font.size 18
                        , Element.Border.color (Colors.darkBody <| Just 1.0)
                        , Element.Border.widthEach { each | bottom = 1 }
                        ]
                    <|
                        Element.text "Timestamp"
              , width = Element.fill
              , view =
                    \event ->
                        let
                            timestamp =
                                case event of
                                    Start startedEvent ->
                                        startedEvent.timestamp

                                    Entered stateEntered ->
                                        stateEntered.timestamp

                                    Exited stateExited ->
                                        stateExited.timestamp

                                    LambdaScheduled lambdaFunctionScheduled ->
                                        lambdaFunctionScheduled.timestamp

                                    BaseEvent base ->
                                        base.timestamp

                                    LambdaFailed lambdaFunctionFailed ->
                                        lambdaFunctionFailed.timestamp

                                    Succeeded succeededEvent ->
                                        succeededEvent.timestamp
                        in
                        Element.el
                            [ Element.Font.size 16
                            , Element.padding 8
                            ]
                        <|
                            Element.text <|
                                String.slice 0 19 timestamp
              }
            , { header =
                    Element.el
                        [ Element.padding 8
                        , Element.Font.bold
                        , Element.Font.size 18
                        , Element.Border.color (Colors.darkBody <| Just 1.0)
                        , Element.Border.widthEach { each | bottom = 1 }
                        ]
                    <|
                        Element.text "State"
              , width = Element.px 600
              , view =
                    \event ->
                        case event of
                            Start ev ->
                                executionStartView ev.executionStartedEventDetails

                            Entered ev ->
                                executionEnteredView ev.stateEnteredEventDetails

                            Exited ev ->
                                stateExitedView ev.stateExitedEventDetails

                            LambdaScheduled ev ->
                                lambdaScheduledView ev.lambdaFunctionScheduledEventDetails

                            BaseEvent ev ->
                                baseEventView ev

                            LambdaFailed ev ->
                                lambdaFailedView ev.lambdaFunctionFailedEventDetails

                            Succeeded ev ->
                                succeedView ev.executionSucceededEventDetails
              }
            ]
        }


succeedView : SucceededEventDetails -> Element msg
succeedView event =
    Element.row
        [ Element.scrollbarX
        , Element.padding 16
        ]
        [ Element.el [ Element.Font.size 16 ] <| Element.text event.output ]


lambdaFailedView : LambdaFunctionFailedDetails -> Element msg
lambdaFailedView event =
    Element.row
        [ Element.scrollbarX
        , Element.padding 16
        , Element.spacing 16
        ]
        [ Element.el [ Element.Font.size 16 ] <| Element.text event.error
        , Element.el [ Element.Font.size 16 ] <| Element.text event.cause
        ]


baseEventView : Base -> Element msg
baseEventView event =
    Element.row
        [ Element.scrollbarX
        , Element.padding 16
        ]
        [ Element.el [ Element.Font.size 16 ] <| Element.text event.timestamp ]


lambdaScheduledView : LambdaScheduledDetails -> Element msg
lambdaScheduledView event =
    Element.row
        [ Element.scrollbarX
        , Element.padding 16
        ]
        [ Element.el [ Element.Font.size 16 ] <| Element.text event.resource
        , Element.el [ Element.Font.size 16 ] <| Element.text event.input
        ]


stateExitedView : StateExitedDetails -> Element msg
stateExitedView event =
    Element.column
        [ Element.padding 16
        , Element.height <| Element.px 250
        , Element.spacing 16
        ]
        [ Element.el [ Element.Font.size 16, Element.width Element.fill ] <|
            Element.text event.name
        , Element.paragraph
            [ Element.Font.size 16
            , Element.scrollbarX
            , Element.height <| Element.px 200
            , Html.Attributes.style "word-break" "break-all" |> Element.htmlAttribute
            ]
            [ Element.text event.output ]
        ]


executionEnteredView : StateEnteredDetails -> Element msg
executionEnteredView event =
    Element.column
        [ Element.padding 16
        , Element.height <| Element.px 250
        , Element.spacing 16
        ]
        [ Element.el [ Element.Font.size 16 ] <| Element.text event.name
        , Element.paragraph
            [ Element.Font.size 16
            , Element.scrollbarX
            , Element.height <| Element.px 200
            , Html.Attributes.style "word-break" "break-all" |> Element.htmlAttribute
            ]
            [ Element.text event.input ]
        ]


executionStartView : StartedEventDetails -> Element msg
executionStartView event =
    Element.row
        [ Element.scrollbarX
        , Element.padding 16
        ]
        [ Element.el [ Element.Font.size 16 ] <| Element.text event.roleArn
        , Element.el [ Element.Font.size 16 ] <| Element.text event.input
        ]


executionHistoryView : Model -> Element Msg
executionHistoryView model =
    let
        executionId =
            case model.active of
                StateMachineView ->
                    "Events"

                ExecutionsView _ ->
                    "Events"

                ExecutionHistoryView execution ->
                    "Events for \"" ++ execution.executionArn ++ "\""
    in
    Element.column
        [ Element.width Element.fill
        , Element.paddingEach Constants.standardPadding16
        , Element.Border.color <| Colors.primaryColor Nothing
        , Element.Border.width 1
        , Element.Border.rounded 4
        ]
        [ Element.row [ Element.width Element.fill ]
            [ Element.el [ Element.alignLeft, Element.Font.bold ] <| Element.text executionId
            , Element.row [ Element.alignRight, Element.spacing 16 ]
                [ Element.Input.button []
                    { label =
                        Element.image [ Element.width <| Element.px 20 ]
                            { src = "src/static/back.svg"
                            , description = "Back to Executions button"
                            }
                    , onPress =
                        case model.active of
                            StateMachineView ->
                                Nothing

                            ExecutionsView _ ->
                                Nothing

                            ExecutionHistoryView execution ->
                                Just <|
                                    FetchStateMachine london execution.stateMachineArn
                    }
                , Element.Input.button []
                    { label =
                        Element.image [ Element.width <| Element.px 20 ]
                            { src = "src/static/refresh.svg"
                            , description = "Refresh Events button"
                            }
                    , onPress = Just FetchEvents
                    }
                ]
            ]
        , case model.events of
            NotAsked ->
                Element.none

            Loading ->
                Element.text "Loading..."

            Failure e ->
                Element.text <| toString e

            Success a ->
                executionHistoryTableView a
        ]


body : Model -> Element Msg
body model =
    Element.column
        [ Element.width <| Element.px <| getProperAppWidth model.active
        , Element.centerX
        , Element.paddingEach Constants.standardPadding16
        ]
        [ case model.active of
            StateMachineView ->
                stateMachinesView model.stateMachines

            ExecutionsView _ ->
                executionsView model

            ExecutionHistoryView _ ->
                executionHistoryView model
        ]


layout : Model -> Element Msg
layout model =
    Element.column [ Element.width Element.fill ]
        [ header model
        , body model
        ]



-- CORE


init : Flags -> Url -> Key -> ( Model, Cmd Msg )
init _ _ _ =
    ( { stateMachines = Loading
      , active = StateMachineView
      , executions = NotAsked
      , events = NotAsked
      , notifications = Hidden []
      , randomInt = 1
      }
    , Cmd.batch
        [ getStateMachines london ]
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ChangeUrl _ ->
            ( model, Cmd.none )

        ClickLink _ ->
            ( model, Cmd.none )

        HandleFetchingStateMachines webData ->
            let
                ( data, cmd ) =
                    case webData of
                        NotAsked ->
                            ( NotAsked, Cmd.none )

                        Loading ->
                            ( Loading, Cmd.none )

                        Failure e ->
                            ( Failure e
                            , perform <|
                                PostErrorNotification
                                    ("ERROR: Fetching state machines failed (" ++ toString e ++ ").")
                            )

                        Success response ->
                            ( Success response.stateMachines
                            , perform <| PostInfoNotification "Got the State Machines!"
                            )
            in
            ( { model | stateMachines = data }
            , cmd
            )

        NoOp ->
            ( model, Cmd.none )

        FetchStateMachines ->
            ( { model | stateMachines = Loading }, getStateMachines london )

        SelectStateMachine stateMachine ->
            ( { model | active = ExecutionsView stateMachine, executions = Loading }
            , getStateMachineExecutions london stateMachine.stateMachineArn
            )

        SelectView active ->
            ( { model | active = active }, Cmd.none )

        HandleFetchingStateMachineExecutions webData ->
            let
                ( data, cmd ) =
                    case webData of
                        NotAsked ->
                            ( NotAsked, Cmd.none )

                        Loading ->
                            ( Loading, Cmd.none )

                        Failure e ->
                            ( Failure e
                            , perform <|
                                PostErrorNotification <|
                                    "ERROR: Failed to fetch executions ("
                                        ++ toString e
                                        ++ ")."
                            )

                        Success response ->
                            ( Success response.executions
                            , perform <| PostInfoNotification <| "Got the executions!"
                            )
            in
            ( { model | executions = data }, cmd )

        -- Random.generate GotSeed <| Random.int 1 1000000
        FetchStateMachinesExecutions ->
            let
                cmd =
                    case model.active of
                        StateMachineView ->
                            Cmd.none

                        ExecutionsView stateMachine ->
                            getStateMachineExecutions london stateMachine.stateMachineArn

                        ExecutionHistoryView _ ->
                            Cmd.none
            in
            ( { model | executions = Loading }, cmd )

        HandleFetchingEvents webData ->
            let
                ( events, cmd ) =
                    case webData of
                        NotAsked ->
                            ( NotAsked, Cmd.none )

                        Loading ->
                            ( Loading, Cmd.none )

                        Failure e ->
                            ( Failure e
                            , perform <|
                                PostErrorNotification <|
                                    "ERROR: Fetching events failed ("
                                        ++ toString e
                                        ++ ")."
                            )

                        Success response ->
                            ( Success response.events
                            , perform <| PostInfoNotification "Got the events!"
                            )
            in
            ( { model | events = events }
            , cmd
            )

        SelectExecution execution ->
            ( { model | active = ExecutionHistoryView execution, events = Loading }
            , getEvents london execution.executionArn
            )

        HandleDeleteStateMachine webData ->
            let
                cmd =
                    case webData of
                        Loading ->
                            Cmd.none

                        NotAsked ->
                            Cmd.none

                        Failure e ->
                            perform <|
                                PostErrorNotification <|
                                    "ERROR: Failed to delete State Machine. ("
                                        ++ toString e
                                        ++ ")"

                        Success _ ->
                            perform <|
                                PostInfoNotification "State Machine was deleted successfully!"
            in
            ( { model
                | active = StateMachineView
                , stateMachines = Loading
                , executions = NotAsked
                , events = NotAsked
              }
            , Cmd.batch
                [ getStateMachines london

                --, Random.generate GotSeed <| Random.int 1 1000000
                , cmd
                ]
            )

        DeleteStateMachine region arn ->
            ( model, deleteStateMachine region arn )

        FetchEvents ->
            let
                cmd =
                    case model.active of
                        StateMachineView ->
                            Cmd.none

                        ExecutionsView _ ->
                            Cmd.none

                        ExecutionHistoryView execution ->
                            getEvents london execution.executionArn
            in
            ( { model | events = Loading }, cmd )

        HandleFetchingStateMachine webData ->
            let
                ( active, cmd ) =
                    case webData of
                        Success stateMachine ->
                            ( ExecutionsView stateMachine
                            , perform <|
                                PostInfoNotification <|
                                    "Got \""
                                        ++ stateMachine.name
                                        ++ "\"."
                            )

                        Failure errorStatus ->
                            ( model.active
                            , perform <|
                                PostErrorNotification <|
                                    "ERROR: Failed to get state machine information ("
                                        ++ toString errorStatus
                                        ++ ")"
                            )

                        _ ->
                            ( model.active, Cmd.none )
            in
            ( { model | active = active }
            , cmd
              --Random.generate GotSeed <| Random.int 1 1000000
            )

        FetchStateMachine region arn ->
            ( model, getStateMachine region arn )

        StopRunningExecution region arn ->
            ( model, stopRunningExecution region arn )

        HandlePostMachine webData ->
            let
                cmd =
                    case webData of
                        NotAsked ->
                            Cmd.none

                        Loading ->
                            Cmd.none

                        Failure e ->
                            perform <|
                                PostErrorNotification <|
                                    "ERROR: Execution failed to stop. ("
                                        ++ toString e
                                        ++ ")"

                        Success _ ->
                            case model.active of
                                StateMachineView ->
                                    Cmd.none

                                ExecutionsView stateMachine ->
                                    getStateMachineExecutions london stateMachine.stateMachineArn

                                ExecutionHistoryView _ ->
                                    Cmd.none
            in
            ( model, cmd )

        ClearNotification uuid ->
            let
                notifications =
                    case model.notifications of
                        Cleared ->
                            []

                        Visible n ->
                            n

                        Hidden n ->
                            n

                filteredNotifications =
                    List.filter
                        (\notification ->
                            isSameNotification notification uuid
                        )
                        notifications

                modelNotifications =
                    case List.length filteredNotifications of
                        0 ->
                            Hidden filteredNotifications

                        _ ->
                            Visible filteredNotifications
            in
            ( { model | notifications = modelNotifications }, Cmd.none )

        PostErrorNotification message ->
            let
                uuid =
                    Random.step UUID.generator (Random.initialSeed model.randomInt)
                        |> Tuple.first

                notification =
                    ErrorNotification { message = message, uuid = uuid }

                modelNotifications =
                    case model.notifications of
                        Hidden n ->
                            Hidden (List.append [ notification ] n)

                        Visible n ->
                            Visible (List.append [ notification ] n)

                        Cleared ->
                            Cleared

                -- notifications =
                --     List.append [ notification ] modelNotifications
            in
            ( { model | notifications = modelNotifications }
            , Random.generate GotSeed <| Random.int 1 1000000
            )

        PostSuccessNotification message ->
            let
                uuid =
                    Random.step UUID.generator (Random.initialSeed model.randomInt)
                        |> Tuple.first

                notification =
                    SuccessNotification { message = message, uuid = uuid }

                modelNotifications =
                    case model.notifications of
                        Hidden n ->
                            Hidden (List.append [ notification ] n)

                        Visible n ->
                            Visible (List.append [ notification ] n)

                        Cleared ->
                            Cleared

                -- notifications =
                --     List.append [ notification ] model.notifications
            in
            ( { model | notifications = modelNotifications }
            , Random.generate GotSeed <| Random.int 1 1000000
            )

        PostInfoNotification message ->
            let
                uuid =
                    Random.step UUID.generator (Random.initialSeed model.randomInt)
                        |> Tuple.first

                notification =
                    InfoNotification { message = message, uuid = uuid }

                modelNotifications =
                    case model.notifications of
                        Hidden n ->
                            Hidden (List.append [ notification ] n)

                        Visible n ->
                            Visible (List.append [ notification ] n)

                        Cleared ->
                            Cleared
            in
            ( { model | notifications = modelNotifications }
            , Random.generate GotSeed <| Random.int 1 1000000
            )

        GotSeed int ->
            ( { model | randomInt = int }, Cmd.none )

        ShowNotifications ->
            let
                notifications =
                    case model.notifications of
                        Visible n ->
                            Visible n

                        Hidden n ->
                            Visible n

                        Cleared ->
                            Cleared
            in
            ( { model | notifications = notifications }, Cmd.none )

        HideNotifications ->
            let
                notifications =
                    case model.notifications of
                        Visible n ->
                            Hidden n

                        Hidden n ->
                            Hidden n

                        Cleared ->
                            Cleared
            in
            ( { model | notifications = notifications }, Cmd.none )


isSameNotification : Notification -> UUID -> Bool
isSameNotification notification compareUuid =
    let
        uuid =
            case notification of
                ErrorNotification baseNotification ->
                    baseNotification.uuid

                InfoNotification baseNotification ->
                    baseNotification.uuid

                SuccessNotification baseNotification ->
                    baseNotification.uuid
    in
    UUID.compare compareUuid uuid /= EQ


view : Model -> Document Msg
view model =
    { title = "Step Functions - Local"
    , body =
        [ Element.layout [ Element.width Element.fill ] (layout model) ]
    }


main : Program Flags Model Msg
main =
    Browser.application
        { init = init
        , update = update
        , view = view
        , subscriptions = \_ -> Sub.none
        , onUrlRequest = ClickLink
        , onUrlChange = ChangeUrl
        }
