module Constants exposing
    ( borderWidth
    , calcBorder
    , defaultWidth
    , each
    , executionHistoryWidth
    , executionsWidth
    , londonRegion
    , movingGraphDistance
    , rectRoundValue
    , standardPadding16
    , toString
    )

import Types exposing (Region(..))


londonRegion : Region
londonRegion =
    Region "eu-west-2"


rectRoundValue : Int
rectRoundValue =
    4


movingGraphDistance : Int
movingGraphDistance =
    25


borderWidth : Int
borderWidth =
    1


calcBorder : Int -> String
calcBorder int =
    toString <| int + borderWidth


toString : Int -> String
toString int =
    String.fromInt int


standardPadding16 =
    { top = 16, left = 16, bottom = 16, right = 16 }


defaultWidth : Int
defaultWidth =
    600


executionsWidth : Int
executionsWidth =
    980


executionHistoryWidth : Int
executionHistoryWidth =
    1600


each =
    { top = 0, left = 0, right = 0, bottom = 0 }
