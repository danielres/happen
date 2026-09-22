defmodule HappenWeb.InvitationAccessTest do
  use HappenWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Happen.Accounts
  alias HappenWeb.LiveAccess

  test "the app rejects a browser without invitation access", %{conn: conn} do
    assert {:error, {:redirect, %{to: "/404"}}} = live(conn, ~p"/")
  end

  test "an enabled invitation grants access to the app", %{conn: conn} do
    {:ok, invitation} = Accounts.create_invitation()
    conn = init_test_session(conn, %{"invitation_id" => invitation.id})

    assert {:ok, view, _html} = live(conn, ~p"/")
    assert has_element?(view, "#create-room-form")
  end

  test "disabling an invitation revokes connected LiveViews immediately", %{conn: conn} do
    {:ok, invitation} = Accounts.create_invitation()
    conn = init_test_session(conn, %{"invitation_id" => invitation.id})
    {:ok, view, _html} = live(conn, ~p"/")

    {:ok, _invitation} = Accounts.disable_invitation(invitation)
    LiveAccess.revoke(invitation.id)

    assert_redirect(view, "/404")
  end
end
