defmodule Farmbot.HTTP do
  @moduledoc """
    Shortcuts to HTTPOtion because im Lazy.
  """
  alias Farmbot.Auth
  alias Farmbot.Token

  @type http_resp :: HTTPotion.Response.t | HTTPotion.ErrorResponse.t

  @doc """
    POST request to the Farmbot Web Api
  """
  @spec post(binary, binary) :: {:error, term} | http_resp
  def post(path, body) do
    with {:ok, server} <- fetch_server,
         {:ok, auth_headers} <- build_auth,
         do: HTTPotion.post("#{server}#{path}",
                            headers: auth_headers, body: body)
  end

  @doc """
    GET request to the Farmbot Web Api
  """
  @spec get(binary) :: {:error, term} | http_resp
  def get(path) do
    with {:ok, server} <- fetch_server,
         {:ok, auth_headers} <- build_auth,
         do: HTTPotion.get("#{server}#{path}", headers: auth_headers)
  end

  @doc """
    Builds a HTTP request.
  """
  @type verbs ::
    :get
    | :post
    | :put
    | :delete
  @spec req(verbs, binary, any) :: http_resp
  def req(verb, path, body \\ nil) do
    with {:ok, server} <- fetch_server,
         {:ok, auth_headers} <- build_auth
    do
      options = [headers: auth_headers]
      if body do
        options_with_body = Keyword.put(options, :body, body)
        HTTPotion.request(verb, "#{server}#{path}", options_with_body)
      else
        HTTPotion.request(verb, "#{server}#{path}", options)
      end
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
