defmodule HappenWeb.RoomLive do
  use HappenWeb, :live_view

  alias Happen.Accounts
  alias Happen.PS
  alias HappenWeb.Presence

  def mount(params, _session, socket) do
    room_id = params["room_id"]

    case Ash.get(Happen.Rooms.Room, room_id) do
      {:ok, room} ->
        Presence.monitor(socket, room_id)
        PS.messages_subscribe(socket, room)
        active_invitations = active_invitations(socket.assigns.access_kind)

        socket =
          socket
          |> assign(room: room)
          |> assign(members: [])
          |> assign(member: nil)
          |> assign(member_form: member_name_changeset(%{}) |> to_form(as: :member))
          |> assign(messages: [])
          |> assign(active_invitations: active_invitations)
          |> assign(sharing_room?: false)
          |> assign(share_form: share_form(active_invitations))

        {:ok, socket}

      {:error, _error} ->
        socket =
          socket
          |> put_flash(:info, "group not found")
          |> push_navigate(to: ~p"/")

        {:ok, socket}
    end
  end

  def handle_event("toggle", _, socket) do
    room_id = socket.assigns.room.id
    Presence.toggle(room_id, socket.assigns.member)
    member = socket.assigns.member
    member = %{member | available?: !member.available?}
    socket = socket |> assign(member: member)
    {:noreply, socket}
  end

  def handle_event("join", %{"member" => params}, socket) do
    case params |> member_name_changeset() |> Ecto.Changeset.apply_action(:insert) do
      {:ok, %{name: name}} ->
        member = %{name: name, available?: true}
        Presence.join(socket.assigns.room.id, member)
        {:noreply, assign(socket, :member, member)}

      {:error, changeset} ->
        {:noreply, assign(socket, :member_form, to_form(changeset, as: :member))}
    end
  end

  def handle_event("invite-friends", _params, %{assigns: %{access_kind: :invitation}} = socket) do
    case Accounts.get_enabled_invitation(socket.assigns.current_invitation.id) do
      {:ok, invitation} -> copy_room_invitation(socket, invitation)
      {:error, _error} -> {:noreply, push_navigate(socket, to: ~p"/404")}
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

  def handle_event("cancel-room-invitation", _params, socket) do
    {:noreply, assign(socket, :sharing_room?, false)}
  end

  def handle_event("room-clipboard-result", %{"success" => true}, socket) do
    {:noreply, put_flash(socket, :info, "Room invitation URL copied")}
  end

  def handle_event("room-clipboard-result", _params, socket) do
    {:noreply, put_flash(socket, :error, "Could not access the clipboard")}
  end

  def handle_event("say", params, socket) do
    :ok =
      PS.message_broadcast(socket.assigns.room, %{
        member: socket.assigns.member,
        body: params["message"]
      })

    {:noreply, push_event(socket, "message-sent", %{})}
  end

  def handle_info({:group, _events, _info}, socket) do
    room_id = socket.assigns.room.id
    members = Presence.get_members(room_id)
    socket = socket |> assign(members: members)
    {:noreply, socket}
  end

  def handle_info(%{message: message}, socket) do
    messages = socket.assigns.messages
    messages = messages ++ [message]
    socket = socket |> assign(messages: messages)
    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <%= if @member do %>
      <Layouts.app flash={@flash}>
        <div
          id="room"
          class="flex h-dvh min-h-0 flex-col overflow-hidden"
          phx-hook=".CopyRoomInvitation"
        >
          <header class="bg-base-300 flex shrink-0 items-end justify-between gap-4 p-4">
            <h1>
              <div class="uppercase text-xs opacity-50">Room</div>
              <div class="font-semibold opacity-60">{@room.name}</div>
            </h1>

            <button
              phx-click="toggle"
              type="button"
              class="flex items-baseline gap-2 cursor-pointer text-xs"
            >
              <span :if={@member.available?} class="text-success">Available now</span>
              <span :if={!@member.available?} class="text-warning">Not available now</span>
              <HappenWeb.Components.Badge.render member={@member} />
            </button>
          </header>

          <.form
            :if={@sharing_room?}
            for={@share_form}
            id="room-invitation-form"
            class="bg-base-200 flex shrink-0 items-end gap-2 border-b border-base-300 p-4"
            phx-submit="copy-room-invitation"
          >
            <.input
              field={@share_form[:invitation_id]}
              label="Share using invitation"
              options={Enum.map(@active_invitations, &{&1.shared_with, &1.id})}
              type="select"
            />
            <.button type="submit">Copy link</.button>
            <.button type="button" phx-click="cancel-room-invitation">Cancel</.button>
          </.form>

          <div class="flex justify-end p-4 h-0">
            <button
              id="invite-friends"
              phx-click="invite-friends"
              type="button"
              class="btn btn-sm btn-primary"
            >
              <.icon name="hero-user-plus-micro" /> Invite friends
            </button>
          </div>

          <main class="flex min-h-0 flex-1 flex-col gap-8 p-4">
            <section class="shrink-0">
              <h3 class="small-caps opacity-60">Online now</h3>

              <ul class="flex flew-wrap gap-2">
                <li :for={{_pid, member} <- @members}>
                  <HappenWeb.Components.Badge.render member={member} />
                </li>
              </ul>
            </section>

            <section class="flex min-h-0 flex-1 flex-col gap-2">
              <h3 :if={@messages |> length() > 0} class="small-caps opacity-60">Messages</h3>
              <HappenWeb.Sections.Messages.render messages={@messages} />
            </section>
          </main>
        </div>

        <script :type={Phoenix.LiveView.ColocatedHook} name=".CopyRoomInvitation">
          export default {
            mounted() {
              this.handleEvent("copy-room-invitation-url", ({url}) => {
                if (!navigator.clipboard) {
                  this.pushEvent("room-clipboard-result", {success: false})
                  return
                }

                navigator.clipboard.writeText(url)
                  .then(() => this.pushEvent("room-clipboard-result", {success: true}))
                  .catch(() => this.pushEvent("room-clipboard-result", {success: false}))
              })
            }
          }
        </script>
      </Layouts.app>
    <% else %>
      <Layouts.app mode="centered" flash={@flash}>
        <.form
          for={@member_form}
          id="member-join-form"
          class="grid gap-2"
          phx-submit="join"
        >
          <.input
            field={@member_form[:name]}
            id="member-name-input"
            phx-mounted={JS.focus()}
            placeholder="How should we call you?"
          />
          <.button>Join room</.button>
        </.form>
      </Layouts.app>
    <% end %>
    """
  end

  defp member_name_changeset(params) do
    {%{}, %{name: :string}}
    |> Ecto.Changeset.cast(params, [:name])
    |> Ecto.Changeset.validate_required([:name])
    |> Ecto.Changeset.validate_length(:name, min: 3, message: "min %{count} chars")
    |> Ecto.Changeset.validate_length(:name, max: 12, message: "max %{count} chars")
  end

  defp active_invitations(:admin), do: enabled_invitations()
  defp active_invitations(_access_kind), do: []

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
