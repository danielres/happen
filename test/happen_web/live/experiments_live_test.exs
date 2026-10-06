defmodule HappenWeb.RoomLiveTest do
  use HappenWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Happen.Accounts
  alias Happen.RoomKey
  alias HappenWeb.RoomLive.Ideas.Store, as: IdeasStore
  alias HappenWeb.RoomLive.Messages.Store, as: MessagesStore

  setup do
    {:ok, invitation} = Accounts.create_invitation()
    %{invitation_id: invitation.id}
  end

  test "decodes the room key into the room name", %{conn: conn, invitation_id: invitation_id} do
    room_name = "Café room"

    conn =
      invitation_session(conn, invitation_id, %{
        "guest_id" => Ash.UUID.generate(),
        "guest_name" => "Test guest",
        "guest_since" => DateTime.now!("Etc/UTC")
      })

    {:ok, view, _html} = live(conn, room_path(room_name))

    assert has_element?(view, "[data-testid='room-name']", room_name)
  end

  test "redirects malformed room keys to the room form", %{
    conn: conn,
    invitation_id: invitation_id
  } do
    room_form_path = ~p"/"
    conn = invitation_session(conn, invitation_id)

    assert {:error, {:redirect, %{to: ^room_form_path}}} = live(conn, "/invalid!")
  end

  test "preserves the room key when creating a guest session", %{
    conn: conn,
    invitation_id: invitation_id
  } do
    room_key = RoomKey.encode("Café room")
    conn = invitation_session(conn, invitation_id)

    {:ok, view, _html} = live(conn, ~p"/#{room_key}")

    assert has_element?(
             view,
             "#guest-name-form input[name='guest[room_name]'][value='#{room_key}']"
           )
  end

  test "delegates message form events and store broadcasts", %{
    conn: conn,
    invitation_id: invitation_id
  } do
    room_name = "messages-#{System.unique_integer([:positive])}"

    conn =
      invitation_session(conn, invitation_id, %{
        "guest_id" => Ash.UUID.generate(),
        "guest_name" => "Test guest",
        "guest_since" => DateTime.now!("Etc/UTC")
      })

    {:ok, view, _html} = live(conn, room_path(room_name))

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

  test "shows only the latest message notification outside the messages tab", %{
    conn: conn,
    invitation_id: invitation_id
  } do
    room_name = "notifications-#{System.unique_integer([:positive])}"

    observer_conn =
      invitation_session(conn, invitation_id, %{
        "guest_id" => Ash.UUID.generate(),
        "guest_name" => "Observer",
        "guest_since" => DateTime.now!("Etc/UTC")
      })

    author_conn =
      Phoenix.ConnTest.build_conn()
      |> invitation_session(invitation_id, %{
        "guest_id" => Ash.UUID.generate(),
        "guest_name" => "Author",
        "guest_since" => DateTime.now!("Etc/UTC")
      })

    {:ok, observer_view, _html} = live(observer_conn, room_path(room_name))
    {:ok, author_view, _html} = live(author_conn, room_path(room_name))

    author_view
    |> form("#messages-body-form", %{"body" => "First message"})
    |> render_submit()

    [first_message] = MessagesStore.list_messages(room_name)

    assert has_element?(
             observer_view,
             "[data-testid='message-notification']",
             "First message"
           )

    assert has_element?(
             observer_view,
             "[data-testid='message-notification-trigger'].tooltip-open"
           )

    assert has_element?(
             observer_view,
             "[data-testid='message-notification']",
             "Author"
           )

    author_view
    |> form("#messages-body-form", %{"body" => "Second message"})
    |> render_submit()

    second_message = MessagesStore.list_messages(room_name) |> List.last()

    refute has_element?(
             observer_view,
             "[data-testid='message-notification']",
             "First message"
           )

    assert has_element?(
             observer_view,
             "[data-testid='message-notification']",
             "Second message"
           )

    send(observer_view.pid, {:messages, {:notification, {:dismiss, first_message.id}}})
    _ = :sys.get_state(observer_view.pid)

    assert has_element?(
             observer_view,
             "[data-testid='message-notification']",
             "Second message"
           )

    send(observer_view.pid, {:messages, {:notification, {:dismiss, second_message.id}}})
    _ = :sys.get_state(observer_view.pid)

    assert has_element?(observer_view, "[data-testid='message-notification']", "Second message")

    refute has_element?(
             observer_view,
             "[data-testid='message-notification-trigger'].tooltip-open"
           )

    send(observer_view.pid, {:messages, {:notification, {:clear, second_message.id}}})
    _ = :sys.get_state(observer_view.pid)

    refute has_element?(observer_view, "[data-testid='message-notification']")

    author_view
    |> form("#messages-body-form", %{"body" => "Third message"})
    |> render_submit()

    assert has_element?(observer_view, "[data-testid='message-notification']")
    third_message = MessagesStore.list_messages(room_name) |> List.last()

    observer_view
    |> element("[data-testid='messages-tab']")
    |> render_click()

    refute has_element?(
             observer_view,
             "[data-testid='message-notification-trigger'].tooltip-open"
           )

    send(observer_view.pid, {:messages, {:notification, {:clear, third_message.id}}})
    _ = :sys.get_state(observer_view.pid)

    refute has_element?(observer_view, "[data-testid='message-notification']")

    author_view
    |> form("#messages-body-form", %{"body" => "Fourth message"})
    |> render_submit()

    refute has_element?(observer_view, "[data-testid='message-notification']")

    refute has_element?(
             observer_view,
             "[data-testid='message-notification-trigger'].tooltip-open"
           )
  end

  test "delegates nested idea tools events", %{conn: conn, invitation_id: invitation_id} do
    room_name = "idea-tools-#{System.unique_integer([:positive])}"

    conn =
      invitation_session(conn, invitation_id, %{
        "guest_id" => Ash.UUID.generate(),
        "guest_name" => "Test guest",
        "guest_since" => DateTime.now!("Etc/UTC")
      })

    {:ok, view, _html} = live(conn, room_path(room_name))

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

  test "assigns room hues to the current users' header badges", %{
    conn: conn,
    invitation_id: invitation_id
  } do
    room_name = "hues-#{System.unique_integer([:positive])}"
    since = DateTime.now!("Etc/UTC")
    first_guest_id = Ash.UUID.generate()

    first_conn =
      invitation_session(conn, invitation_id, %{
        "guest_id" => first_guest_id,
        "guest_name" => "First guest",
        "guest_since" => since
      })

    second_conn =
      Phoenix.ConnTest.build_conn()
      |> invitation_session(invitation_id, %{
        "guest_id" => Ash.UUID.generate(),
        "guest_name" => "Second guest",
        "guest_since" => DateTime.add(since, 1, :second)
      })

    {:ok, first_view, _html} = live(first_conn, room_path(room_name))
    {:ok, second_view, _html} = live(second_conn, room_path(room_name))

    assert has_element?(first_view, "[data-testid='presences-count']", "2")
    assert has_element?(second_view, "[data-testid='presences-count']", "2")
    assert has_element?(first_view, "[data-testid='current-user-badge'][style*='40']")
    assert has_element?(second_view, "[data-testid='current-user-badge'][style*='220']")
  end

  test "delegates the leave event through presences", %{
    conn: conn,
    invitation_id: invitation_id
  } do
    room_name = "leave-#{System.unique_integer([:positive])}"

    conn =
      invitation_session(conn, invitation_id, %{
        "guest_id" => Ash.UUID.generate(),
        "guest_name" => "Test guest",
        "guest_since" => DateTime.now!("Etc/UTC")
      })

    {:ok, view, _html} = live(conn, room_path(room_name))

    view
    |> element("[data-testid='presences-leave']")
    |> render_click()

    assert_redirect(view, ~p"/guest/logout")
  end

  test "adds an idea and toggles the current user's vote", %{
    conn: conn,
    invitation_id: invitation_id
  } do
    room_name = "ideas-#{System.unique_integer([:positive])}"

    conn =
      invitation_session(conn, invitation_id, %{
        "guest_id" => Ash.UUID.generate(),
        "guest_name" => "Test guest",
        "guest_since" => DateTime.now!("Etc/UTC")
      })

    second_conn =
      Phoenix.ConnTest.build_conn()
      |> invitation_session(invitation_id, %{
        "guest_id" => Ash.UUID.generate(),
        "guest_name" => "Second guest",
        "guest_since" => DateTime.now!("Etc/UTC")
      })

    {:ok, view, _html} = live(conn, room_path(room_name))
    {:ok, second_view, _html} = live(second_conn, room_path(room_name))

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

  test "sorts ideas by score", %{conn: conn, invitation_id: invitation_id} do
    room_name = "sorted-ideas-#{System.unique_integer([:positive])}"
    author = %{id: Ash.UUID.generate(), name: "Author", hue: 40}

    conn =
      invitation_session(conn, invitation_id, %{
        "guest_id" => Ash.UUID.generate(),
        "guest_name" => "Test guest",
        "guest_since" => DateTime.now!("Etc/UTC")
      })

    {:ok, view, _html} = live(conn, room_path(room_name))

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

  defp invitation_session(conn, invitation_id, session \\ %{}) do
    init_test_session(conn, Map.put(session, "invitation_id", invitation_id))
  end

  defp room_path(room_name), do: ~p"/#{RoomKey.encode(room_name)}"
end
