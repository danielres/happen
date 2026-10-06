defmodule HappenWeb.AccessControllerTest do
  use HappenWeb.ConnCase, async: true

  alias Happen.Accounts

  test "redeems an invitation into the browser session", %{conn: conn} do
    {invitation, token} = invitation_with_token()

    conn = get(conn, ~p"/invite/#{token}")

    assert redirected_to(conn) == ~p"/ex"
    assert get_session(conn, :invitation_id) == invitation.id
    assert get_resp_header(conn, "cache-control") == ["no-store"]
    assert get_resp_header(conn, "referrer-policy") == ["no-referrer"]
  end

  test "redeems a combined invitation and room URL", %{conn: conn} do
    {invitation, token} = invitation_with_token()
    room_id = Ash.UUID.generate()

    conn = get(conn, ~p"/invite/#{token}/r/#{room_id}")

    assert redirected_to(conn) == ~p"/r/#{room_id}"
    assert get_session(conn, :invitation_id) == invitation.id
  end

  test "returns a generic 404 for an invalid invitation", %{conn: conn} do
    conn = get(conn, ~p"/invite/not-a-valid-token")

    assert response(conn, 404) =~ "Not Found"
  end

  test "returns a generic 404 for a disabled invitation", %{conn: conn} do
    {invitation, token} = invitation_with_token()
    {:ok, _invitation} = Accounts.disable_invitation(invitation)

    conn = get(conn, ~p"/invite/#{token}")

    assert response(conn, 404) =~ "Not Found"
  end

  defp invitation_with_token do
    {:ok, invitation} = Accounts.create_invitation()
    {:ok, token} = Accounts.invitation_token(invitation)
    {invitation, token}
  end
end
