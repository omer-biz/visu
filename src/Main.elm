module Main exposing (main)

import Browser
import Dict exposing (Dict)
import File exposing (File)
import Html exposing (..)
import Html.Attributes exposing (accept, class, placeholder, type_)
import Html.Events exposing (on)
import Json.Decode as Decode
import Ports
import SvgAssets
import Task


type alias Model =
    { keyBinds : KeyBinds
    , selectedKey : Maybe String
    , viewMode : ViewMode
    , searchQuery : String
    }


type ViewMode
    = Physical
    | ListView


type KeyBinds
    = NotProvided
    | ErrorParsing String
    | Parsing
    | Parsed (Dict String (List Binding))


type alias Binding =
    { key : String
    , modifiers : List KeyModifier
    , actions : List String
    , options : Dict String String
    }


type KeyModifier
    = Ctrl
    | Shift
    | Super
    | Alt
    | Mod
    | Mod3
    | Win
    | Control
    | Other String


type Msg
    = GotParsed Decode.Value
    | FileSelected File
    | FileLoaded String
    | KeySelected String
    | ChangeViewMode ViewMode
    | UpdateSearchQuery String


onFileChange : (File -> msg) -> Attribute msg
onFileChange tagger =
    on "change"
        (Decode.at [ "target", "files" ]
            (Decode.index 0 File.decoder)
            |> Decode.map tagger
        )


init : () -> ( Model, Cmd Msg )
init _ =
    ( { keyBinds = NotProvided, selectedKey = Nothing, viewMode = Physical, searchQuery = "" }, Cmd.none )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotParsed value ->
            case Decode.decodeValue responseDecoder value of
                Ok (Success bindings) ->
                    let
                        grouped =
                            List.foldl
                                (\b acc ->
                                    Dict.update b.key
                                        (\maybeList ->
                                            case maybeList of
                                                Just list ->
                                                    Just (list ++ [ b ])

                                                Nothing ->
                                                    Just [ b ]
                                        )
                                        acc
                                )
                                Dict.empty
                                bindings
                    in
                    ( { model | keyBinds = Parsed grouped }, Cmd.none )

                Ok (Error err) ->
                    ( { model | keyBinds = ErrorParsing err }, Cmd.none )

                Err err ->
                    ( { model | keyBinds = ErrorParsing <| Decode.errorToString err }, Cmd.none )

        FileSelected file ->
            ( model
            , Task.perform FileLoaded (File.toString file)
            )

        FileLoaded contents ->
            ( { model | keyBinds = Parsing }
            , Ports.sendConfig contents
            )

        KeySelected keyId ->
            ( { model | selectedKey = Just keyId }, Cmd.none )

        ChangeViewMode mode ->
            ( { model | viewMode = mode }, Cmd.none )

        UpdateSearchQuery query ->
            ( { model | searchQuery = query }, Cmd.none )


type Response
    = Success (List Binding)
    | Error String


responseDecoder : Decode.Decoder Response
responseDecoder =
    Decode.field "type" Decode.string
        |> Decode.andThen
            (\t ->
                case t of
                    "SUCCESS" ->
                        Decode.field "data" (Decode.list bindingDecoder)
                            |> Decode.map Success

                    "ERROR" ->
                        Decode.field "error" Decode.string
                            |> Decode.map Error

                    _ ->
                        Decode.fail ("Unknown response type: " ++ t)
            )


bindingDecoder : Decode.Decoder Binding
bindingDecoder =
    Decode.map4 Binding
        (Decode.field "key" Decode.string)
        (Decode.field "modifiers" (Decode.list modifierDecoder))
        (Decode.field "actions" (Decode.list Decode.string))
        (Decode.field "options" (Decode.list optionDecoder |> Decode.map Dict.fromList))


optionDecoder : Decode.Decoder ( String, String )
optionDecoder =
    Decode.map2 (\k v -> ( k, v ))
        (Decode.index 0 Decode.string)
        (Decode.index 1 Decode.string)


modifierDecoder : Decode.Decoder KeyModifier
modifierDecoder =
    Decode.string
        |> Decode.map
            (\s ->
                case String.toLower s of
                    "ctrl" ->
                        Ctrl

                    "control" ->
                        Control

                    "shift" ->
                        Shift

                    "super" ->
                        Super

                    "alt" ->
                        Alt

                    "mod" ->
                        Mod

                    "win" ->
                        Win

                    "mod3" ->
                        Mod3

                    _ ->
                        Other s
            )


view : Model -> Html Msg
view model =
    main_ [ class "flex-1 grid grid-cols-1 lg:grid-cols-12 gap-0 overflow-hidden" ]
        [ viewUploadConfig model
        , viewKeyBoard model
        , viewKeyMapInfo model
        , case model.keyBinds of
            Parsing ->
                div [ class "fixed bottom-10 left-1/2 -translate-x-1/2 bg-zinc-800 border border-zinc-700 px-4 py-3 rounded-full shadow-2xl flex items-center gap-3 animate-pulse z-50" ]
                    [ div [ class "bg-blue-500/20 text-blue-500 p-1 rounded-full" ]
                        [ SvgAssets.spinner ]
                    , span [ class "text-sm font-medium text-zinc-200" ]
                        [ text "Parsing formatting configuration..." ]
                    ]

            ErrorParsing err ->
                div [ class "fixed bottom-10 left-1/2 -translate-x-1/2 bg-zinc-800/90 backdrop-blur-md border border-red-700/50 p-4 rounded-2xl shadow-2xl flex flex-col gap-3 max-w-xl w-full z-50" ]
                    [ div [ class "flex items-center gap-3 text-red-500 font-bold" ]
                        [ SvgAssets.alert
                        , text "Error Parsing Config"
                        ]
                    , div [ class "text-xs text-red-400 overflow-y-auto max-h-48 bg-red-500/10 p-3 rounded-lg w-full font-mono whitespace-pre-wrap leading-relaxed shadow-inner" ]
                        [ text err ]
                    ]

            Parsed dict ->
                if Dict.size dict > 0 then
                    div [ class "fixed bottom-10 left-1/2 -translate-x-1/2 bg-zinc-800 border border-zinc-700 px-4 py-3 rounded-full shadow-2xl flex items-center gap-3 animate-bounce z-50" ]
                        [ div [ class "bg-green-500/20 text-green-500 p-1 rounded-full" ]
                            [ SvgAssets.checkMark ]
                        , span [ class "text-sm font-medium" ]
                            [ text ("Parsed " ++ String.fromInt (Dict.size dict) ++ " keybindings from config") ]
                        ]
                else
                    text ""

            NotProvided ->
                text ""
        ]


viewKeyBoard : Model -> Html Msg
viewKeyBoard model =
    let
        activeBindingsCount =
            case model.keyBinds of
                Parsed dict ->
                    Dict.size dict

                _ ->
                    0
    in
    section [ class "lg:col-span-6 bg-zinc-950 p-8 overflow-x-auto flex flex-col items-center justify-start" ]
        [ div [ class "w-full max-w-4xl" ]
            [ div [ class "flex justify-between items-center mb-8" ]
                [ div []
                    [ h2 [ class "text-xl font-semibold" ]
                        [ text "Workspace View" ]
                    , p [ class "text-zinc-500 text-sm" ]
                        [ text (String.fromInt activeBindingsCount ++ " active bindings detected") ]
                    ]
                , div [ class "flex bg-zinc-900 p-1 rounded-lg border border-zinc-800" ]
                    [ button
                        [ class
                            (if model.viewMode == Physical then
                                "px-4 py-1.5 text-xs font-medium bg-zinc-800 rounded-md shadow-sm"

                             else
                                "px-4 py-1.5 text-xs font-medium text-zinc-500 hover:text-zinc-300 transition-colors"
                            )
                        , Html.Events.onClick (ChangeViewMode Physical)
                        ]
                        [ text "Physical" ]
                    , button
                        [ class
                            (if model.viewMode == ListView then
                                "px-4 py-1.5 text-xs font-medium bg-zinc-800 rounded-md shadow-sm"

                             else
                                "px-4 py-1.5 text-xs font-medium text-zinc-500 hover:text-zinc-300 transition-colors"
                            )
                        , Html.Events.onClick (ChangeViewMode ListView)
                        ]
                        [ text "List View" ]
                    ]
                ]
            , if model.viewMode == Physical then
                div [ class "kb-grid p-4 bg-zinc-900 rounded-2xl border border-zinc-800 shadow-2xl" ]
                    (List.map (viewKey model) keyboardLayout)

              else
                viewList model
            , if model.viewMode == Physical then
                viewLegend

              else
                text ""
            ]
        ]


viewList : Model -> Html Msg
viewList model =
    case model.keyBinds of
        Parsed dict ->
            let
                allBindings =
                    Dict.values dict
                        |> List.concat
                        |> List.filter (matchesSearch model.searchQuery)

                activeBindingsCount =
                    List.length allBindings
            in
            if activeBindingsCount == 0 then
                div [ class "w-full p-12 text-center border border-dashed border-zinc-800 rounded-2xl opacity-50 bg-zinc-900" ]
                    [ p [ class "text-zinc-400 text-sm font-medium" ] [ text "No bindings available." ] ]

            else
                div [ class "w-full grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4 max-h-[600px] overflow-y-auto p-4 bg-zinc-900 rounded-2xl border border-zinc-800 shadow-2xl custom-scrollbar" ]
                    (List.map
                        (\binding ->
                            div [ Html.Events.onClick (KeySelected binding.key), class "cursor-pointer transition-transform hover:-translate-y-0.5" ]
                                [ viewBindingDetail binding ]
                        )
                        allBindings
                    )

        Parsing ->
            div [ class "w-full p-12 text-center border border-dashed border-blue-800/50 rounded-2xl bg-blue-900/10 flex flex-col items-center justify-center gap-4" ]
                [ div [ class "text-blue-500" ] [ SvgAssets.spinner ]
                , p [ class "text-blue-400 text-sm font-medium animate-pulse" ] [ text "Parsing config..." ] 
                ]

        ErrorParsing _ ->
            div [ class "w-full p-12 text-center border border-dashed border-red-800/50 rounded-2xl bg-red-900/10 flex flex-col items-center justify-center gap-4" ]
                [ div [ class "text-red-500" ] [ SvgAssets.alert ]
                , p [ class "text-red-400 text-sm font-medium" ] [ text "Could not parse config. Please check the error below." ] 
                ]

        NotProvided ->
            div [ class "w-full p-12 text-center border border-dashed border-zinc-800 rounded-2xl opacity-50 bg-zinc-900" ]
                [ p [ class "text-zinc-400 text-sm font-medium" ] [ text "Upload a config to see bindings." ] ]


type alias KeyDef =
    { id : String
    , label : String
    , span : Int
    }


keyboardLayout : List KeyDef
keyboardLayout =
    [ -- Row 1
      { id = "escape", label = "Esc", span = 4 }
    , { id = "1", label = "1", span = 4 }
    , { id = "2", label = "2", span = 4 }
    , { id = "3", label = "3", span = 4 }
    , { id = "4", label = "4", span = 4 }
    , { id = "5", label = "5", span = 4 }
    , { id = "6", label = "6", span = 4 }
    , { id = "7", label = "7", span = 4 }
    , { id = "8", label = "8", span = 4 }
    , { id = "9", label = "9", span = 4 }
    , { id = "0", label = "0", span = 4 }
    , { id = "minus", label = "-", span = 4 }
    , { id = "equal", label = "=", span = 4 }
    , { id = "backspace", label = "Backspace", span = 8 }

    -- Row 2
    , { id = "tab", label = "Tab", span = 6 }
    , { id = "q", label = "Q", span = 4 }
    , { id = "w", label = "W", span = 4 }
    , { id = "e", label = "E", span = 4 }
    , { id = "r", label = "R", span = 4 }
    , { id = "t", label = "T", span = 4 }
    , { id = "y", label = "Y", span = 4 }
    , { id = "u", label = "U", span = 4 }
    , { id = "i", label = "I", span = 4 }
    , { id = "o", label = "O", span = 4 }
    , { id = "p", label = "P", span = 4 }
    , { id = "bracketleft", label = "[", span = 4 }
    , { id = "bracketright", label = "]", span = 4 }
    , { id = "backslash", label = "\\", span = 6 }

    -- Row 3
    , { id = "capslock", label = "Caps", span = 7 }
    , { id = "a", label = "A", span = 4 }
    , { id = "s", label = "S", span = 4 }
    , { id = "d", label = "D", span = 4 }
    , { id = "f", label = "F", span = 4 }
    , { id = "g", label = "G", span = 4 }
    , { id = "h", label = "H", span = 4 }
    , { id = "j", label = "J", span = 4 }
    , { id = "k", label = "K", span = 4 }
    , { id = "l", label = "L", span = 4 }
    , { id = "semicolon", label = ";", span = 4 }
    , { id = "quote", label = "'", span = 4 }
    , { id = "return", label = "Enter", span = 9 }

    -- Row 4
    , { id = "shiftleft", label = "Shift", span = 9 }
    , { id = "z", label = "Z", span = 4 }
    , { id = "x", label = "X", span = 4 }
    , { id = "c", label = "C", span = 4 }
    , { id = "v", label = "V", span = 4 }
    , { id = "b", label = "B", span = 4 }
    , { id = "n", label = "N", span = 4 }
    , { id = "m", label = "M", span = 4 }
    , { id = "comma", label = ",", span = 4 }
    , { id = "period", label = ".", span = 4 }
    , { id = "slash", label = "/", span = 4 }
    , { id = "up", label = "↑", span = 4 }
    , { id = "shiftright", label = "Shift", span = 7 }

    -- Row 5
    , { id = "ctrlleft", label = "Ctrl", span = 6 }
    , { id = "superleft", label = "Super", span = 6 }
    , { id = "altleft", label = "Alt", span = 6 }
    , { id = "space", label = "", span = 24 }
    , { id = "altright", label = "Alt", span = 6 }
    , { id = "left", label = "←", span = 4 }
    , { id = "down", label = "↓", span = 4 }
    , { id = "right", label = "→", span = 4 }
    ]


viewKey : Model -> KeyDef -> Html Msg
viewKey model keyDef =
    let
        bindings =
            case model.keyBinds of
                Parsed dict ->
                    Dict.get keyDef.id dict
                        |> Maybe.withDefault []
                        |> List.filter (matchesSearch model.searchQuery)

                _ ->
                    []

        isBound =
            not (List.isEmpty bindings)

        isSelected =
            model.selectedKey == Just keyDef.id

        baseClasses =
            getSpanClass keyDef.span ++ " h-12 rounded-lg border transition-all flex flex-col items-center justify-center relative "

        stateClasses =
            if isSelected then
                "bg-violet-500/30 border-violet-500 ring-4 ring-violet-500/30 z-10 scale-105 shadow-2xl"

            else if isBound then
                "bg-violet-500/20 border-violet-500/50 hover:bg-violet-500/30 hover:-translate-y-0.5"

            else
                "bg-zinc-800 border-zinc-700 hover:bg-zinc-700 hover:-translate-y-0.5"

        mainModifier =
            bindings
                |> List.head
                |> Maybe.andThen (\b -> List.head b.modifiers)
                |> Maybe.map modifierToString
                |> Maybe.withDefault ""
    in
    button
        [ class (baseClasses ++ stateClasses)
        , Html.Events.onClick (KeySelected keyDef.id)
        ]
        [ if isBound && mainModifier /= "" then
            span [ class "absolute top-1 left-1.5 text-[8px] font-bold text-violet-400" ]
                [ text mainModifier ]

          else
            text ""
        , span [ class "text-sm font-semibold" ]
            [ text keyDef.label ]
        , if List.length bindings > 1 then
            span [ class "absolute bottom-1 right-1.5 bg-violet-500 text-white text-[8px] px-1 rounded-full" ]
                [ text (String.fromInt (List.length bindings)) ]

          else
            text ""
        ]


getSpanClass : Int -> String
getSpanClass span =
    case span of
        4 ->
            "col-span-4"

        6 ->
            "col-span-6"

        7 ->
            "col-span-7"

        8 ->
            "col-span-8"

        9 ->
            "col-span-9"

        11 ->
            "col-span-11"

        24 ->
            "col-span-24"

        _ ->
            "col-span-" ++ String.fromInt span


matchesSearch : String -> Binding -> Bool
matchesSearch query binding =
    if String.isEmpty query then
        True

    else
        let
            q =
                String.toLower query

            matchesAction =
                List.any (\action -> String.contains q (String.toLower action)) binding.actions

            matchesKey =
                String.contains q (String.toLower binding.key)
        in
        matchesAction || matchesKey


modifierToString : KeyModifier -> String
modifierToString mod =
    case mod of
        Ctrl ->
            "CTRL"

        Shift ->
            "SHFT"

        Super ->
            "SUP"

        Alt ->
            "ALT"

        Mod ->
            "MOD"

        Win ->
            "WIN"

        Control ->
            "CTRL"

        Mod3 ->
            "Mod3"

        Other s ->
            String.toUpper s


viewLegend : Html msg
viewLegend =
    div [ class "mt-12 flex flex-wrap gap-6 justify-center opacity-60" ]
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


viewUploadConfig : Model -> Html Msg
viewUploadConfig model =
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
                    , Html.Attributes.value ""
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
        , div [ class "mt-12 bg-zinc-800/30 border border-zinc-800 rounded-xl p-4" ]
            [ h4 [ class "text-xs font-bold text-zinc-400 mb-4 uppercase tracking-widest" ]
                [ text "Global Filter" ]
            , div [ class "relative" ]
                [ input
                    [ class "w-full bg-zinc-950 border border-zinc-700 rounded-lg py-2 pl-9 pr-4 text-xs focus:ring-1 focus:ring-violet-500 focus:outline-none focus:border-violet-500"
                    , placeholder "Search actions (e.g. 'spawn')"
                    , type_ "text"
                    , Html.Attributes.value model.searchQuery
                    , Html.Events.onInput UpdateSearchQuery
                    ]
                    []
                , SvgAssets.search
                ]
            ]
        ]


viewKeyMapInfo : Model -> Html msg
viewKeyMapInfo model =
    let
        selectedId =
            model.selectedKey |> Maybe.withDefault ""

        bindings =
            case model.keyBinds of
                Parsed dict ->
                    Dict.get selectedId dict
                        |> Maybe.withDefault []
                        |> List.filter (matchesSearch model.searchQuery)

                _ ->
                    []

        bindingCount =
            List.length bindings
    in
    aside [ class "lg:col-span-3 border-l border-zinc-800 bg-zinc-900/50 p-6 overflow-y-auto" ]
        [ div [ class "flex items-end justify-between mb-8" ]
            [ div []
                [ h3 [ class "text-4xl font-black text-white uppercase" ]
                    [ text
                        (if selectedId == "" then
                            "-"

                         else
                            selectedId
                        )
                    ]
                , p [ class "text-zinc-500 text-sm font-medium" ]
                    [ text
                        (String.fromInt bindingCount
                            ++ " Binding"
                            ++ (if bindingCount == 1 then
                                    ""

                                else
                                    "s"
                               )
                            ++ " Found"
                        )
                    ]
                ]
            , button [ class "text-zinc-500 hover:text-white mb-1" ]
                [ SvgAssets.clipboard
                ]
            ]
        , div [ class "space-y-4" ]
            (if List.isEmpty bindings then
                [ div [ class "p-8 text-center border border-dashed border-zinc-800 rounded-xl opacity-40" ]
                    [ p [ class "text-xs" ]
                        [ text "No bindings for this key." ]
                    ]
                ]

             else
                List.map viewBindingDetail bindings
            )
        ]


viewBindingDetail : Binding -> Html msg
viewBindingDetail binding =
    div [ class "bg-zinc-800/80 border border-zinc-700 p-4 rounded-xl space-y-3 group hover:border-violet-500/50 transition-colors" ]
        [ div [ class "flex items-center gap-1.5 flex-wrap" ]
            (List.intersperse (span [ class "text-zinc-500 text-xs" ] [ text "+" ])
                (List.map viewModifierBadge binding.modifiers
                    ++ [ span [ class "px-1.5 py-0.5 bg-violet-500/20 text-violet-300 border border-violet-500/30 rounded text-[10px] font-bold mono uppercase" ]
                            [ text binding.key ]
                       ]
                )
            )
        , div [ class "flex flex-col" ]
            [ span [ class "text-xs text-zinc-500 font-semibold uppercase tracking-wider mb-1" ]
                [ text "Actions" ]
            , div [ class "space-y-1" ]
                (List.map (\action -> span [ class "mono text-sm text-violet-400 block" ] [ text action ]) binding.actions)
            ]
        , if not (Dict.isEmpty binding.options) then
            div [ class "flex flex-col pt-2 border-t border-zinc-700/50" ]
                [ span [ class "text-[10px] text-zinc-500 font-semibold uppercase tracking-wider mb-1" ]
                    [ text "Options" ]
                , div [ class "space-y-1" ]
                    (binding.options
                        |> Dict.toList
                        |> List.map (\( k, v ) -> div [ class "text-[10px] text-zinc-400 flex justify-between" ] [ span [] [ text k ], span [ class "italic text-zinc-500" ] [ text v ] ])
                    )
                ]

          else
            text ""
        ]


viewModifierBadge : KeyModifier -> Html msg
viewModifierBadge mod =
    span [ class "px-1.5 py-0.5 bg-zinc-700 text-zinc-300 rounded text-[10px] font-bold mono uppercase" ]
        [ text (modifierToString mod) ]


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
