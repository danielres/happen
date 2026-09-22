defmodule Happen.Accounts.InvitationToken do
  @salt "happen invitation token"

  def generate do
    token =
      32
      |> :crypto.strong_rand_bytes()
      |> Base.url_encode64(padding: false)

    %{
      ciphertext: Plug.Crypto.encrypt(secret_key_base(), @salt, token, max_age: :infinity),
      hash: hash(token)
    }
  end

  def decrypt(ciphertext) do
    Plug.Crypto.decrypt(secret_key_base(), @salt, ciphertext, max_age: :infinity)
  end

  def hash(token) do
    token
    |> then(&:crypto.hash(:sha256, &1))
    |> Base.url_encode64(padding: false)
  end

  defp secret_key_base do
    :happen
    |> Application.fetch_env!(HappenWeb.Endpoint)
    |> Keyword.fetch!(:secret_key_base)
  end
end
