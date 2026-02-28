module SvgAssets exposing (..)

import Html exposing (Html)
import Html.Attributes exposing (attribute)
import Svg exposing (..)
import Svg.Attributes exposing (..)


logo : Html msg
logo =
    svg [ class "mx-auto mb-3 text-zinc-500", fill "none", attribute "height" "24", attribute "stroke" "currentColor", attribute "stroke-linecap" "round", attribute "stroke-linejoin" "round", attribute "stroke-width" "2", viewBox "0 0 24 24", attribute "width" "24", attribute "xmlns" "http://www.w3.org/2000/svg" ]
        [ Svg.path [ d "M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" ]
            []
        , node "polyline"
            [ attribute "points" "17 8 12 3 7 8" ]
            []
        , node "line"
            [ attribute "x1" "12", attribute "x2" "12", attribute "y1" "3", attribute "y2" "15" ]
            []
        ]


clipboard : Html msg
clipboard =
    svg [ fill "none", attribute "height" "18", attribute "stroke" "currentColor", attribute "stroke-linecap" "round", attribute "stroke-linejoin" "round", attribute "stroke-width" "2", viewBox "0 0 24 24", attribute "width" "18", attribute "xmlns" "http://www.w3.org/2000/svg" ]
        [ node "rect"
            [ attribute "height" "14", attribute "rx" "2", attribute "ry" "2", attribute "width" "14", attribute "x" "8", attribute "y" "8" ]
            []
        , Svg.path [ d "M4 16c-1.1 0-2-.9-2-2V4c0-1.1.9-2 2-2h10c1.1 0 2 .9 2 2" ]
            []
        ]


search : Html msg
search =
    svg [ class "absolute left-3 top-2.5 text-zinc-600", fill "none", attribute "height" "14", attribute "stroke" "currentColor", attribute "stroke-linecap" "round", attribute "stroke-linejoin" "round", attribute "stroke-width" "2", viewBox "0 0 24 24", attribute "width" "14", attribute "xmlns" "http://www.w3.org/2000/svg" ]
        [ node "circle"
            [ attribute "cx" "11", attribute "cy" "11", attribute "r" "8" ]
            []
        , Svg.path [ d "m21 21-4.3-4.3" ]
            []
        ]


checkMark : Html msg
checkMark =
    svg [ fill "none", attribute "height" "14", attribute "stroke" "currentColor", attribute "stroke-linecap" "round", attribute "stroke-linejoin" "round", attribute "stroke-width" "3", viewBox "0 0 24 24", attribute "width" "14", attribute "xmlns" "http://www.w3.org/2000/svg" ]
        [ node "polyline"
            [ attribute "points" "20 6 9 17 4 12" ]
            []
        ]
