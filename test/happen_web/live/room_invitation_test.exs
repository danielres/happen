defmodule HappenWeb.RoomInvitationTest do
  use HappenWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Happen.Accounts
  alias Happen.Rooms

  test "an invited member can copy a room URL backed by their invitation", %{conn: conn} do
    {:ok, invitation} = Accounts.create_invitation()
    {:ok, token} = Accounts.invitation_token(invitation)
    {:ok, room} = Rooms.create_room("Friends")
    conn = init_test_session(conn, %{"invitation_id" => invitation.id})
    {:ok, view, _html} = live(conn, ~p"/r/#{room.id}")

    view
    |> form("#member-join-form", member: %{name: "Jane"})
    |> render_submit()

    view
    |> element("#invite-friends")
    |> render_click()

    expected_url = "#{HappenWeb.Endpoint.url()}/invite/#{token}/r/#{room.id}"
    assert_push_event(view, "copy-room-invitation-url", %{url: ^expected_url})
  end

  test "an admin chooses an active invitation before copying a room URL", %{conn: conn} do
    {:ok, admin} = Accounts.initialize_admin("a secure admin password", "a secure admin password")
    {:ok, invitation} = Accounts.create_invitation()
    {:ok, token} = Accounts.invitation_token(invitation)
    {:ok, room} = Rooms.create_room("Friends")
    conn = init_test_session(conn, %{"admin_id" => admin.id})
    {:ok, view, _html} = live(conn, ~p"/r/#{room.id}")

    view
    |> form("#member-join-form", member: %{name: "Jane"})
    |> render_submit()

    view
    |> element("#invite-friends")
    |> render_click()

    assert has_element?(view, "#room-invitation-form")

    view
    |> form("#room-invitation-form", share: %{invitation_id: invitation.id})
    |> render_submit()

    expected_url = "#{HappenWeb.Endpoint.url()}/invite/#{token}/r/#{room.id}"
    assert_push_event(view, "copy-room-invitation-url", %{url: ^expected_url})
    refute has_element?(view, "#room-invitation-form")
  end
end
