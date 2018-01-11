port module Trui exposing (..)

{-| ! EXPERIMENTAL ! a visual/hybrid user interface programming tool. See the `Conversation.elm` example for a gentle introduction to Arborist.
-}

import Task
import Json.Decode as Decode
import Json.Encode as Encode
import Regex
import Html exposing (Html, div, node, h1, h2, h3, p, a, text, program, label, textarea, map, button)
import Html.Attributes exposing (class, style, value, type_, href)
import Html.Events exposing (onInput, onClick)
import Svg exposing (svg, path)
import Svg.Attributes exposing (viewBox, d, stroke)
import Arborist
import Arborist.Tree as Tree
import Arborist.Settings as Settings
import Arborist.Context exposing (NodeState(..))
import Styles
import Window exposing (size, resizes)


{-| The Node data type held in each of the tree's nodes.
-}
type alias Node =
    { code : String
    }


{-| Program model.
-}
type alias Model =
    { arborist : Arborist.Model Node

    -- Keep track of a to-be-inserted node
    , newNode : Node
    , windowSize : Window.Size
    }


{-| The starting tree.
-}
tree : Tree.Tree Node
tree =
    Tree.Node { code = """<div>
  <Child1/>
</div>""" }
        [ Tree.Node { code = "<h1>Hello</h1>" }
            []
        , Tree.Node { code = "<p>World</p>" }
            [ Tree.Node { code = "<code>const a;</code>" } []
            ]
        ]


{-| Flatten
-}
flatten : Tree.Tree a -> List ( List Int, a )
flatten =
    flattenTail []


flattenTail : List Int -> Tree.Tree a -> List ( List Int, a )
flattenTail path tree =
    case tree of
        Tree.Empty ->
            []

        Tree.Node val children ->
            [ ( path, val ) ]
                ++ (List.indexedMap
                        (\index child ->
                            (flattenTail (path ++ [ index ]) child)
                        )
                        children
                        |> List.foldl (++) []
                   )


init : ( Model, Cmd Msg )
init =
    ( { arborist =
            Arborist.initWith
                [ Settings.centerOffset 0 -180
                , Settings.nodeHeight 45
                , Settings.level 100
                , Settings.nodeWidth 160
                , Settings.connectorStrokeAttributes
                    [ stroke "#E2E2E2"
                    ]
                ]
                tree
      , newNode = { code = "" }
      , windowSize = { width = 0, height = 0 }
      }
    , Task.perform Resize Window.size
    )


port code : Encode.Value -> Cmd msg


{-| Program message
-}
type Msg
    = ArboristMsg Arborist.Msg
    | EditNewNodeCode String
    | SetActive Node
    | DeleteActive
    | Resize Window.Size



-- Update


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        sourceCode =
            Arborist.tree model.arborist
                |> flatten
                |> List.map
                    (\( path, { code } ) ->
                        let
                            pathPrefix =
                                (List.map (\i -> toString (i + 1)) path |> String.join "")

                            prefixedCode =
                                Regex.replace (Regex.All)
                                    (Regex.regex "<Child")
                                    (\_ -> "<Child" ++ pathPrefix)
                                    code
                        in
                            "function Child" ++ pathPrefix ++ " (props) {\n return " ++ prefixedCode ++ "\n}"
                    )
                |> String.join "\n\n"
    in
        case msg of
            ArboristMsg arboristMsg ->
                ( { model | arborist = Arborist.update arboristMsg model.arborist }
                , code (Encode.object [ ( "sourcecode", Encode.string sourceCode ) ])
                )

            SetActive newNode ->
                ( { model | arborist = Arborist.setActiveNode newNode model.arborist }
                , Cmd.none
                )

            DeleteActive ->
                ( { model | arborist = Arborist.deleteActiveNode model.arborist }
                , Cmd.none
                )

            EditNewNodeCode val ->
                ( { model
                    | newNode = { code = val }
                  }
                , Cmd.none
                )

            Resize { width, height } ->
                ( { model
                    | arborist =
                        Arborist.resize (width // 2) height model.arborist
                    , windowSize =
                        { width = width
                        , height = height
                        }
                  }
                , Cmd.none
                )



-- View


view : Model -> Html Msg
view model =
    div [] <|
        [ node "style" [] [ text Styles.raw ]
        ]
            ++ [ -- For pop-up coordinates to work, include view in a container
                 div
                    [ style
                        [ ( "margin", "auto" )
                        , ( "position", "absolute" )
                        , ( "top", "0" )
                        , ( "left", "0" )
                        , ( "width", (toString (model.windowSize.width // 2)) ++ "px" )
                        , ( "height", (toString model.windowSize.height) ++ "px" )
                        ]
                    ]
                 <|
                    [ Arborist.view nodeView [ style Styles.box ] model.arborist |> Html.map ArboristMsg ]
                        ++ (Arborist.activeNodeWithContext model.arborist
                                |> Maybe.map
                                    (\( item, { position } ) ->
                                        let
                                            ( x, y ) =
                                                position
                                        in
                                            [ div
                                                [ style <|
                                                    Styles.popup
                                                        ++ [ ( "left", (toString x) ++ "px" )
                                                           , ( "top", (toString y) ++ "px" )
                                                           , ( "width", "60vw" )
                                                           , ( "height", "60vh" )
                                                           , ( "max-height", "600px" )
                                                           , ( "max-width", "600px" )
                                                           ]
                                                ]
                                                (case item of
                                                    Just item ->
                                                        [ textarea [ style textareaStyle, value item.code, onInput (\val -> SetActive { item | code = val }) ] []
                                                        , button [ style Styles.button, onClick DeleteActive ] [ text "Delete" ]
                                                        ]

                                                    Nothing ->
                                                        [ textarea [ style textareaStyle, value model.newNode.code, onInput EditNewNodeCode ] []
                                                        , button [ style Styles.button, type_ "submit", onClick (SetActive model.newNode) ] [ text "Add node" ]
                                                        ]
                                                )
                                            ]
                                    )
                                |> Maybe.withDefault []
                           )
               ]


textareaStyle : List ( String, String )
textareaStyle =
    [ ( "font-family", "monospace" )
    , ( "min-height", "300px" )
    , ( "font-size", "1.25rem" )
    ]


{-| Describe how a node should render inside the tree's layout.
-}
nodeView : Arborist.NodeView Node
nodeView context item =
    item
        |> Maybe.map
            (\item ->
                div
                    [ style <|
                        Styles.nodeContainer
                            ++ [ ( "background-color"
                                 , case context.state of
                                    Active ->
                                        Styles.green

                                    Hovered ->
                                        Styles.lightBlue

                                    DropTarget ->
                                        Styles.orange

                                    Normal ->
                                        Styles.blue
                                 )
                               , ( "color", "white" )
                               ]
                    ]
                    [ p [ style <| Styles.text ] [ text "Code" ]
                    ]
            )
        |> Maybe.withDefault
            (div
                [ style <|
                    Styles.nodeContainer
                        ++ (case context.state of
                                Active ->
                                    [ ( "background-color", Styles.green )
                                    , ( "color", "white" )
                                    , ( "border", "0" )
                                    ]

                                DropTarget ->
                                    [ ( "background-color", Styles.orange )
                                    , ( "border", "0" )
                                    , ( "color", "white" )
                                    ]

                                _ ->
                                    [ ( "background-color", "transparent" )
                                    , ( "border", "1px dashed #CECECE" )
                                    , ( "color", "#898989" )
                                    ]
                           )
                ]
                [ p [ style <| Styles.text ] [ text "New child" ] ]
            )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Arborist.subscriptions model.arborist |> Sub.map ArboristMsg
        , Window.resizes Resize
        ]


{-| Entry point
-}
main : Program Never Model Msg
main =
    program
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }
