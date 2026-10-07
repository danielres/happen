defmodule HappenWeb.AccessController do
  use HappenWeb, :controller

  alias Happen.Accounts
  alias Happen.RoomKey

  def redeem(conn, %{"token" => token, "room_key" => room_key}) do
    case RoomKey.decode(room_key) do
      {:ok, _room_name} -> redeem_and_redirect(conn, token, ~p"/#{room_key}")
      :error -> not_found(conn, %{})
    end
  end

  def redeem(conn, %{"token" => token}) do
    redeem_and_redirect(conn, token, ~p"/")
  end

  def not_found(conn, _params) do
    conn
    |> protect_secret()
    |> put_status(:not_found)
    |> put_view(html: HappenWeb.ErrorHTML)
    |> render(:"404")
  end

  defp redeem_and_redirect(conn, token, destination) do
    case Accounts.redeem_invitation(token) do
      {:ok, invitation} ->
        conn
        |> protect_secret()
        |> configure_session(renew: true)
        |> put_session(:invitation_id, invitation.id)
        |> redirect(to: destination)

      {:error, _error} ->
        not_found(conn, %{})
    end
  end

  defp protect_secret(conn) do
    conn
    |> put_resp_header("cache-control", "no-store")
    |> put_resp_header("referrer-policy", "no-referrer")
  end
end
