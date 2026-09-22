defmodule HappenWeb.Sections.Messages do
  use HappenWeb, :html

  attr :messages, :list, required: true

  def render(assigns) do
    ~H"""
    <HappenWeb.Sections.Messages.List.render messages={@messages} />
    <HappenWeb.Sections.Messages.Form.render />
    """
  end
end
