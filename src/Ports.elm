port module Ports exposing (receiveParsed, sendConfig)

import Json.Decode as Decode


port sendConfig : String -> Cmd msg


port receiveParsed : (Decode.Value -> msg) -> Sub msg
