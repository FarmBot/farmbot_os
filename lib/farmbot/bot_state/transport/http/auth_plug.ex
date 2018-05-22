defmodule Farmbot.BotState.Transport.HTTP.AuthPlug do
  @moduledoc "Plug for authorizing local REST access."
  import Plug.Conn
  alias Farmbot.BotState.Transport.HTTP

  @behaviour Plug

  def init(opts) do
    env = Keyword.fetch!(opts, :env)
    Keyword.put(opts, :handler, :"handle_#{env}")
  end

  def call(conn, opts) do
    fun = Keyword.fetch!(opts, :handler)

    case apply(__MODULE__, fun, [conn]) do
      {conn, code, msg} -> send_resp(conn, code, msg)
      conn -> conn
    end
  end

  def handle_prod(conn) do
    req_header = get_req_header(conn, "authorization")

    with [<<_::size(8), <<"earer ">>, maybe_token::binary>>] <- req_header,
         [token] <- String.split(maybe_token, ","),
         {:ok, key} <- HTTP.public_key(),
         {true, _, _} <- JOSE.JWT.verify(key, token) do
      conn
    else
      # An error happened verifying.
      {:error, reason} ->
        {conn, 400, "token verification error: " <> format_error(reason)}

      # if the JWT failed to verify.
      {false, _, _} ->
        {conn, 401, "unauthorized token."}

      # The header didn't match the pattern.
      [_auth_header] ->
        {conn, 400, "bad auth header."}

      [_ | _] ->
        {conn, 400, "too many auth headers."}

      [] ->
        {conn, 400, "no auth header supplied."}

      # some other problem
      other ->
        {conn, 500, format_error(other)}
    end
  end

  def handle_dev(conn), do: conn
  def handle_test(conn), do: handle_dev(conn)

  defp format_error(err) when is_binary(err), do: err
  defp format_error(err), do: inspect(err)
end
