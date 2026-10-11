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

  test "admin copies an invitation path for the browser's current origin", %{conn: conn} do
    password = "a secure admin password"
    {:ok, admin} = Accounts.initialize_admin(password, password)
    {:ok, invitation} = Accounts.create_invitation()

    admin_conn = init_test_session(conn, %{"admin_id" => admin.id})
    {:ok, admin_view, _html} = live(admin_conn, ~p"/_")

    admin_view
    |> element("#copy-invitation-#{invitation.id}")
    |> render_click()

    assert_push_event(admin_view, "copy-invitation-url", %{path: path})
    assert String.starts_with?(path, "/invite/")
    refute String.starts_with?(path, "http")
  end

  test "disabling an invitation from admin revokes every active LiveView using it", %{conn: conn} do
    password = "a secure admin password"
    {:ok, admin} = Accounts.initialize_admin(password, password)
    {:ok, invitation} = Accounts.create_invitation()

    room_path = ~p"/#{RoomKey.encode("Integration test room")}"

    first_conn = init_test_session(conn, %{"invitation_id" => invitation.id})
    second_conn = init_test_session(build_conn(), %{"invitation_id" => invitation.id})

    {:ok, first_view, _html} = live(first_conn, room_path)
    {:ok, second_view, _html} = live(second_conn, room_path)

    admin_conn = init_test_session(build_conn(), %{"admin_id" => admin.id})
    {:ok, admin_view, _html} = live(admin_conn, ~p"/_")

    admin_view
    |> element("[data-testid='disable-invitation'][phx-value-id='#{invitation.id}']")
    |> render_click()

    assert_redirect(first_view, "/404")
    assert_redirect(second_view, "/404")
  end
end
