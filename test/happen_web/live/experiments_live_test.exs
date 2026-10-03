defmodule HappenWeb.ExperimentsLiveTest do
  use HappenWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias HappenWeb.ExperimentsLive.Ideas.Store, as: IdeasStore

  test "delegates message form events and store broadcasts", %{conn: conn} do
    room_name = "messages-#{System.unique_integer([:positive])}"

    conn =
      init_test_session(conn, %{
        "guest_id" => Ash.UUID.generate(),
        "guest_name" => "Test guest",
        "guest_since" => DateTime.now!("Etc/UTC")
      })

    {:ok, view, _html} = live(conn, ~p"/ex/#{room_name}")

    view
    |> form("#messages-body-form", %{"body" => "Hello"})
    |> render_change()

    view
    |> form("#messages-body-form", %{"body" => "Hello"})
    |> render_submit()

    assert has_element?(view, "[data-testid='messages-count']", "1")
    assert has_element?(view, "#messages > li")
    assert has_element?(view, "#messages-body-form input[value='']")
  end

  test "delegates nested idea tools events", %{conn: conn} do
    room_name = "idea-tools-#{System.unique_integer([:positive])}"

    conn =
      init_test_session(conn, %{
        "guest_id" => Ash.UUID.generate(),
        "guest_name" => "Test guest",
        "guest_since" => DateTime.now!("Etc/UTC")
      })

    {:ok, view, _html} = live(conn, ~p"/ex/#{room_name}")

    refute has_element?(view, "[data-testid='ideas-tools-panel']")

    view
    |> element("[data-testid='ideas-tools-button']")
    |> render_click()

    assert has_element?(view, "[data-testid='ideas-tools-panel']")
    assert has_element?(view, "[data-testid='ideas-tools-track'].translate-x-0")

    assert has_element?(
             view,
             "[data-testid='ideas-tools-reset-all-votes'][disabled]"
           )

    assert has_element?(
             view,
             "[data-testid='ideas-tools-remove-unpopular-ideas'][disabled]"
           )

    assert has_element?(
             view,
             "[data-testid='ideas-tools-remove-all-ideas'][disabled]"
           )

    view
    |> element("[data-testid='ideas-tools-button']")
    |> render_click()

    refute has_element?(view, "[data-testid='ideas-tools-panel']")
  end

  test "assigns room hues to the current users' header badges", %{conn: conn} do
    room_name = "hues-#{System.unique_integer([:positive])}"
    since = DateTime.now!("Etc/UTC")
    first_guest_id = Ash.UUID.generate()

    first_conn =
      init_test_session(conn, %{
        "guest_id" => first_guest_id,
        "guest_name" => "First guest",
        "guest_since" => since
      })

    second_conn =
      Phoenix.ConnTest.build_conn()
      |> init_test_session(%{
        "guest_id" => Ash.UUID.generate(),
        "guest_name" => "Second guest",
        "guest_since" => DateTime.add(since, 1, :second)
      })

    {:ok, first_view, _html} = live(first_conn, ~p"/ex/#{room_name}")
    {:ok, second_view, _html} = live(second_conn, ~p"/ex/#{room_name}")

    assert has_element?(first_view, "[data-testid='presences-count']", "2")
    assert has_element?(second_view, "[data-testid='presences-count']", "2")
    assert has_element?(first_view, "[data-testid='current-user-badge'][style*='40']")
    assert has_element?(second_view, "[data-testid='current-user-badge'][style*='220']")
  end

  test "delegates the leave event through presences", %{conn: conn} do
    room_name = "leave-#{System.unique_integer([:positive])}"

    conn =
      init_test_session(conn, %{
        "guest_id" => Ash.UUID.generate(),
        "guest_name" => "Test guest",
        "guest_since" => DateTime.now!("Etc/UTC")
      })

    {:ok, view, _html} = live(conn, ~p"/ex/#{room_name}")

    view
    |> element("[data-testid='presences-leave']")
    |> render_click()

    assert_redirect(view, ~p"/guest/logout")
  end

  test "adds an idea and toggles the current user's vote", %{conn: conn} do
    room_name = "ideas-#{System.unique_integer([:positive])}"

    conn =
      init_test_session(conn, %{
        "guest_id" => Ash.UUID.generate(),
        "guest_name" => "Test guest",
        "guest_since" => DateTime.now!("Etc/UTC")
      })

    second_conn =
      Phoenix.ConnTest.build_conn()
      |> init_test_session(%{
        "guest_id" => Ash.UUID.generate(),
        "guest_name" => "Second guest",
        "guest_since" => DateTime.now!("Etc/UTC")
      })

    {:ok, view, _html} = live(conn, ~p"/ex/#{room_name}")
    {:ok, second_view, _html} = live(second_conn, ~p"/ex/#{room_name}")

    view
    |> form("#ideas-body-form", %{"body" => "Make it happen"})
    |> render_submit()

    assert has_element?(view, "[data-testid='ideas-list'] > [data-testid^='idea-']")
    assert has_element?(view, "[data-testid^='ideas-upvote-'][aria-pressed='false']")

    view
    |> element("[data-testid^='ideas-upvote-']")
    |> render_click()

    assert has_element?(view, "[data-testid^='ideas-upvote-'][aria-pressed='true']")
    assert has_element?(view, "[data-testid^='idea-voters-']", "Upvotes:")

    view
    |> element("[data-testid='ideas-tools-button']")
    |> render_click()

    assert has_element?(view, "[data-testid='ideas-tools-reset-all-votes']")

    refute has_element?(
             view,
             "[data-testid='ideas-tools-reset-all-votes'][disabled]"
           )

    assert has_element?(
             view,
             "[data-testid='ideas-tools-remove-unpopular-ideas'][disabled]"
           )

    refute has_element?(
             view,
             "[data-testid='ideas-tools-remove-all-ideas'][disabled]"
           )

    view
    |> element("[data-testid='ideas-tools-reset-all-votes']")
    |> render_click()

    assert has_element?(view, "[data-testid='ideas-tools-track'].-translate-x-full")
    assert has_element?(view, "[data-testid='ideas-tools-panel']", "Are you sure?")

    view
    |> element("[data-testid='ideas-tools-reset-all-votes-confirm']")
    |> render_click()

    refute has_element?(view, "[data-testid='ideas-tools-panel']")
    assert has_element?(view, "[data-testid^='ideas-upvote-'][aria-pressed='false']")

    assert has_element?(
             view,
             "#toast-group .toast-info",
             "Votes have been reset by Test guest"
           )

    assert has_element?(view, "#toast-group[data-theme='inherit']")

    assert has_element?(
             second_view,
             "#toast-group .toast-info",
             "Votes have been reset by Test guest"
           )

    view
    |> element("[data-testid='ideas-tools-button']")
    |> render_click()

    assert has_element?(
             view,
             "[data-testid='ideas-tools-reset-all-votes'][disabled]"
           )

    view
    |> element("[data-testid='ideas-tools-button']")
    |> render_click()

    view
    |> element("[data-testid^='ideas-downvote-']")
    |> render_click()

    view
    |> element("[data-testid='ideas-tools-button']")
    |> render_click()

    refute has_element?(
             view,
             "[data-testid='ideas-tools-remove-unpopular-ideas'][disabled]"
           )
  end

  test "sorts ideas by score", %{conn: conn} do
    room_name = "sorted-ideas-#{System.unique_integer([:positive])}"
    author = %{id: Ash.UUID.generate(), name: "Author", hue: 40}

    conn =
      init_test_session(conn, %{
        "guest_id" => Ash.UUID.generate(),
        "guest_name" => "Test guest",
        "guest_since" => DateTime.now!("Etc/UTC")
      })

    {:ok, view, _html} = live(conn, ~p"/ex/#{room_name}")

    first_idea = IdeasStore.add_idea(room_name, author, "First idea")
    second_idea = IdeasStore.add_idea(room_name, author, "Second idea")

    assert has_element?(view, "[data-testid='ideas-count']", "2")

    assert has_element?(
             view,
             "[data-testid='ideas-list'] > [data-testid='idea-#{second_idea.id}']:first-child"
           )

    voter = %{id: Ash.UUID.generate(), name: "Voter", hue: 220}

    assert {:ok, _idea} = IdeasStore.vote(room_name, first_idea.id, voter, :up)

    assert has_element?(
             view,
             "[data-testid='ideas-list'] > [data-testid='idea-#{first_idea.id}']:first-child"
           )
  end
end
