defmodule HappenWeb.Plugs.GuestIdTest do
  use HappenWeb.ConnCase, async: true

  test "assigns a new guest ID and stores it in a signed cookie", %{conn: conn} do
    conn = get(conn, ~p"/")

    guest_id = conn.assigns.guest_id

    assert {:ok, ^guest_id} = Ecto.UUID.cast(guest_id)
    assert get_session(conn, :guest_id) == guest_id

    assert %{
             "guest_id" => %{
               http_only: true,
               max_age: 31_536_000,
               path: "/",
               same_site: "Lax",
               value: signed_guest_id
             }
           } = get_resp_cookies(conn)

    refute signed_guest_id == guest_id
  end

  test "reuses the guest ID from the signed cookie", %{conn: conn} do
    first_conn = get(conn, ~p"/")
    guest_id = first_conn.assigns.guest_id

    second_conn =
      first_conn
      |> recycle()
      |> get(~p"/")

    assert second_conn.assigns.guest_id == guest_id
    assert get_session(second_conn, :guest_id) == guest_id
    refute Map.has_key?(get_resp_cookies(second_conn), "guest_id")
  end
end
