defmodule HappenWeb.RoomLive.Invitation do
  use HappenWeb, :live_view
  use LiveDelegate, path: [:invitation]

  alias Happen.Accounts

  def handle_event("create", _params, socket) do
    room_key = socket.assigns.room.data.key

    with {:ok, invitation} <- Accounts.create_invitation(),
         {:ok, token} <- Accounts.invitation_token(invitation) do
      url = HappenWeb.Endpoint.url() <> ~p"/invite/#{token}?room_key=#{room_key}"
      {:noreply, push_event(socket, "copy-room-invitation-url", %{url: url})}
    else
      {:error, _error} ->
        {:noreply, Toast.put_toast(socket, :error, "Could not create invitation")}
    end
  end

  def handle_event("clipboard-result", %{"success" => true}, socket) do
    {:noreply, Toast.put_toast(socket, :success, "Invitation URL copied")}
  end

  def handle_event("clipboard-result", _params, socket) do
    {:noreply, Toast.put_toast(socket, :error, "Could not access the clipboard")}
  end

  def render_button(assigns) do
    ~H"""
    <button
      id="invite-friends"
      class={[
        "btn btn-success btn-circle",
        "tooltip tooltip-success tooltip-left"
      ]}
      data-clipboard-result-event={delegate_event("clipboard-result")}
      data-copy-event="copy-room-invitation-url"
      data-testid="invite-friends"
      phx-click={delegate_event("create")}
      phx-hook=".CopyRoomInvitationToClipboard"
      type="button"
    >
      <.icon name="hero-user-plus-micro" />
      <span class="tooltip-content max-w-32 text-right">Invite friends to this room</span>
    </button>

    <script
      :type={Phoenix.LiveView.ColocatedHook}
      name=".CopyRoomInvitationToClipboard"
      extension="ts"
    >
      export default {
        mounted() {
          const foo: string = "foo"
          const baf = foo + 2

          this.handleEvent(this.el.dataset.copyEvent, ({url}) => {
            if (!navigator.clipboard) {
              this.pushEvent(this.el.dataset.clipboardResultEvent, {success: false})
              return
            }

            navigator.clipboard.writeText(url)
              .then(() => this.pushEvent(this.el.dataset.clipboardResultEvent, {success: true}))
              .catch(() => this.pushEvent(this.el.dataset.clipboardResultEvent, {success: false}))
          })
        }
      }
    </script>
    """
  end
end
