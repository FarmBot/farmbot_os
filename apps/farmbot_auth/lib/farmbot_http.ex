defmodule Farmbot.HTTP do
  @moduledoc """
    Shortcuts to Http Client because im Lazy.
  """
  alias Farmbot.Auth
  alias Farmbot.Token
  use HTTPoison.Base

  @version Mix.Project.config[:version]
  @target Mix.Project.config[:target]
  @ssl_hack [{:versions, [:'tlsv1.2']}]

  @type http_resp :: HTTPoison.Response.t |{:error, HTTPoison.ErrorResponse.t}

  def process_url(url) do
    {:ok, server} = fetch_server()
    server <> url
  end

  def process_request_headers(_headers) do
    {:ok, auth_headers} = build_auth()
    auth_headers
  end

  def process_request_options(opts), do: opts |> Keyword.put(:ssl, @ssl_hack)

  defp build_auth do
    with {:ok, %Token{} = token} <- Auth.get_token
    do
      {:ok,
        ["Content-Type": "application/json",
         "User-Agent": "FarmbotOS/#{@version} (#{@target}) #{@target} ()",
         "Authorization": "Bearer " <> token.encoded]}
    else
      _ -> {:error, :no_token}
    end
  end

  defp fetch_server do
    case Auth.get_server do
      {:ok, nil} -> {:error, :no_server}
      {:ok, server} -> {:ok, server}
    end
  end
end
