defmodule HappenWeb.ExperimentsLive.Messages do
  use HappenWeb, :live_view

  alias HappenWeb.ExperimentsLive
  alias HappenWeb.ExperimentsLive.Messages.Store

  def on_mount(_params, _session, socket) do
    socket
    |> assign_stream()
    |> assign(messages: %{ttl: Store.ttl()})
    |> assign_form()
    |> subscribe()
  end

  defp assign_stream(socket) do
    room_name = socket.assigns.room.data.name
    messages = Store.list_messages(room_name) |> Enum.reverse()
    socket |> stream(:messages, messages)
  end

  defp assign_form(socket, body \\ "") do
    form = %{"body" => body}
    socket |> update(:messages, &Map.put(&1, :form, to_form(form)))
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
    socket |> stream_delete_by_dom_id(:messages, "messages-#{message_id}")
  end

  attr :form, :map, required: true
  attr :stream, :list, required: true
  attr :ttl, :integer, required: true

  def render(assigns) do
    ~H"""
    <div class="space-y-2">
      <.form
        for={@form}
        id="message-body-form"
        phx-change="messages:change"
        phx-submit="messages:add"
      >
        <.input
          autocomplete="off"
          field={@form[:body]}
          placeholder="Say something"
          required
          phx-mounted={JS.focus()}
          class="input input-info w-full"
        />
      </.form>

      <ul
        id="messages"
        phx-update="stream"
        class="space-y-1"
        style={"--message-ttl: #{@ttl}s"}
      >
        <li
          :for={{id, message} <- @stream}
          id={id}
          class={["fade-out bg-base-200 rounded-box px-4 py-2"]}
        >
          <div class="float-right"><ExperimentsLive.User.badge user={message.user} /></div>
          <div class="text-base-content/75">{message.body}</div>
        </li>
      </ul>
    </div>
    """
  end
end
