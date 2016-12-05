defmodule Farmbot.HTTP do
  @moduledoc """
    Shortcuts to HTTPOtion because im Lazy.
  """

  @type http_resp :: HTTPotion.Response.t | HTTPotion.ErrorResponse.t

  @doc """
    POST request to the Farmbot Web Api
  """
  @spec post(binary, binary) :: {:error, term} | http_resp
  def post(path, body) do
    with {:ok, server} <- fetch_server,
         {:ok, auth_headers} <- build_auth,
         do: HTTPotion.post("#{server}#{path}", headers: auth_headers, body: body)
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

  @type headers :: ["Content-Type": String.t, "Authorization": String.t]
  @spec build_auth :: {:ok, headers} | {:error, term}
  defp build_auth do
    with {:ok, json_token} <- Farmbot.Auth.get_token,
         {:ok, token} <- Token.create(json_token),
    do:
      {:ok,
        ["Content-Type": "application/json",
         "Authorization": "Bearer " <> token.encoded]}
  end

  defp fetch_server do
    case Farmbot.BotState.get_server do
      nil -> {:error, :no_server}
      server -> {:ok, server}
    end
  end
end
