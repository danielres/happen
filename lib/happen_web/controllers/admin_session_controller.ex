defmodule HappenWeb.AdminSessionController do
  use HappenWeb, :controller

  alias Happen.Accounts

  def setup(conn, %{"admin" => params}) do
    case Accounts.initialize_admin(params["password"], params["password_confirmation"]) do
      {:ok, admin} ->
        conn
        |> sign_in(admin)
        |> put_flash(:info, "Admin password set")
        |> redirect(to: ~p"/_")

      {:error, _error} ->
        setup_failed(conn)
    end
  end

  def setup(conn, _params), do: setup_failed(conn)

  def login(conn, %{"admin" => %{"password" => password}}) do
    case Accounts.authenticate_admin(password) do
      {:ok, admin} ->
        conn
        |> sign_in(admin)
        |> redirect(to: ~p"/_")

      {:error, :invalid_credentials} ->
        conn
        |> put_flash(:error, "Incorrect password")
        |> redirect(to: ~p"/_")
    end
  end

  def login(conn, _params) do
    conn
    |> put_flash(:error, "Incorrect password")
    |> redirect(to: ~p"/_")
  end

  def logout(conn, _params) do
    conn
    |> configure_session(renew: true)
    |> delete_session(:admin_id)
    |> redirect(to: ~p"/_")
  end

  defp setup_failed(conn) do
    case Accounts.get_admin() do
      {:ok, _admin} ->
        conn
        |> put_flash(:error, "Admin is already set up. Sign in instead.")
        |> redirect(to: ~p"/_")

      {:error, _error} ->
        conn
        |> put_flash(:error, "Password must be 12 to 128 characters and match its confirmation.")
        |> redirect(to: ~p"/_")
    end
  end

  defp sign_in(conn, admin) do
    conn
    |> configure_session(renew: true)
    |> put_session(:admin_id, admin.id)
  end
end
