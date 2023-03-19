module Constants exposing
    ( borderWidth
    , calcBorder
    , defaultWidth
    , each
    , executionHistoryWidth
    , executionsWidth
    , rectRoundValue
    , standardPadding16
    , toString
    )


rectRoundValue =
    8


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


defaultWidth =
    600


executionsWidth =
    980


executionHistoryWidth =
    1200


each =
    { top = 0, left = 0, right = 0, bottom = 0 }
