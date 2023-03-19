module Main exposing (..)

--import Constants
--import Graph
--import List exposing (map)
--import Svg exposing (Svg, circle, g, line, polygon, rect, svg)
--import Svg.Attributes as SvgAttr

import Api exposing (deleteStateMachine, getEvents, getStateMachine, getStateMachineExecutions, getStateMachines)
import Browser exposing (Document)
import Browser.Navigation exposing (Key)
import Colors
import Constants exposing (each)
import Debug exposing (toString)
import Element exposing (Color, Element)
import Element.Background
import Element.Border
import Element.Font
import Element.Input
import RemoteData exposing (RemoteData(..), WebData)
import Types exposing (Active(..), Base, Event(..), Execution, Flags, LambdaFunctionFailedDetails, LambdaScheduledDetails, Model, Msg(..), StartedEventDetails, StateEnteredDetails, StateExitedDetails, StateMachine, SucceededEventDetails)
import Url exposing (Url)


header : Element msg
header =
    Element.row
        [ Element.width Element.fill
        , Element.height <| Element.px 80
        , Element.Background.color <| Colors.primaryColor Nothing
        , Element.Font.color <| Colors.lightBody Nothing
        , Element.paddingEach Constants.standardPadding16
        , Element.spaceEvenly
        ]
        [ Element.el [] <| Element.text "Step Functions - Local"
        , Element.image [ Element.width <| Element.px 40 ] { src = "src/static/aws-step-functions-seeklogo.com2.svg", description = "AWS Step Functions Logo" }
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
                            , onPress = Just <| DeleteStateMachine "eu-west-2" stateMachine.stateMachineArn
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

        Entered ev ->
            Colors.primaryColor <| Just 1.0

        Exited ev ->
            Colors.primaryColor <| Just 1.0

        LambdaScheduled ev ->
            Colors.primaryColor <| Just 1.0

        BaseEvent ev ->
            let
                color =
                    case ev.type_ of
                        "ExecutionFailed" ->
                            Colors.errorColor <| Just 1.0

                        _ ->
                            Colors.primaryColor <| Just 1.0
            in
            color

        LambdaFailed ev ->
            Colors.errorColor <| Just 1.0

        Succeeded ev ->
            Colors.successColor <| Just 1.0


executionHistoryTableView : List Event -> Element Msg
executionHistoryTableView events =
    Element.table [ Element.paddingXY 0 16, Element.width Element.fill ]
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
        ]
        [ Element.el [ Element.Font.size 16 ] <| Element.text event.cause
        , Element.el [ Element.Font.size 16 ] <| Element.text event.error
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
    Element.row
        [ Element.scrollbarX
        , Element.padding 16
        ]
        [ Element.el [ Element.Font.size 16 ] <| Element.text event.name
        , Element.el [ Element.Font.size 16 ] <| Element.text event.output
        ]


executionEnteredView : StateEnteredDetails -> Element msg
executionEnteredView event =
    Element.row
        [ Element.scrollbarX
        , Element.padding 16
        ]
        [ Element.el [ Element.Font.size 16 ] <| Element.text event.name
        , Element.el [ Element.Font.size 16 ] <| Element.text event.input
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
    Element.column
        [ Element.width Element.fill
        , Element.paddingEach Constants.standardPadding16
        , Element.Border.color <| Colors.primaryColor Nothing
        , Element.Border.width 1
        , Element.Border.rounded 4
        ]
        [ Element.row [ Element.width Element.fill ]
            [ Element.el [ Element.alignLeft, Element.Font.bold ] <| Element.text "Events"
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
                                Just <| NoOp

                            ExecutionsView _ ->
                                Just <| NoOp

                            ExecutionHistoryView execution ->
                                Just <|
                                    FetchStateMachine "eu-west-2" execution.stateMachineArn
                    }
                , Element.Input.button []
                    { label =
                        Element.image [ Element.width <| Element.px 20 ]
                            { src = "src/static/refresh.svg"
                            , description = "Refresh Events button"
                            }
                    , onPress = Just <| FetchEvents
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
        [ header
        , body model
        ]



-- CORE


init : Flags -> Url -> Key -> ( Model, Cmd Msg )
init flags url navKey =
    ( { stateMachines = Loading
      , active = StateMachineView
      , executions = NotAsked
      , events = NotAsked
      }
    , Cmd.batch
        [ getStateMachines "eu-west-2"
        ]
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ChangeUrl url ->
            ( model, Cmd.none )

        ClickLink urlRequest ->
            ( model, Cmd.none )

        HandleFetchingStateMachines webData ->
            let
                data =
                    case webData of
                        NotAsked ->
                            NotAsked

                        Loading ->
                            Loading

                        Failure e ->
                            Failure e

                        Success response ->
                            Success response.stateMachines
            in
            ( { model | stateMachines = data }, Cmd.none )

        NoOp ->
            ( model, Cmd.none )

        FetchStateMachines ->
            ( { model | stateMachines = Loading }, getStateMachines "eu-west-2" )

        SelectStateMachine stateMachine ->
            ( { model | active = ExecutionsView stateMachine, executions = Loading }
            , getStateMachineExecutions "eu-west-2" stateMachine.stateMachineArn
            )

        SelectView active ->
            ( { model | active = active }, Cmd.none )

        HandleFetchingStateMachineExecutions webData ->
            let
                data =
                    case webData of
                        NotAsked ->
                            NotAsked

                        Loading ->
                            Loading

                        Failure e ->
                            Failure e

                        Success response ->
                            Success response.executions
            in
            ( { model | executions = data }, Cmd.none )

        FetchStateMachinesExecutions ->
            let
                cmd =
                    case model.active of
                        StateMachineView ->
                            Cmd.none

                        ExecutionsView stateMachine ->
                            getStateMachineExecutions "eu-west-2" stateMachine.stateMachineArn

                        ExecutionHistoryView _ ->
                            Cmd.none
            in
            ( { model | executions = Loading }, cmd )

        HandleFetchingEvents webData ->
            let
                events =
                    case webData of
                        NotAsked ->
                            NotAsked

                        Loading ->
                            Loading

                        Failure e ->
                            Failure e

                        Success response ->
                            Success response.events
            in
            ( { model | events = events }, Cmd.none )

        SelectExecution execution ->
            ( { model | active = ExecutionHistoryView execution, events = Loading }
            , getEvents "eu-west-2" execution.executionArn
            )

        HandleDeleteStateMachine _ ->
            ( { model
                | active = StateMachineView
                , stateMachines = Loading
                , executions = NotAsked
                , events = NotAsked
              }
            , getStateMachines "eu-west-2"
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
                            getEvents "eu-west-2" execution.executionArn
            in
            ( { model | events = Loading }, cmd )

        HandleFetchingStateMachine webData ->
            let
                active =
                    case webData of
                        Success stateMachine ->
                            ExecutionsView stateMachine

                        _ ->
                            model.active
            in
            ( { model | active = active }, Cmd.none )

        FetchStateMachine region arn ->
            ( model, getStateMachine region arn )


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
