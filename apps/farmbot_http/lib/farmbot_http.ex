defmodule Farmbot.HTTP do
  @moduledoc """
    Shortcuts to Http Client because im Lazy.
  """
  alias Farmbot.Auth
  alias Farmbot.Token

  @version Mix.Project.config[:version]
  @target Mix.Project.config[:target]

  @type http_resp :: HTTPoison.Response.t |{:error, HTTPoison.ErrorResponse.t}

  @doc """
    POST request to the Farmbot Web Api
  """
  @spec post(binary, binary) :: {:error, term} | http_resp
  def post(path, body) do
    with {:ok, server} <- fetch_server(),
         {:ok, auth_headers} <- build_auth(),
         do: HTTPoison.post("#{server}#{path}", body, auth_headers)
  end

  @doc """
    GET request to the Farmbot Web Api
  """
  @spec get(binary) :: {:error, term} | http_resp
  def get(path) do
    with {:ok, server} <- fetch_server(),
         {:ok, auth_headers} <- build_auth(),
         do: HTTPoison.get("#{server}#{path}", auth_headers)
  end

  @doc """
    Builds a HTTP request.
  """
  @type verbs ::
    :get
    | :post
    | :put
    | :delete
  @spec req(verbs, binary, binary) :: http_resp
  def req(verb, path, body \\ "") do
    with {:ok, server} <- fetch_server(),
         {:ok, auth_headers} <- build_auth()
    do
      HTTPoison.request verb, "#{server}#{path}", body, [headers: auth_headers]
    end
  end

  @doc """
    Short cut for getting a path and piping it thro Poison.decode.
  """
  @spec get_to_json(binary) :: map
  def get_to_json(path), do: path |> get |> Map.get(:body) |> Poison.decode!

  @type headers :: ["Content-Type": String.t, "Authorization": String.t]
  @spec build_auth :: {:ok, headers} | {:error, term}
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
