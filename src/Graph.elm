module Graph exposing (calcTextWidth, renderRectTextNode)

import Constants
import Svg exposing (Svg)
import Svg.Attributes as SvgAttr


calcTextWidth : String -> Int
calcTextWidth str =
    String.toList str
        |> List.map
            (\char ->
                if Char.isAlpha char then
                    if Char.isUpper char then
                        15

                    else
                        11

                else
                    5
            )
        |> List.sum


renderRectTextNode : Int -> Int -> String -> Svg msg
renderRectTextNode offset height text =
    Svg.svg [ SvgAttr.x <| Constants.toString offset ]
        [ Svg.rect
            [ SvgAttr.strokeWidth <| Constants.calcBorder 0
            , SvgAttr.stroke "black"
            , SvgAttr.fill "none"
            , SvgAttr.width <| Constants.toString (calcTextWidth text)
            , SvgAttr.height <| Constants.toString height
            , SvgAttr.y <| Constants.calcBorder 0
            , SvgAttr.x <| Constants.calcBorder 0
            , SvgAttr.rx <| Constants.toString Constants.rectRoundValue
            , SvgAttr.ry <| Constants.toString Constants.rectRoundValue
            , SvgAttr.r "50"
            ]
            []
        , Svg.text_
            [ SvgAttr.textAnchor "middle"

            --, SvgAttr.textLength <| Constants.toString (calcTextWidth text - 20)
            , SvgAttr.alignmentBaseline "middle"
            , SvgAttr.y <| Constants.calcBorder (Basics.round <| Basics.toFloat height / 2)
            , SvgAttr.x <| Constants.calcBorder (Basics.round <| Basics.toFloat (calcTextWidth text) / 2)
            ]
            [ Svg.text text ]
        ]
