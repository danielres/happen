defmodule HappenWeb.ExperimentsLive.User do
  use HappenWeb, :html

  def on_mount(_params, session, socket) do
    user =
      case session do
        %{"guest_id" => guest_id, "guest_name" => name, "guest_since" => since} ->
          %{id: guest_id, name: name, hue: 140, since: since}

        _ ->
          nil
      end

    form = to_form(%{"name" => ""}, as: :guest)

    socket
    |> assign(user: %{data: user, form: form})
  end

  def form(assigns) do
    ~H"""
    <Phoenix.Component.form
      for={@form}
      id="guest-name-form"
      action={~p"/guest"}
      method="post"
      class="grid"
    >
      <.input
        field={@form[:name]}
        placeholder="How should we call you?"
        required
        phx-mounted={JS.focus()}
      />

      <input
        type="hidden"
        name="guest[room_name]"
        value={@room.key}
      />

      <.button type="submit">Continue</.button>
    </Phoenix.Component.form>
    """
  end

  attr :"data-testid", :string, default: nil
  attr :user, :map, required: true

  def badge(assigns) do
    ~H"""
    <span
      data-testid={assigns[:"data-testid"]}
      class="badge rounded-full"
      style={"background: #{color(@user)}"}
    >
      <span class="text-xs font-semibold opacity-60">{@user.name}</span>
    </span>
    """
  end

  defp color(user), do: "oklch(50% 0.09 #{user.hue})"
end
