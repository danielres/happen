defmodule HappenWeb.HomeLive do
  use HappenWeb, :live_view
  alias HappenWeb.Presence

  def mount(_params, _session, socket) do
    form = Happen.Rooms.form_to_create_room()
    {:ok, assign(socket, form: form |> to_form())}
  end

  def handle_event("submit", %{"form" => params}, socket) do
    case AshPhoenix.Form.submit(socket.assigns.form, params: params) do
      {:ok, room} ->
        {:noreply, push_navigate(socket, to: ~p"/r/#{room.id}")}

      {:error, form} ->
        dbg(form)
        {:noreply, assign(socket, :form, form)}
    end
  end

  def handle_event("validate", form, socket) do
    {:noreply, socket}
  end

  def handle_info({:group, _events, _info}, socket) do
    members = Presence.get_members(@room)
    socket = socket |> assign(members: members)
    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <.form for={@form} phx-submit="submit">
      <.input field={@form[:name]} label="Room name" />
      <.button type="submit">submit</.button>
    </.form>
    """
  end
end
