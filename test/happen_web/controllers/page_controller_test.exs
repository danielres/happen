defmodule HappenWeb.PageControllerTest do
  use HappenWeb.ConnCase

  test "GET / requires invitation access", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert redirected_to(conn) == ~p"/404"
  end
end
