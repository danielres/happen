defmodule HappenWeb.ExperimentsLiveHomeTest do
  use HappenWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Happen.RoomKey

  test "opens a room using its encoded name", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/ex")

    view
    |> form("[data-testid='room-form']", %{
      "room" => %{"name" => " Café room "}
    })
    |> render_submit()

    room_key = RoomKey.encode("Café room")
    assert_redirect(view, ~p"/ex/#{room_key}")
  end

  test "disables submission while the room name is invalid", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/ex")

    assert has_element?(view, "[data-testid='room-form'] button[type='submit'][disabled]")

    view
    |> form("[data-testid='room-form']", %{"room" => %{"name" => "abc"}})
    |> render_change()

    assert has_element?(view, "[data-testid='room-form'] button[type='submit'][disabled]")

    view
    |> form("[data-testid='room-form']", %{"room" => %{"name" => "valid room"}})
    |> render_change()

    refute has_element?(view, "[data-testid='room-form'] button[type='submit'][disabled]")
  end

  test "shows errors after submission and clears them while editing", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/ex")

    view
    |> form("[data-testid='room-form']", %{"room" => %{"name" => "abc"}})
    |> render_change()

    refute has_element?(view, "[data-testid='room-form'] p.text-error")

    view
    |> form("[data-testid='room-form']", %{"room" => %{"name" => "abc"}})
    |> render_submit()

    assert has_element?(
             view,
             "[data-testid='room-form'] p.text-error",
             "should be at least 4 character(s)"
           )

    view
    |> form("[data-testid='room-form']", %{"room" => %{"name" => "valid room"}})
    |> render_change()

    refute has_element?(view, "[data-testid='room-form'] p.text-error")

    view
    |> form("[data-testid='room-form']", %{
      "room" => %{"name" => "a room name that is too long"}
    })
    |> render_change()

    assert has_element?(
             view,
             "[data-testid='room-form'] p.text-error",
             "should be at most 16 character(s)"
           )
  end
end
