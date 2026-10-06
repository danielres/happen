defmodule HappenWeb.HomeLive do
  use HappenWeb, :live_view

  alias Ecto.Changeset
  alias Happen.RoomKey

  @room_types %{name: :string}

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    form = %{} |> room_changeset() |> to_form(as: :room)
    {:ok, assign(socket, :form, form)}
  end

  @impl Phoenix.LiveView
  def handle_event("validate", %{"room" => params}, socket) do
    action = socket.assigns.form.source.action

    form =
      params
      |> room_changeset()
      |> Map.put(:action, action)
      |> to_form(as: :room)

    {:noreply, assign(socket, :form, form)}
  end

  @impl Phoenix.LiveView
  def handle_event("open_room", %{"room" => params}, socket) do
    case params |> room_changeset() |> Changeset.apply_action(:insert) do
      {:ok, %{name: room_name}} ->
        room_key = RoomKey.encode(room_name)
        {:noreply, push_navigate(socket, to: ~p"/#{room_key}")}

      {:error, changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset, as: :room))}
    end
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <Layouts.app mode="centered" flash={@flash}>
      <div class="bg-base-200 p-4 rounded-box max-w-sm">
        <.form
          for={@form}
          id="room-form"
          data-testid="room-form"
          phx-change="validate"
          phx-submit="open_room"
          class="grid"
        >
          <.input
            data-testid="room-name"
            class="input input-info w-full"
            field={@form[:name]}
            placeholder="Enter a room name"
            autocomplete="off"
            phx-hook="CapitalizeFirstLetter"
            phx-mounted={JS.focus()}
            required
          />

          <.button
            class="btn btn-info btn-soft"
            disabled={!@form.source.valid?}
            type="submit"
          >
            Enter room
          </.button>
        </.form>
      </div>
    </Layouts.app>
    """
  end

  defp room_changeset(params) do
    params =
      Map.update(params, "name", "", fn
        name when is_binary(name) -> String.trim(name)
        name -> name
      end)

    {%{}, @room_types}
    |> Changeset.cast(params, Map.keys(@room_types))
    |> Changeset.validate_required([:name])
    |> Changeset.validate_length(:name, min: 4, message: "min 4 chars")
    |> Changeset.validate_length(:name, max: 16, message: "max 16 chars")
  end
end
