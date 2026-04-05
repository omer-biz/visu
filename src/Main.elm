module Main exposing (main)

import Browser
import Dict exposing (Dict)
import File exposing (File)
import Html exposing (..)
import Html.Attributes exposing (accept, class, for, id, placeholder, type_)
import Html.Events exposing (on)
import Json.Decode as Decode
import Ports
import SvgAssets
import Task


type alias Model =
    { keyBinds : KeyBinds }


type KeyBinds
    = NotProvided
    | ErrorParsing ()
    | Parsing
    | Parsed (Dict String KeyInfo)


type alias KeyInfo =
    { modifiers : List KeyModifiers
    , action : String
    }


type KeyModifiers
    = Ctrl
    | Shift
    | Super


type Msg
    = GotParsed Decode.Value
    | FileSelected File
    | FileLoaded String


onFileChange : (File -> msg) -> Attribute msg
onFileChange tagger =
    on "change"
        (Decode.at [ "target", "files" ]
            (Decode.index 0 File.decoder)
            |> Decode.map tagger
        )


init : () -> ( Model, Cmd Msg )
init _ =
    ( { keyBinds = NotProvided }, Cmd.none )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotParsed _ ->
            ( model, Cmd.none )

        FileSelected file ->
            ( model
            , Task.perform FileLoaded (File.toString file)
            )

        FileLoaded contents ->
            ( { model | keyBinds = Parsing }
            , Ports.sendConfig contents
            )


view : Model -> Html Msg
view _ =
    main_ [ class "flex-1 grid grid-cols-1 lg:grid-cols-12 gap-0 overflow-hidden" ]
        [ viewUploadConfig
        , viewKeyBoard
        , viewKeyMapInfo
        , div [ class "fixed bottom-10 left-1/2 -translate-x-1/2 bg-zinc-800 border border-zinc-700 px-4 py-3 rounded-full shadow-2xl flex items-center gap-3 animate-bounce" ]
            [ div [ class "bg-green-500/20 text-green-500 p-1 rounded-full" ]
                [ SvgAssets.checkMark
                ]
            , span [ class "text-sm font-medium" ]
                [ text "Parsed 42 keybindings from config.kdl" ]
            ]
        ]


viewKeyBoard : Html msg
viewKeyBoard =
    section [ class "lg:col-span-6 bg-zinc-950 p-8 overflow-x-auto flex flex-col items-center justify-start" ]
        [ div [ class "w-full max-w-4xl" ]
            [ div [ class "flex justify-between items-center mb-8" ]
                [ div []
                    [ h2 [ class "text-xl font-semibold" ]
                        [ text "Workspace View" ]
                    , p [ class "text-zinc-500 text-sm" ]
                        [ text "42 active bindings detected" ]
                    ]
                , div [ class "flex bg-zinc-900 p-1 rounded-lg border border-zinc-800" ]
                    [ button [ class "px-4 py-1.5 text-xs font-medium bg-zinc-800 rounded-md shadow-sm" ]
                        [ text "Physical" ]
                    , button [ class "px-4 py-1.5 text-xs font-medium text-zinc-500 hover:text-zinc-300 transition-colors" ]
                        [ text "List View" ]
                    ]
                ]
            , div [ class "kb-grid p-4 bg-zinc-900 rounded-2xl border border-zinc-800 shadow-2xl" ]
                [ button [ class "col-span-4 h-12 rounded-lg bg-zinc-800 border border-zinc-700 flex flex-col items-center justify-center hover:bg-zinc-700 transition-all group relative" ]
                    [ span [ class "text-[10px] text-zinc-500 font-bold group-hover:text-zinc-300 uppercase" ]
                        [ text "Esc" ]
                    ]
                , button [ class "col-span-4 h-12 rounded-lg bg-zinc-800 border border-zinc-700 flex items-center justify-center hover:-translate-y-0.5 transition-all" ]
                    [ text "1" ]
                , button [ class "col-span-4 h-12 rounded-lg bg-zinc-800 border border-zinc-700 flex items-center justify-center hover:-translate-y-0.5 transition-all" ]
                    [ text "2" ]
                , button [ class "col-span-4 h-12 rounded-lg bg-violet-500/20 border border-violet-500/50 ring-2 ring-violet-500/20 flex flex-col items-center justify-center hover:-translate-y-0.5 transition-all relative" ]
                    [ span [ class "absolute top-1 left-1.5 text-[8px] font-bold text-violet-400" ]
                        [ text "SUP" ]
                    , span [ class "text-sm font-semibold" ]
                        [ text "3" ]
                    , span [ class "absolute bottom-1 right-1.5 bg-violet-500 text-white text-[8px] px-1 rounded-full" ]
                        [ text "2" ]
                    ]
                , button [ class "col-span-4 h-12 rounded-lg bg-zinc-800 border border-zinc-700 flex items-center justify-center hover:-translate-y-0.5 transition-all" ]
                    [ text "4" ]
                , button [ class "col-span-4 h-12 rounded-lg bg-zinc-800 border border-zinc-700 flex items-center justify-center hover:-translate-y-0.5 transition-all" ]
                    [ text "5" ]
                , button [ class "col-span-4 h-12 rounded-lg bg-zinc-800 border border-zinc-700 flex items-center justify-center hover:-translate-y-0.5 transition-all" ]
                    [ text "6" ]
                , button [ class "col-span-4 h-12 rounded-lg bg-zinc-800 border border-zinc-700 flex items-center justify-center hover:-translate-y-0.5 transition-all" ]
                    [ text "7" ]
                , button [ class "col-span-4 h-12 rounded-lg bg-zinc-800 border border-zinc-700 flex items-center justify-center hover:-translate-y-0.5 transition-all" ]
                    [ text "8" ]
                , button [ class "col-span-4 h-12 rounded-lg bg-zinc-800 border border-zinc-700 flex items-center justify-center hover:-translate-y-0.5 transition-all" ]
                    [ text "9" ]
                , button [ class "col-span-4 h-12 rounded-lg bg-zinc-800 border border-zinc-700 flex items-center justify-center hover:-translate-y-0.5 transition-all" ]
                    [ text "0" ]
                , button [ class "col-span-4 h-12 rounded-lg bg-zinc-800 border border-zinc-700 flex items-center justify-center hover:-translate-y-0.5 transition-all" ]
                    [ text "-" ]
                , button [ class "col-span-4 h-12 rounded-lg bg-zinc-800 border border-zinc-700 flex items-center justify-center hover:-translate-y-0.5 transition-all" ]
                    [ text "=" ]
                , button [ class "col-span-8 h-12 rounded-lg bg-zinc-800 border border-zinc-700 flex items-center justify-center hover:-translate-y-0.5 transition-all text-xs text-zinc-500 uppercase font-bold" ]
                    [ text "Backspace" ]
                , button [ class "col-span-6 h-12 rounded-lg bg-zinc-800 border border-zinc-700 flex items-center justify-center text-xs text-zinc-500 uppercase font-bold" ]
                    [ text "Tab" ]
                , button [ class "col-span-4 h-12 rounded-lg bg-zinc-800 border border-zinc-700 flex items-center justify-center font-semibold" ]
                    [ text "Q" ]
                , button [ class "col-span-4 h-12 rounded-lg bg-zinc-800 border border-zinc-700 flex items-center justify-center font-semibold" ]
                    [ text "W" ]
                , button [ class "col-span-4 h-12 rounded-lg bg-zinc-800 border border-zinc-700 flex items-center justify-center font-semibold" ]
                    [ text "E" ]
                , button [ class "col-span-4 h-12 rounded-lg bg-zinc-800 border border-zinc-700 flex items-center justify-center font-semibold" ]
                    [ text "R" ]
                , button [ class "col-span-4 h-12 rounded-lg bg-zinc-800 border border-zinc-700 flex items-center justify-center font-semibold" ]
                    [ text "T" ]
                , button [ class "col-span-4 h-12 rounded-lg bg-zinc-800 border border-zinc-700 flex items-center justify-center font-semibold" ]
                    [ text "Y" ]
                , button [ class "col-span-4 h-12 rounded-lg bg-zinc-800 border border-zinc-700 flex items-center justify-center font-semibold" ]
                    [ text "U" ]
                , button [ class "col-span-4 h-12 rounded-lg bg-zinc-800 border border-zinc-700 flex items-center justify-center font-semibold" ]
                    [ text "I" ]
                , button [ class "col-span-4 h-12 rounded-lg bg-zinc-800 border border-zinc-700 flex items-center justify-center font-semibold" ]
                    [ text "O" ]
                , button [ class "col-span-4 h-12 rounded-lg bg-zinc-800 border border-zinc-700 flex items-center justify-center font-semibold" ]
                    [ text "P" ]
                , button [ class "col-span-4 h-12 rounded-lg bg-zinc-800 border border-zinc-700 flex items-center justify-center font-semibold" ]
                    [ text "[" ]
                , button [ class "col-span-4 h-12 rounded-lg bg-zinc-800 border border-zinc-700 flex items-center justify-center font-semibold" ]
                    [ text "]" ]
                , button [ class "col-span-6 h-12 rounded-lg bg-zinc-800 border border-zinc-700 flex items-center justify-center font-semibold" ]
                    [ text "\\" ]
                , button [ class "col-span-7 h-12 rounded-lg bg-zinc-800 border border-zinc-700 flex items-center justify-center text-xs text-zinc-500 uppercase font-bold" ]
                    [ text "Caps" ]
                , button [ class "col-span-4 h-12 rounded-lg bg-zinc-800 border border-zinc-700 flex items-center justify-center font-semibold" ]
                    [ text "A" ]
                , button [ class "col-span-4 h-12 rounded-lg bg-zinc-800 border border-zinc-700 flex items-center justify-center font-semibold" ]
                    [ text "S" ]
                , button [ class "col-span-4 h-12 rounded-lg bg-zinc-800 border border-zinc-700 flex items-center justify-center font-semibold" ]
                    [ text "D" ]
                , button [ class "col-span-4 h-12 rounded-lg bg-zinc-800 border border-zinc-700 flex items-center justify-center font-semibold" ]
                    [ text "F" ]
                , button [ class "col-span-4 h-12 rounded-lg bg-zinc-800 border border-zinc-700 flex items-center justify-center font-semibold" ]
                    [ text "G" ]
                , button [ class "col-span-4 h-12 rounded-lg bg-violet-500/20 border border-violet-500 ring-4 ring-violet-500/30 flex flex-col items-center justify-center relative scale-105 z-10 shadow-2xl" ]
                    [ span [ class "absolute top-1 left-1.5 text-[8px] font-bold text-violet-400" ]
                        [ text "SUP" ]
                    , span [ class "text-sm font-semibold" ]
                        [ text "H" ]
                    , span [ class "absolute bottom-1 right-1.5 bg-violet-500 text-white text-[8px] px-1 rounded-full" ]
                        [ text "1" ]
                    ]
                , button [ class "col-span-4 h-12 rounded-lg bg-zinc-800 border border-zinc-700 flex items-center justify-center font-semibold" ]
                    [ text "J" ]
                , button [ class "col-span-4 h-12 rounded-lg bg-zinc-800 border border-zinc-700 flex items-center justify-center font-semibold" ]
                    [ text "K" ]
                , button [ class "col-span-4 h-12 rounded-lg bg-zinc-800 border border-zinc-700 flex items-center justify-center font-semibold" ]
                    [ text "L" ]
                , button [ class "col-span-4 h-12 rounded-lg bg-zinc-800 border border-zinc-700 flex items-center justify-center font-semibold" ]
                    [ text ";" ]
                , button [ class "col-span-4 h-12 rounded-lg bg-zinc-800 border border-zinc-700 flex items-center justify-center font-semibold" ]
                    [ text "'" ]
                , button [ class "col-span-9 h-12 rounded-lg bg-zinc-800 border border-zinc-700 flex items-center justify-center text-xs text-zinc-500 uppercase font-bold" ]
                    [ text "Enter" ]
                , button [ class "col-span-9 h-12 rounded-lg bg-zinc-800 border border-zinc-700 flex items-center justify-center text-xs text-zinc-500 uppercase font-bold" ]
                    [ text "Shift" ]
                , button [ class "col-span-4 h-12 rounded-lg bg-zinc-800 border border-zinc-700 flex items-center justify-center font-semibold" ]
                    [ text "Z" ]
                , button [ class "col-span-4 h-12 rounded-lg bg-zinc-800 border border-zinc-700 flex items-center justify-center font-semibold" ]
                    [ text "X" ]
                , button [ class "col-span-4 h-12 rounded-lg bg-zinc-800 border border-zinc-700 flex items-center justify-center font-semibold" ]
                    [ text "C" ]
                , button [ class "col-span-4 h-12 rounded-lg bg-zinc-800 border border-zinc-700 flex items-center justify-center font-semibold" ]
                    [ text "V" ]
                , button [ class "col-span-4 h-12 rounded-lg bg-zinc-800 border border-zinc-700 flex items-center justify-center font-semibold" ]
                    [ text "B" ]
                , button [ class "col-span-4 h-12 rounded-lg bg-zinc-800 border border-zinc-700 flex items-center justify-center font-semibold" ]
                    [ text "N" ]
                , button [ class "col-span-4 h-12 rounded-lg bg-zinc-800 border border-zinc-700 flex items-center justify-center font-semibold" ]
                    [ text "M" ]
                , button [ class "col-span-4 h-12 rounded-lg bg-zinc-800 border border-zinc-700 flex items-center justify-center font-semibold" ]
                    [ text "," ]
                , button [ class "col-span-4 h-12 rounded-lg bg-zinc-800 border border-zinc-700 flex items-center justify-center font-semibold" ]
                    [ text "." ]
                , button [ class "col-span-4 h-12 rounded-lg bg-zinc-800 border border-zinc-700 flex items-center justify-center font-semibold" ]
                    [ text "/" ]
                , button [ class "col-span-11 h-12 rounded-lg bg-zinc-800 border border-zinc-700 flex items-center justify-center text-xs text-zinc-500 uppercase font-bold" ]
                    [ text "Shift" ]
                , button [ class "col-span-6 h-12 rounded-lg bg-zinc-800 border border-zinc-700 flex items-center justify-center text-xs text-zinc-500 font-bold" ]
                    [ text "Ctrl" ]
                , button [ class "col-span-6 h-12 rounded-lg bg-zinc-800 border border-zinc-700 flex items-center justify-center text-xs text-zinc-500 font-bold" ]
                    [ text "Super" ]
                , button [ class "col-span-6 h-12 rounded-lg bg-zinc-800 border border-zinc-700 flex items-center justify-center text-xs text-zinc-500 font-bold" ]
                    [ text "Alt" ]
                , button [ class "col-span-24 h-12 rounded-lg bg-zinc-800 border border-zinc-700 flex items-center justify-center font-semibold" ]
                    []
                , button [ class "col-span-6 h-12 rounded-lg bg-zinc-800 border border-zinc-700 flex items-center justify-center text-xs text-zinc-500 font-bold" ]
                    [ text "Alt" ]
                , button [ class "col-span-6 h-12 rounded-lg bg-zinc-800 border border-zinc-700 flex items-center justify-center text-xs text-zinc-500 font-bold" ]
                    [ text "Super" ]
                , button [ class "col-span-6 h-12 rounded-lg bg-zinc-800 border border-zinc-700 flex items-center justify-center text-xs text-zinc-500 font-bold" ]
                    [ text "Ctrl" ]
                ]
            , div [ class "mt-12 flex flex-wrap gap-6 justify-center opacity-60" ]
                [ div [ class "flex items-center gap-2 text-xs" ]
                    [ div [ class "w-3 h-3 rounded-sm bg-violet-500" ]
                        []
                    , span []
                        [ text "Active Binding" ]
                    ]
                , div [ class "flex items-center gap-2 text-xs" ]
                    [ div [ class "w-3 h-3 rounded-sm bg-zinc-800 border border-zinc-700" ]
                        []
                    , span []
                        [ text "Unbound" ]
                    ]
                , div [ class "flex items-center gap-2 text-xs" ]
                    [ div [ class "w-3 h-3 rounded-sm border-2 border-violet-500 shadow-[0_0_8px_rgba(139,92,246,0.5)]" ]
                        []
                    , span []
                        [ text "Selected" ]
                    ]
                ]
            ]
        ]


viewUploadConfig : Html Msg
viewUploadConfig =
    aside [ class "lg:col-span-3 border-r border-zinc-800 bg-zinc-900/50 p-6 flex flex-col gap-6 overflow-y-auto" ]
        [ section []
            [ label [ class "text-xs font-bold uppercase tracking-widest text-zinc-500 mb-3 block" ]
                [ text "Config Source" ]
            , div [ class "relative" ]
                [ input
                    [ type_ "file"
                    , accept ".kdl"
                    , class "absolute inset-0 w-full h-full opacity-0 cursor-pointer"
                    , onFileChange FileSelected
                    ]
                    []
                , div
                    [ class "border-2 border-dashed border-zinc-700 rounded-xl p-8 text-center hover:border-violet-500/50 transition-colors cursor-pointer bg-zinc-800/30" ]
                    [ SvgAssets.logo
                    , p [ class "text-sm text-zinc-400" ]
                        [ text "Drop your "
                        , code [ class "text-zinc-200" ]
                            [ text "config.kdl " ]
                        , text "here or click to upload"
                        ]
                    ]
                ]
            ]
        , hr [ class "border-zinc-800" ]
            []
        , section [ class "space-y-4" ]
            [ label [ class "text-xs font-bold uppercase tracking-widest text-zinc-500 block" ]
                [ text "Preferences" ]
            , div [ class "flex items-center justify-between p-3 bg-zinc-800/50 rounded-lg border border-zinc-700/50" ]
                [ span [ class "text-sm" ]
                    [ text "Keyboard Layout" ]
                , select [ class "bg-transparent text-sm font-medium focus:outline-none" ]
                    [ option []
                        [ text "ANSI" ]
                    , option []
                        [ text "ISO" ]
                    ]
                ]
            , div [ class "space-y-2" ]
                [ div [ class "flex justify-between text-xs text-zinc-500 px-1" ]
                    [ span []
                        [ text "Key Size" ]
                    , span []
                        [ text "Medium" ]
                    ]
                , input [ class "w-full accent-violet-500", type_ "range" ]
                    []
                ]
            , div [ class "flex items-center gap-3" ]
                [ input [ class "w-4 h-4 rounded border-zinc-700 bg-zinc-800 text-violet-600 focus:ring-violet-500", id "unbound", type_ "checkbox" ]
                    []
                , label [ class "text-sm text-zinc-300", for "unbound" ]
                    [ text "Show unbound keys" ]
                ]
            ]
        ]


viewKeyMapInfo : Html msg
viewKeyMapInfo =
    aside [ class "lg:col-span-3 border-l border-zinc-800 bg-zinc-900/50 p-6 overflow-y-auto" ]
        [ div [ class "flex items-end justify-between mb-8" ]
            [ div []
                [ h3 [ class "text-4xl font-black text-white" ]
                    [ text "H" ]
                , p [ class "text-zinc-500 text-sm font-medium" ]
                    [ text "1 Binding Found" ]
                ]
            , button [ class "text-zinc-500 hover:text-white mb-1" ]
                [ SvgAssets.clipboard
                ]
            ]
        , div [ class "space-y-4" ]
            [ div [ class "bg-zinc-800/80 border border-zinc-700 p-4 rounded-xl space-y-3 group hover:border-violet-500/50 transition-colors" ]
                [ div [ class "flex items-center gap-1.5 flex-wrap" ]
                    [ span [ class "px-1.5 py-0.5 bg-zinc-700 text-zinc-300 rounded text-[10px] font-bold mono" ]
                        [ text "Super" ]
                    , span [ class "text-zinc-500 text-xs" ]
                        [ text "+" ]
                    , span [ class "px-1.5 py-0.5 bg-zinc-700 text-zinc-300 rounded text-[10px] font-bold mono" ]
                        [ text "Shift" ]
                    , span [ class "text-zinc-500 text-xs" ]
                        [ text "+" ]
                    , span [ class "px-1.5 py-0.5 bg-violet-500/20 text-violet-300 border border-violet-500/30 rounded text-[10px] font-bold mono" ]
                        [ text "H" ]
                    ]
                , div [ class "flex flex-col" ]
                    [ span [ class "text-xs text-zinc-500 font-semibold uppercase tracking-wider mb-1" ]
                        [ text "Action" ]
                    , span [ class "mono text-sm text-violet-400" ]
                        [ text "focus-column-left" ]
                    ]
                , div [ class "pt-2 flex justify-between items-center border-t border-zinc-700/50" ]
                    [ span [ class "text-[10px] text-zinc-500 italic" ]
                        [ text "Default Layer" ]
                    , button [ class "opacity-0 group-hover:opacity-100 transition-opacity text-xs text-violet-500 font-medium" ]
                        [ text "Edit Bind" ]
                    ]
                ]
            , div [ class "p-8 text-center border border-dashed border-zinc-800 rounded-xl opacity-40" ]
                [ p [ class "text-xs" ]
                    [ text "No other bindings for this key." ]
                ]
            ]
        , div [ class "mt-12 bg-zinc-800/30 border border-zinc-800 rounded-xl p-4" ]
            [ h4 [ class "text-xs font-bold text-zinc-400 mb-4 uppercase tracking-widest" ]
                [ text "Global Filter" ]
            , div [ class "relative" ]
                [ input [ class "w-full bg-zinc-950 border border-zinc-700 rounded-lg py-2 pl-9 pr-4 text-xs focus:ring-1 focus:ring-violet-500 focus:outline-none focus:border-violet-500", placeholder "Search actions (e.g. 'spawn')", type_ "text" ]
                    []
                , SvgAssets.search
                ]
            ]
        ]


subscriptions : Model -> Sub Msg
subscriptions _ =
    Ports.receiveParsed GotParsed


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
