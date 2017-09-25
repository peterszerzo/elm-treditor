module Utils exposing (..)

import Json.Decode as Decode
import Html exposing (Attribute)
import Html.Events exposing (onWithOptions)


addFloatTuples : ( Float, Float ) -> ( Float, Float ) -> ( Float, Float )
addFloatTuples ( x1, y1 ) ( x2, y2 ) =
    ( x1 + x2, y1 + y2 )


onClickStopPropagation : msg -> Attribute msg
onClickStopPropagation message =
    let
        config =
            { stopPropagation = True
            , preventDefault = False
            }
    in
        onWithOptions "click" config (Decode.succeed message)


compareLists : List comparable -> List comparable -> Order
compareLists l1 l2 =
    case ( l1, l2 ) of
        ( head1 :: tail1, head2 :: tail2 ) ->
            let
                comp =
                    compare head1 head2
            in
                if comp == EQ then
                    compareLists tail1 tail2
                else
                    comp

        ( _, _ ) ->
            EQ
