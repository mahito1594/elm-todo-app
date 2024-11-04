port module Main exposing (..)

import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Keyed as Keyed
import Html.Lazy exposing (lazy)
import Json.Decode as D
import Json.Encode as E


main : Program E.Value Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- MODEL


type alias Model =
    { input : String
    , items : List TodoItem
    }


type alias TodoItem =
    { id : ItemId
    , description : String
    , done : Bool
    }


type alias ItemId =
    Int


init : E.Value -> ( Model, Cmd Msg )
init flags =
    let
        items : List TodoItem
        items =
            case D.decodeValue (D.list decoder) flags of
                Ok todoItems ->
                    todoItems

                Err _ ->
                    []
    in
    ( { items = items, input = "" }
    , Cmd.none
    )



-- UPDATE


type Msg
    = InputDescription String
    | AddItem
    | ItemSaved (Result D.Error TodoItem)
    | ToggleStatus TodoItem
    | StatusToggled ItemId
    | DeleteItem ItemId


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        InputDescription input ->
            ( { model | input = input }, Cmd.none )

        AddItem ->
            ( model
            , addNewTodoItem
                (E.object
                    [ ( "description", E.string model.input )
                    , ( "done", E.bool False )
                    ]
                )
            )

        ItemSaved (Ok item) ->
            ( { model | input = "", items = item :: model.items }, Cmd.none )

        -- TODO: Add handling for parse errors
        ItemSaved (Err _) ->
            ( model, Cmd.none )

        ToggleStatus item ->
            ( model
            , toggleStatus
                (E.object
                    [ ( "id", E.int item.id )
                    , ( "description", E.string item.description )
                    , ( "done", E.bool <| not item.done )
                    ]
                )
            )

        StatusToggled itemId ->
            let
                toggleAt : Int -> List TodoItem -> List TodoItem
                toggleAt id items =
                    List.map
                        (\item ->
                            if item.id == id then
                                { item | done = not item.done }

                            else
                                item
                        )
                        items
            in
            ( { model
                | items = toggleAt itemId model.items
              }
            , Cmd.none
            )

        DeleteItem itemId ->
            ( { model | items = List.filter (\item -> item.id /= itemId) model.items }, deleteTodoItem itemId )



-- SUBSCTIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ newItemReciever (D.decodeValue decoder) |> Sub.map ItemSaved
        , toggleStatusReciever StatusToggled
        ]



-- VIEW


view : Model -> Html Msg
view model =
    div []
        [ section []
            [ Html.form [ onSubmit AddItem ]
                [ input [ type_ "text", value model.input, onInput InputDescription ] []
                , button
                    [ type_ "submit", disabled (String.isEmpty model.input) ]
                    [ text "Add" ]
                ]
            ]
        , Keyed.node "section" [] (List.map viewItem model.items)
        ]


viewItem : TodoItem -> ( String, Html Msg )
viewItem item =
    let
        viewDescription : TodoItem -> Html Msg
        viewDescription itm =
            if itm.done then
                del [] [ text itm.description ]

            else
                text itm.description

        viewStatusToggleButton : TodoItem -> Html Msg
        viewStatusToggleButton itm =
            button [ class "outline", onClick (ToggleStatus itm) ]
                [ text
                    (if itm.done then
                        "Undone"

                     else
                        "Done"
                    )
                ]

        viewDeleteButton : TodoItem -> Html Msg
        viewDeleteButton itm =
            button
                [ classList [ ( "outline", True ), ( "contrast", True ) ]
                , onClick (DeleteItem itm.id)
                ]
                [ text "Delete" ]

        viewArticle : TodoItem -> Html Msg
        viewArticle itm =
            article
                []
                [ viewDescription itm
                , footer []
                    [ div [ class "grid" ]
                        [ viewStatusToggleButton itm
                        , viewDeleteButton itm
                        ]
                    ]
                ]
    in
    ( String.fromInt item.id, lazy viewArticle item )



-- Ports


port addNewTodoItem : E.Value -> Cmd msg


port toggleStatus : E.Value -> Cmd msg


port deleteTodoItem : ItemId -> Cmd msg


port newItemReciever : (E.Value -> msg) -> Sub msg


port toggleStatusReciever : (ItemId -> msg) -> Sub msg



-- JSON Encode/Decode


decoder : D.Decoder TodoItem
decoder =
    D.map3 TodoItem
        (D.field "id" D.int)
        (D.field "description" D.string)
        (D.field "done" D.bool)
