defmodule HappenWeb.ExperimentsLive.Ideas.Components.Form do
  use HappenWeb, :html

  alias HappenWeb.ExperimentsLive.Ideas.Components
  alias HappenWeb.ExperimentsLive.Ideas.Utils

def render(assigns) do
    ~H"""
    <.form
      for={@form}
      id="idea-body-form"
      phx-change="ideas:change"
      phx-submit="ideas:add"
      phx-click-away="ideas:add_cancel"
      phx-window-keydown="ideas:add_cancel"
      phx-key="Escape"
      class="mb-2"
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
          phx-mounted={JS.focus()}
        />
        <button class="btn btn-square btn-info btn-soft h-full">
          <.icon name="hero-check-micro" />
        </button>
      </label>
    </.form>
    """
  end
  
end
