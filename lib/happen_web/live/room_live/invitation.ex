defmodule HappenWeb.RoomLive.Invitation do
  use HappenWeb, :live_view
  use LiveDelegate, path: [:invitation]

  alias Happen.Accounts

  def handle_event("copy", _params, socket) do
    invitation = socket.assigns.current_invitation
    room_key = socket.assigns.room.data.key

    with {:ok, token} <- Accounts.invitation_token(invitation) do
      path = ~p"/invite/#{token}?room_key=#{room_key}"
      {:noreply, push_event(socket, "copy-room-invitation-url", %{path: path})}
    else
      {:error, _error} ->
        {:noreply, Toast.put_toast(socket, :error, "Could not copy invitation")}
    end
  end

  def handle_event("clipboard-result", %{"success" => true}, socket) do
    {:noreply, Toast.put_toast(socket, :info, "Invitation URL copied")}
  end

  def handle_event("clipboard-result", _params, socket) do
    {:noreply, Toast.put_toast(socket, :error, "Could not access the clipboard")}
  end

  def render_button(assigns) do
    ~H"""
    <button
      id="invite-friends"
      class={[
        "btn btn-sm btn-info",
        "tooltip tooltip-info tooltip-bottom tooltip-end"
      ]}
      data-clipboard-result-event={delegate_event("clipboard-result")}
      data-copy-event="copy-room-invitation-url"
      data-testid="invite-friends"
      phx-click={delegate_event("copy")}
      phx-hook=".CopyRoomInvitationToClipboard"
      type="button"
    >
      Invite friends <.icon name="hero-user-plus-solid" class="size-5" />
      <span class="tooltip-content">Invite friends to this room</span>
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

          this.handleEvent(this.el.dataset.copyEvent, ({path}) => {
            if (!navigator.clipboard) {
              this.pushEvent(this.el.dataset.clipboardResultEvent, {success: false})
              return
            }

            const url = new URL(path, window.location.origin).toString()

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
