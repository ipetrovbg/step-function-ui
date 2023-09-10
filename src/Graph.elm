module Graph exposing
    ( calcTextWidth
    , downPolygon
    , graphWidth
    , prepareNodes
    , renderNode
    , renderRectTextNode
    , svgFragment
    , upPolygon
    )

import Constants
import Dict exposing (Dict)
import Svg exposing (Svg, font)
import Svg.Attributes exposing (..)
import Types exposing (LinePoint, NodeKind(..), Point, StateMachineState)


getChar : Maybe ( Char, String ) -> Char
getChar m =
    case m of
        Just ( c, s ) ->
            c

        Nothing ->
            'a'


calcTextWidth : String -> Int
calcTextWidth str =
    String.length str * 13



-- let
--     d =
--         String.toList str
--             |> List.map
--                 (\char ->
--                     if Char.isAlpha char then
--                         if Char.isUpper char then
--                             case char of
--                                 'L' ->
--                                     14
--                                 'I' ->
--                                     10
--                                 'W' ->
--                                     20
--                                 'M' ->
--                                     20
--                                 _ ->
--                                     17
--                         else
--                             case char of
--                                 'l' ->
--                                     8
--                                 'i' ->
--                                     5
--                                 _ ->
--                                     13
--                     else
--                         20
--                 )
--     _ =
--         Debug.log str (List.sum d)
-- in
-- List.sum d


upPolygon : Svg msg
upPolygon =
    Svg.svg [ width "15", height "15" ]
        [ Svg.polygon [ points "7,0 15,15 0, 15", fill "black" ] []
        ]


downPolygon : Svg msg
downPolygon =
    Svg.svg [ width "15", height "15" ]
        [ Svg.polygon [ points "0,0 15,0 7,15", fill "black" ] []
        ]


svgFragment : Int -> Point -> List ( Svg msg, Svg msg ) -> Svg msg
svgFragment svgWidth point svgs =
    Svg.svg
        [ width <| Constants.toString svgWidth
        , height <| Constants.toString svgWidth
        , viewBox ("0 " ++ Constants.toString point.y ++ " " ++ Constants.toString svgWidth ++ " " ++ Constants.toString svgWidth)
        , strokeWidth <| Constants.calcBorder 0
        , stroke "black"
        ]
    <|
        List.append
            [ Svg.defs []
                [ Svg.marker
                    [ id "right-arrow"
                    , markerWidth "10"
                    , markerHeight "7"
                    , refX "0"
                    , refY "3.5"
                    , orient "auto"
                    ]
                    [ Svg.polygon [ points "0 0, 10 3.5, 0 7" ] []
                    ]
                ]
            ]
        <|
            List.concatMap
                (\( rect, textNode ) -> [ rect, textNode ])
                svgs


renderLine : LinePoint -> Svg msg
renderLine line =
    Svg.line
        [ x1 <| Constants.toString line.x1
        , y1 <| Constants.toString line.y1
        , y2 <| Constants.toString line.y2
        , x2 <| Constants.toString line.x2
        , markerEnd "url(#right-arrow)"
        ]
        []


renderRectTextNode : Int -> Int -> Int -> String -> ( Svg msg, Svg msg )
renderRectTextNode offsetX offsetY heightInt text =
    ( Svg.rect
        [ strokeWidth <| Constants.calcBorder 0
        , stroke "black"
        , fill "none"
        , width <| Constants.toString (calcTextWidth text)
        , height <| Constants.toString heightInt
        , y <| Constants.toString offsetY
        , x <| Constants.toString offsetX
        , rx <| Constants.toString Constants.rectRoundValue
        , ry <| Constants.toString Constants.rectRoundValue
        , r "50"
        ]
        []
    , Svg.text_
        [ textAnchor "middle"
        , fontFamily "Courier Prime"

        -- , textLength <| Constants.toString (calcTextWidth text)
        , alignmentBaseline "middle"
        , y <| Constants.calcBorder <| (Basics.round <| Basics.toFloat heightInt / 2) + offsetY
        , x <| Constants.calcBorder <| (Basics.round <| Basics.toFloat (calcTextWidth text) / 2) + offsetX
        ]
        [ Svg.text text ]
    )


spaceBetween : Int
spaceBetween =
    70


nodeHeight : Int
nodeHeight =
    35


graphWidth : Int
graphWidth =
    780


renderNode : ( String, NodeKind ) -> ( Svg msg, Svg msg )
renderNode ( txt, node ) =
    case node of
        Rect p ->
            renderRectTextNode p.x p.y nodeHeight txt

        Line l ->
            ( renderLine l, Svg.rect [] [] )


transformToNode : MappingStruct -> List ( String, NodeKind ) -> List ( String, NodeKind )
transformToNode mapping l =
    let
        { isLast, node, txt } =
            mapping

        maybeItem =
            if List.length l == 1 then
                List.reverse l
                    |> List.head

            else
                List.reverse l
                    |> List.tail
                    |> Maybe.withDefault []
                    |> List.head

        point =
            case maybeItem of
                Just ( t, pointer ) ->
                    case pointer of
                        Rect r ->
                            if not isLast then
                                case node of
                                    Rect nodeRect ->
                                        -- Everything inbetween
                                        [ ( txt, Rect { x = nodeRect.x, y = r.y + spaceBetween } )
                                        , ( ""
                                          , Line
                                                { x1 = r.x + Basics.round (Basics.toFloat (calcTextWidth t) / 2)
                                                , y1 = r.y + nodeHeight
                                                , x2 = nodeRect.x + Basics.round (Basics.toFloat (calcTextWidth txt) / 2)
                                                , y2 = r.y + spaceBetween - 10
                                                }
                                          )
                                        ]

                                    _ ->
                                        []

                            else
                                case node of
                                    Rect nodeRect ->
                                        -- Last step
                                        [ ( txt, Rect { x = nodeRect.x, y = r.y + spaceBetween } )
                                        , ( ""
                                          , Line
                                                { x1 = r.x + Basics.round (Basics.toFloat (calcTextWidth t) / 2)
                                                , y1 = r.y + nodeHeight
                                                , x2 = nodeRect.x + Basics.round (Basics.toFloat (calcTextWidth txt) / 2)
                                                , y2 = r.y + spaceBetween - 10
                                                }
                                          )
                                        ]

                                    _ ->
                                        []

                        _ ->
                            []

                Nothing ->
                    case node of
                        -- First step
                        Rect r ->
                            -- "r.y +<something>" determines where the graph should start from
                            [ ( txt, Rect { x = r.x, y = r.y + 16 } ) ]

                        _ ->
                            []
    in
    List.append l point


type alias MappingStruct =
    { txt : String
    , node : NodeKind
    , isLast : Bool
    }


prepareNodes : List String -> Dict String StateMachineState -> Int -> List ( String, NodeKind )
prepareNodes data _ svgWidth =
    List.foldl transformToNode
        []
        (data
            |> List.indexedMap Tuple.pair
            |> List.map
                (\( i, txt ) ->
                    { txt = txt
                    , node =
                        Rect
                            { x =
                                (Basics.round <| Basics.toFloat svgWidth / 2)
                                    - (Basics.round <| Basics.toFloat (calcTextWidth txt) / 2)
                            , y = 0
                            }
                    , isLast = i + 1 == List.length data
                    }
                )
        )
