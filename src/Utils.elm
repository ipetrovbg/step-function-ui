module Utils exposing (inOutEvents, perform)

import Task
import Types exposing (Event(..))


perform : msg -> Cmd msg
perform =
    Task.perform identity << Task.succeed


isInOutEvent : Event -> Bool
isInOutEvent ev =
    case ev of
        Entered _ ->
            True

        Exited _ ->
            True

        _ ->
            False


chunkList : List a -> List ( a, a )
chunkList items =
    case items of
        [] ->
            []

        [ _ ] ->
            []

        x :: y :: ys ->
            ( x, y ) :: chunkList (y :: ys)


isInOutEventTuple : ( Event, Event ) -> Bool
isInOutEventTuple eventTuple =
    case eventTuple of
        ( Entered _, Exited _ ) ->
            True

        ( _, _ ) ->
            False


inOutEvents : List Event -> List ( Event, Event )
inOutEvents events =
    events
        |> List.filter isInOutEvent
        |> chunkList
        |> List.filter isInOutEventTuple
