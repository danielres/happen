defmodule HappenWeb.GuestSessionController do
  use HappenWeb, :controller

  def create(conn, %{"guest" => %{"name" => name, "room_name" => room_key}}) do
    name = name |> String.trim()

    conn
    |> put_session(:guest_name, name)
    |> put_session(:guest_since, DateTime.now!("Etc/UTC"))
    |> redirect(to: ~p"/ex/#{room_key}")
  end

  def delete(conn, _params) do
    conn
    |> delete_session(:guest_name)
    |> redirect(to: ~p"/ex")
  end
end
