module Main exposing (..)

import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Keyed as Keyed
import Html.Lazy exposing (lazy)


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = \_ -> Sub.none
        }



-- MODEL


type alias Model =
    { input : String
    , items : List TodoItem
    , nextId : ItemId
    }


type alias TodoItem =
    { id : ItemId
    , description : String
    , done : Bool
    }


type alias ItemId =
    Int


init : () -> ( Model, Cmd Msg )
init _ =
    ( { items = [], input = "", nextId = 0 }, Cmd.none )



-- UPDATE


type Msg
    = InputDescription String
    | AddItem
    | MarkAsDone ItemId
    | MarkAsUndone ItemId


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        InputDescription input ->
            ( { model | input = input }, Cmd.none )

        AddItem ->
            ( { model
                | input = ""
                , items = { id = model.nextId, description = model.input, done = False } :: model.items
                , nextId = model.nextId + 1
              }
            , Cmd.none
            )

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
