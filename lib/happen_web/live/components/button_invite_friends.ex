defmodule HappenWeb.Components.ButtonInviteFriends do
  use HappenWeb, :live_component

  alias Happen.Accounts

  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_new(:active_invitations, fn -> [] end)
      |> assign_new(:share_form, fn -> share_form([]) end)
      |> assign_new(:sharing_room?, fn -> false end)

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div id={@id}>
      <div
        :if={@sharing_room?}
        class="flex justify-end"
      >
        <.form
          class="max-w-2xl bg-base-200 p-4"
          for={@share_form}
          id="room-invitation-form"
          phx-submit="copy-room-invitation"
          phx-target={@myself}
        >
          <.input
            field={@share_form[:invitation_id]}
            label="Share using invitation"
            options={Enum.map(@active_invitations, &{&1.shared_with, &1.id})}
            type="select"
          />
          <.button type="submit">Copy link</.button>
          <.button type="button" phx-click="cancel-room-invitation" phx-target={@myself}>
            Cancel
          </.button>
        </.form>
      </div>

      <div
        :if={!@sharing_room?}
        class="flex justify-end p-4 h-0"
      >
        <button
          id="invite-friends"
          phx-click="invite-friends"
          phx-target={@myself}
          type="button"
          class="btn btn-sm btn-primary"
        >
          <.icon name="hero-user-plus-micro" /> Invite friends
        </button>
      </div>
    </div>
    """
  end

  def handle_event("invite-friends", _params, %{assigns: %{access_kind: :invitation}} = socket) do
    case Accounts.get_enabled_invitation(socket.assigns.current_invitation.id) do
      {:ok, invitation} -> copy_room_invitation(socket, invitation)
      {:error, _error} -> {:noreply, push_navigate(socket, to: ~p"/404")}
    end
  end

  def handle_event("cancel-room-invitation", _params, socket) do
    {:noreply, assign(socket, :sharing_room?, false)}
  end

  def handle_event(
        "copy-room-invitation",
        %{"share" => %{"invitation_id" => invitation_id}},
        %{assigns: %{access_kind: :admin}} = socket
      ) do
    case Accounts.get_enabled_invitation(invitation_id) do
      {:ok, invitation} ->
        socket
        |> assign(:sharing_room?, false)
        |> copy_room_invitation(invitation)

      {:error, _error} ->
        {:noreply, put_flash(socket, :error, "Choose an active invitation")}
    end
  end

  def handle_event("invite-friends", _params, %{assigns: %{access_kind: :admin}} = socket) do
    invitations = enabled_invitations()

    if invitations == [] do
      {:noreply, put_flash(socket, :error, "Create an active invitation in admin first")}
    else
      {:noreply,
       socket
       |> assign(:active_invitations, invitations)
       |> assign(:share_form, share_form(invitations))
       |> assign(:sharing_room?, true)}
    end
  end

  defp enabled_invitations do
    case Accounts.list_enabled_invitations() do
      {:ok, invitations} -> invitations
      {:error, _error} -> []
    end
  end

  defp share_form([invitation | _invitations]) do
    to_form(%{"invitation_id" => invitation.id}, as: :share)
  end

  defp share_form([]), do: to_form(%{"invitation_id" => ""}, as: :share)

  defp copy_room_invitation(socket, invitation) do
    case Accounts.invitation_token(invitation) do
      {:ok, token} ->
        url = "#{HappenWeb.Endpoint.url()}/invite/#{token}/r/#{socket.assigns.room.id}"
        {:noreply, push_event(socket, "copy-room-invitation-url", %{url: url})}

      {:error, _error} ->
        {:noreply, put_flash(socket, :error, "Could not copy room invitation URL")}
    end
  end
end
