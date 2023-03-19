module Colors exposing (..)

-- COLORS

import Element exposing (Color)


getMaybeColor : { r : Int, g : Int, b : Int, a : Maybe Float } -> Color
getMaybeColor { r, g, b, a } =
    case a of
        Just alfa ->
            Element.rgba255 r g b alfa

        Nothing ->
            Element.rgb255 r g b


primaryColor : Maybe Float -> Color
primaryColor maybeAlfa =
    let
        r =
            29

        g =
            53

        b =
            87
    in
    getMaybeColor { r = r, g = g, b = b, a = maybeAlfa }


whiteColor : Maybe Float -> Color
whiteColor maybeAlfa =
    let
        r =
            255

        g =
            255

        b =
            255
    in
    getMaybeColor { r = r, g = g, b = b, a = maybeAlfa }


errorColor : Maybe Float -> Color
errorColor maybeAlfa =
    let
        r =
            230

        g =
            57

        b =
            70
    in
    getMaybeColor { r = r, g = g, b = b, a = maybeAlfa }


successColor : Maybe Float -> Color
successColor maybeAlfa =
    let
        r =
            0

        g =
            155

        b =
            0
    in
    getMaybeColor { r = r, g = g, b = b, a = maybeAlfa }


secondaryColor : Maybe Float -> Color
secondaryColor maybeAlfa =
    let
        r =
            69

        g =
            123

        b =
            157
    in
    getMaybeColor { r = r, g = g, b = b, a = maybeAlfa }


lightBody : Maybe Float -> Color
lightBody maybeAlfa =
    let
        r =
            241

        g =
            250

        b =
            238
    in
    getMaybeColor { r = r, g = g, b = b, a = maybeAlfa }


darkBody : Maybe Float -> Color
darkBody maybeAlfa =
    primaryColor maybeAlfa
