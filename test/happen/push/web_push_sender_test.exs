defmodule Happen.Push.WebPushSenderTest do
  use ExUnit.Case, async: false

  alias Happen.Push.Subscription
  alias Happen.Push.WebPushSender

  setup {Req.Test, :verify_on_exit!}

  setup do
    previous_sender = Application.get_env(:happen, WebPushSender)
    previous_vapid = Application.get_env(:web_push_ex, :vapid)
    {public_key, private_key} = :crypto.generate_key(:ecdh, :prime256v1)

    Application.put_env(:happen, WebPushSender,
      req_options: [plug: {Req.Test, __MODULE__}]
    )

    Application.put_env(:web_push_ex, :vapid,
      private_key: WebPushEx.encode(private_key),
      public_key: WebPushEx.encode(public_key),
      subject: "mailto:push@example.com"
    )

    on_exit(fn ->
      restore_env(:happen, WebPushSender, previous_sender)
      restore_env(:web_push_ex, :vapid, previous_vapid)
    end)
  end

  test "sends encrypted notification data with redirects and retries disabled" do
    Req.Test.expect(__MODULE__, fn conn ->
      assert conn.method == "POST"
      assert Plug.Conn.get_req_header(conn, "content-encoding") == ["aes128gcm"]
      assert Plug.Conn.get_req_header(conn, "authorization") |> List.first() =~ "vapid t="
      assert Req.Test.raw_body(conn) != ""
      Plug.Conn.send_resp(conn, 201, "")
    end)

    assert :ok = WebPushSender.send(subscription("active"), %{title: "Room", body: "Hello"})
  end

  test "marks gone endpoints as expired" do
    Req.Test.expect(__MODULE__, fn conn -> Plug.Conn.send_resp(conn, 410, "") end)

    assert :expired =
             WebPushSender.send(subscription("expired"), %{title: "Room", body: "Hello"})
  end

  defp subscription(name) do
    {public_key, _private_key} = :crypto.generate_key(:ecdh, :prime256v1)

    %Subscription{
      endpoint: "https://fcm.googleapis.com/fcm/send/#{name}",
      auth: Base.url_encode64(:crypto.strong_rand_bytes(16), padding: false),
      p256dh: Base.url_encode64(public_key, padding: false)
    }
  end

  defp restore_env(app, key, nil), do: Application.delete_env(app, key)
  defp restore_env(app, key, value), do: Application.put_env(app, key, value)
end
