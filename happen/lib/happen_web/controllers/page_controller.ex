defmodule HappenWeb.PageController do
  use HappenWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
