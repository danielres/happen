defmodule HappenWeb.Components.ButtonInviteFriends do
  use HappenWeb, :connected_component

  alias Happen.Accounts

  def on_mount(socket) do
    socket =
      socket
      |> assign_new(:active_invitations, fn -> [] end)
      |> assign_new(:invitation_url, fn -> nil end)
      |> assign_new(:share_form, fn -> share_form([]) end)
      |> assign_new(:sharing_room?, fn -> false end)

    {:ok, socket, fn -> :ok end}
  end

  def handle_update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  def render(assigns) do
    ~H"""
    <div id={@id} {@connected_attrs} phx-hook=".InviteFriends">
      <div
        :if={@sharing_room?}
        class="flex justify-end"
      >
        <div
          :if={@access_kind == :invitation}
          id="room-invitation-details"
          class="grid max-w-2xl gap-3 bg-base-200 p-4"
        >
          <p class="opacity-75">Share this link with your friends to invite them to this room.</p>
          <p
            id="room-invitation-url"
            class="opacity-75 break-all rounded bg-base-300 p-2 font-mono text-sm"
          >
            {@invitation_url}
          </p>

          <div class="flex justify-end gap-2">
            <.button
              id="cancel-room-invitation"
              class="btn btn-sm btn-primary btn-soft"
              type="button"
              phx-click="cancel-room-invitation"
              phx-target={@myself}
            >
              Cancel
            </.button>

            <.button
              id="copy-room-invitation"
              class="btn btn-primary btn-sm"
              type="button"
              phx-click="copy-room-invitation"
              phx-target={@myself}
              phx-mounted={JS.focus()}
            >
              Copy link
            </.button>
          </div>
        </div>

        <.form
          :if={@access_kind == :admin}
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
          <.button id="copy-room-invitation" type="submit">Copy link</.button>
          <.button
            id="cancel-room-invitation"
            type="button"
            phx-click="cancel-room-invitation"
            phx-target={@myself}
          >
            Cancel
          </.button>
        </.form>
      </div>

      <div class="relative">
        <div
          :if={!@sharing_room?}
          class={["absolute top-2 right-4 z-50"]}
        >
          <button
            id="invite-friends"
            phx-click="invite-friends"
            phx-target={@myself}
            type="button"
            class="btn btn-circle btn-primary tooltip tooltip-primary tooltip-left"
            data-tip="Invite friends"
          >
            <.icon name="hero-user-plus-solid" class="size-5" />
            <span class="sr-only">Invite friends</span>
          </button>
        </div>
      </div>

      <script :type={Phoenix.LiveView.ColocatedHook} name=".InviteFriends">
        export default {
          mounted() {
            this.handleEvent("copy-room-invitation-url", ({url}) => {
              navigator.clipboard?.writeText(url).catch(() => {})
            })
          }
        }
      </script>
    </div>
    """
  end

  def handle_event("invite-friends", _params, %{assigns: %{access_kind: :invitation}} = socket) do
    case Accounts.get_enabled_invitation(socket.assigns.current_invitation.id) do
      {:ok, invitation} -> show_room_invitation(socket, invitation)
      {:error, _error} -> {:noreply, push_navigate(socket, to: ~p"/404")}
    end
  end

  def handle_event("cancel-room-invitation", _params, socket) do
    {:noreply, hide_room_invitation(socket)}
  end

  def handle_event(
        "copy-room-invitation",
        _params,
        %{assigns: %{access_kind: :invitation, invitation_url: invitation_url}} = socket
      )
      when is_binary(invitation_url) do
    socket =
      socket
      |> hide_room_invitation()
      |> push_event("copy-room-invitation-url", %{url: invitation_url})

    {:noreply, socket}
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
        url = room_invitation_url(socket, token)
        {:noreply, push_event(socket, "copy-room-invitation-url", %{url: url})}

      {:error, _error} ->
        {:noreply, put_flash(socket, :error, "Could not copy room invitation URL")}
    end
  end

  defp show_room_invitation(socket, invitation) do
    case Accounts.invitation_token(invitation) do
      {:ok, token} ->
        {:noreply,
         socket
         |> assign(:invitation_url, room_invitation_url(socket, token))
         |> assign(:sharing_room?, true)}

      {:error, _error} ->
        {:noreply, put_flash(socket, :error, "Could not show room invitation URL")}
    end
  end

  defp hide_room_invitation(socket) do
    socket
    |> assign(:invitation_url, nil)
    |> assign(:sharing_room?, false)
  end

  defp room_invitation_url(socket, token) do
    "#{HappenWeb.Endpoint.url()}/invite/#{token}/r/#{socket.assigns.room.id}"
  end
end
