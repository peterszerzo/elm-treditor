module Internals.Settings exposing
    ( Setting(..)
    , Settings
    , ShowPlaceholderLeavesAdvanced
    , apply
    , defaults
    , showPlaceholderLeavesAdvanced
    )


type alias ShowPlaceholderLeavesAdvanced node =
    { node : node
    , parent : Maybe node
    , children : List node
    , siblings : List node
    }
    -> Bool


type alias ExtendConnectorsByAdvanced node =
    { node : Maybe node
    , parent : Maybe node
    , children : List node
    , siblings : List node
    }
    -> Maybe Int


type alias IsNodeClustered node =
    node -> Bool


type alias Settings node =
    { canvasWidth : Float
    , canvasHeight : Float
    , nodeWidth : Float
    , nodeHeight : Float
    , level : Float
    , gutter : Float
    , centerOffset : ( Float, Float )
    , extendConnectorsBy : Maybe Float
    , extendConnectorsByAdvanced : Maybe (ExtendConnectorsByAdvanced node)
    , connectorStroke : String
    , connectorStrokeWidth : String
    , dragAndDrop : Bool
    , keyboardNavigation : Maybe { outsideId : Maybe String }
    , showPlaceholderLeaves : Bool
    , showPlaceholderLeavesAdvanced : Maybe (ShowPlaceholderLeavesAdvanced node)
    , defaultNode : Maybe node
    , isNodeClustered : IsNodeClustered node
    , checksum : Maybe String
    }


defaults : Settings node
defaults =
    { nodeWidth = 120
    , nodeHeight = 36
    , canvasWidth = 600
    , canvasHeight = 480
    , level = 80
    , gutter = 20
    , centerOffset = ( 0, 0 )
    , extendConnectorsBy = Nothing
    , extendConnectorsByAdvanced = Nothing
    , connectorStroke = "#E2E2E2"
    , connectorStrokeWidth = "2"
    , dragAndDrop = True
    , keyboardNavigation = Nothing
    , showPlaceholderLeaves = True
    , showPlaceholderLeavesAdvanced = Nothing
    , defaultNode = Nothing
    , isNodeClustered = \_ -> False
    , checksum = Nothing
    }


type Setting node
    = NodeWidth Int
    | NodeHeight Int
    | CanvasWidth Int
    | CanvasHeight Int
    | Level Int
    | Gutter Int
    | CenterOffset Int Int
    | ConnectorStroke String
    | ConnectorStrokeWidth String
    | ExtendConnectorsBy Int
    | ExtendConnectorsByAdvanced (ExtendConnectorsByAdvanced node)
    | DragAndDrop Bool
    | KeyboardNavigation Bool
    | KeyboardNavigationOutside String Bool
    | ShowPlaceholderLeaves Bool
    | ShowPlaceholderLeavesAdvanced (ShowPlaceholderLeavesAdvanced node)
    | DefaultNode node
    | Checksum String
    | IsNodeClustered (node -> Bool)


showPlaceholderLeavesAdvanced : Settings node -> ShowPlaceholderLeavesAdvanced node
showPlaceholderLeavesAdvanced settings =
    settings.showPlaceholderLeavesAdvanced
        |> Maybe.withDefault (\_ -> settings.showPlaceholderLeaves)


apply : List (Setting node) -> Settings node -> Settings node
apply newSettings settings =
    case newSettings of
        [] ->
            settings

        head :: tail ->
            apply tail
                (case head of
                    NodeWidth w ->
                        { settings | nodeWidth = toFloat w }

                    NodeHeight h ->
                        { settings | nodeHeight = toFloat h }

                    CanvasWidth w ->
                        { settings | canvasWidth = toFloat w }

                    CanvasHeight h ->
                        { settings | canvasHeight = toFloat h }

                    ExtendConnectorsBy offset ->
                        { settings | extendConnectorsBy = Just <| toFloat offset }

                    ExtendConnectorsByAdvanced extendConnectorsByAdvanced ->
                        { settings | extendConnectorsByAdvanced = Just extendConnectorsByAdvanced }

                    Level l ->
                        { settings | level = toFloat l }

                    Gutter g ->
                        { settings | gutter = toFloat g }

                    CenterOffset x y ->
                        { settings | centerOffset = ( toFloat x, toFloat y ) }

                    ConnectorStroke stroke ->
                        { settings | connectorStroke = stroke }

                    ConnectorStrokeWidth strokeWidth ->
                        { settings | connectorStrokeWidth = strokeWidth }

                    DragAndDrop isEnabled ->
                        { settings | dragAndDrop = isEnabled }

                    KeyboardNavigation enabled ->
                        { settings
                            | keyboardNavigation =
                                if enabled then
                                    Just
                                        { outsideId = Nothing
                                        }

                                else
                                    Nothing
                        }

                    KeyboardNavigationOutside domId enabled ->
                        { settings
                            | keyboardNavigation =
                                if enabled then
                                    Just
                                        { outsideId = Just domId
                                        }

                                else
                                    Nothing
                        }

                    ShowPlaceholderLeaves show ->
                        { settings | showPlaceholderLeaves = show }

                    ShowPlaceholderLeavesAdvanced show ->
                        { settings | showPlaceholderLeavesAdvanced = Just show }

                    DefaultNode node ->
                        { settings | defaultNode = Just node }

                    IsNodeClustered isNodeClustered ->
                        { settings | isNodeClustered = isNodeClustered }

                    Checksum checksum ->
                        { settings | checksum = Just checksum }
                )
