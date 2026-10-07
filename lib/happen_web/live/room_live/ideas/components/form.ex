defmodule HappenWeb.RoomLive.Ideas.Components.Form do
  use HappenWeb, :html
  use LiveDelegate, path: [:ideas]

  attr :form, :map, required: true

  def render(assigns) do
    ~H"""
    <.form
      for={@form}
      id={delegate_dom_id("body-form")}
      phx-change={delegate_event("change")}
      phx-click-away={delegate_event("add_cancel")}
      phx-key="Escape"
      phx-submit={delegate_event("add")}
      phx-window-keydown={delegate_event("add_cancel")}
    >
      <label class="input input-info pr-0 w-full">
        <input
          type="text"
          autocomplete="off"
          name={@form[:body].name}
          value={Phoenix.HTML.Form.normalize_value("text", @form[:body].value)}
          placeholder="Suggest an idea"
          required
          class="grow"
        />
        <button class="btn btn-square btn-info btn-soft h-full">
          <.icon name="hero-check-micro" />
        </button>
      </label>
    </.form>
    """
  end
end
