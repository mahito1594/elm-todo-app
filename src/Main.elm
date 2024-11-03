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
    | MarkAsDone ItemId
    | MarkAsUndone ItemId


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

        MarkAsDone itemId ->
            let
                done : ItemId -> TodoItem -> TodoItem
                done id item =
                    if item.id == id then
                        { item | done = True }

                    else
                        item
            in
            ( { model
                | items = List.map (done itemId) model.items
              }
            , Cmd.none
            )

        MarkAsUndone itemId ->
            let
                undone : ItemId -> TodoItem -> TodoItem
                undone id item =
                    if item.id == id then
                        { item | done = False }

                    else
                        item
            in
            ( { model
                | items = List.map (undone itemId) model.items
              }
            , Cmd.none
            )



-- SUBSCTIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    newItemReciever (D.decodeValue decoder) |> Sub.map ItemSaved



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

        clickHandler : TodoItem -> Msg
        clickHandler itm =
            if itm.done then
                MarkAsUndone itm.id

            else
                MarkAsDone itm.id

        viewButton : TodoItem -> Html Msg
        viewButton itm =
            button [ class "outline", onClick (clickHandler itm) ]
                [ text
                    (if itm.done then
                        "Undone"

                     else
                        "Done"
                    )
                ]

        viewArticle : TodoItem -> Html Msg
        viewArticle itm =
            article
                []
                [ viewDescription itm
                , footer []
                    [ viewButton itm
                    ]
                ]
    in
    ( String.fromInt item.id, lazy viewArticle item )



-- Ports


port addNewTodoItem : E.Value -> Cmd msg


port newItemReciever : (E.Value -> msg) -> Sub msg



-- JSON Encode/Decode


decoder : D.Decoder TodoItem
decoder =
    D.map3 TodoItem
        (D.field "id" D.int)
        (D.field "description" D.string)
        (D.field "done" D.bool)
