defmodule HappenWeb.LiveAccess do
  import Phoenix.Component, only: [assign: 3]

  use HappenWeb, :verified_routes

  alias Happen.Accounts

  def on_mount(:require, _params, session, socket) do
    case access_from_session(session) do
      {:admin, admin} ->
        socket =
          socket
          |> assign(:access_kind, :admin)
          |> assign(:current_admin, admin)
          |> assign(:current_invitation, nil)

        {:cont, socket}

      {:invitation, invitation} ->
        socket =
          socket
          |> assign(:access_kind, :invitation)
          |> assign(:current_admin, nil)
          |> assign(:current_invitation, invitation)
          |> subscribe_to_revocation(invitation)

        {:cont, socket}

      :error ->
        {:halt, Phoenix.LiveView.redirect(socket, to: ~p"/404")}
    end
  end

  def revoke(invitation_id) do
    Phoenix.PubSub.broadcast(
      Happen.PubSub,
      topic(invitation_id),
      {:invitation_revoked, invitation_id}
    )
  end

  defp access_from_session(%{"admin_id" => admin_id} = session) do
    case Accounts.get_admin() do
      {:ok, %{id: ^admin_id} = admin} -> {:admin, admin}
      _result -> invitation_access(session)
    end
  end

  defp access_from_session(session), do: invitation_access(session)

  defp invitation_access(%{"invitation_id" => invitation_id}) do
    case Accounts.get_enabled_invitation(invitation_id) do
      {:ok, invitation} -> {:invitation, invitation}
      _result -> :error
    end
  end

  defp invitation_access(_session), do: :error

  defp subscribe_to_revocation(socket, invitation) do
    if Phoenix.LiveView.connected?(socket) do
      Phoenix.PubSub.subscribe(Happen.PubSub, topic(invitation.id))
    end

    Phoenix.LiveView.attach_hook(socket, :invitation_revocation, :handle_info, fn
      {:invitation_revoked, invitation_id}, socket when invitation_id == invitation.id ->
        {:halt, Phoenix.LiveView.redirect(socket, to: ~p"/404")}

      _message, socket ->
        {:cont, socket}
    end)
  end

  defp topic(invitation_id), do: "invitation:#{invitation_id}"
end
