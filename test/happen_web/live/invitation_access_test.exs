defmodule HappenWeb.InvitationAccessTest do
  use HappenWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Happen.Accounts
  alias Happen.RoomKey

  test "the app rejects a browser without invitation access", %{conn: conn} do
    assert {:error, {:redirect, %{to: "/404"}}} = live(conn, ~p"/")
  end

  test "an enabled invitation grants access to the app", %{conn: conn} do
    {:ok, invitation} = Accounts.create_invitation()
    conn = init_test_session(conn, %{"invitation_id" => invitation.id})

    assert {:ok, view, _html} = live(conn, ~p"/")
    assert has_element?(view, "[data-testid='room-form']")
  end

  test "disabling an invitation from admin revokes an active room LiveView", %{conn: conn} do
    password = "a secure admin password"
    {:ok, admin} = Accounts.initialize_admin(password, password)
    {:ok, invitation} = Accounts.create_invitation()

    invited_conn = init_test_session(conn, %{"invitation_id" => invitation.id})
    room_path = ~p"/#{RoomKey.encode("Integration test room")}"
    {:ok, invited_view, _html} = live(invited_conn, room_path)

    admin_conn = init_test_session(build_conn(), %{"admin_id" => admin.id})
    {:ok, admin_view, _html} = live(admin_conn, ~p"/_")

    admin_view
    |> element("[data-testid='disable-invitation'][phx-value-id='#{invitation.id}']")
    |> render_click()

    assert_redirect(invited_view, "/404")
  end
end
