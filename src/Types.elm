module Types exposing (Flags, Model, Msg(..))

import Browser exposing (UrlRequest)
import Url exposing (Url)


type alias Flags =
    ()


type alias Model =
    ()


type Msg
    = ChangeUrl Url
    | ClickLink UrlRequest
