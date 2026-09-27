defmodule HappenWeb.Plugs.GuestId do
  import Plug.Conn

  @cookie_name "guest_id"
  @cookie_max_age 60 * 60 * 12

  def init(opts), do: opts

  def call(conn, _opts) do
    conn = fetch_cookies(conn, signed: [@cookie_name])

    case valid_guest_id(conn.cookies[@cookie_name]) do
      {:ok, guest_id} ->
        identify_guest(conn, guest_id)

      :error ->
        guest_id = Ash.UUID.generate()

        conn
        |> put_resp_cookie(@cookie_name, guest_id,
          http_only: true,
          max_age: @cookie_max_age,
          path: "/",
          same_site: "Lax",
          sign: true
        )
        |> identify_guest(guest_id)
    end
  end

  defp valid_guest_id(guest_id) when is_binary(guest_id), do: Ecto.UUID.cast(guest_id)
  defp valid_guest_id(_guest_id), do: :error

  defp identify_guest(conn, guest_id) do
    conn
    |> assign(:guest_id, guest_id)
    |> put_session(:guest_id, guest_id)
  end
end
