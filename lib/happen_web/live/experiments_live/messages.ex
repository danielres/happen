defmodule HappenWeb.ExperimentsLive.Messages do
  use HappenWeb, :live_view
  use LiveDelegate, path: [:messages]

  alias HappenWeb.ExperimentsLive
  alias HappenWeb.ExperimentsLive.Messages.Store
  alias ExperimentsLive.User

  def on_mount(_params, _session, socket) do
    socket
    |> delegate_assign(%{ttl: Store.ttl()})
    |> assign_form()
    |> assign_stream()
    |> subscribe()
  end

  defp assign_stream(socket) do
    room_name = socket.assigns.room.data.name
    messages = Store.list_messages(room_name) |> Enum.reverse()
    socket |> stream(:messages, messages)
  end

  defp assign_form(socket, body \\ "") do
    form = %{"body" => body}
    socket |> delegate_assign(:form, to_form(form))
  end

  defp subscribe(socket) do
    if connected?(socket), do: Store.subscribe(socket.assigns.room.data.name)
    socket
  end

  def handle_event("add", %{"body" => body}, socket) do
    room_name = socket.assigns.room.data.name
    user = socket.assigns.user.data
    Store.add_message(room_name, user, body)
    {:noreply, socket |> assign_form()}
  end

  def handle_event("change", %{"body" => body}, socket) do
    {:noreply, socket |> assign_form(body)}
  end

  def handle_info({:added, message}, socket) do
    {:noreply, socket |> stream_insert(message)}
  end

  def handle_info({:deleted, message_id}, socket) do
    {:noreply, socket |> stream_delete_by_id(message_id)}
  end

  defp stream_insert(socket, message) do
    socket |> stream_insert(:messages, message, at: 0, limit: Store.max_count())
  end

  defp stream_delete_by_id(socket, message_id) do
    socket |> stream_delete_by_dom_id(:messages, delegate_dom_id(message_id))
  end

  attr :messages, :map, required: true
  attr :stream, :list, required: true

  def render(assigns) do
    ~H"""
    <div class="space-y-2">
      <.form
        for={@messages.form}
        id={delegate_dom_id("body-form")}
        phx-change={delegate_event("change")}
        phx-submit={delegate_event("add")}
      >
        <.input
          autocomplete="off"
          field={@messages.form[:body]}
          placeholder="Say something"
          required
          phx-mounted={JS.focus()}
          class="input input-info w-full"
        />
      </.form>

      <ul
        id="messages"
        class="space-y-1"
        phx-hook=".MessageFade"
        phx-update="stream"
        style={"--message-ttl: #{@messages.ttl}s"}
      >
        <li
          :for={{id, message} <- @stream}
          id={id}
          class={["fade-out bg-base-200 rounded-box px-4 py-2"]}
          data-created-at={DateTime.to_unix(message.created_at, :millisecond)}
        >
          <div class="float-right"><User.badge user={message.user} /></div>
          <div class="text-base-content/75">{message.body}</div>
        </li>
      </ul>

      <script :type={Phoenix.LiveView.ColocatedHook} name=".MessageFade">
        export default {
          mounted() {
            this.sync = () => {
              this.el.querySelectorAll("[data-created-at]").forEach(message => {
                const age = Math.max(Date.now() - Number(message.dataset.createdAt), 0)
                message.style.setProperty("--message-age", `${age}ms`)
              })
            }

            this.onTabChange = () => this.sync()

            this.sync()
            document.addEventListener("change", this.onTabChange)
          },

          updated() {
            this.sync()
          },

          destroyed() {
            document.removeEventListener("change", this.onTabChange)
          }
        }
      </script>
    </div>
    """
  end
end
