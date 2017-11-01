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
    apply(__MODULE__, fun, [conn, opts])
  end

  def handle_prod(conn, _opts) do
    with [<<_ :: size(8), <<"earer ">>, maybe_token :: binary>>] <- get_req_header(conn, "authorization"),
         [token] <- String.split(maybe_token, ","),
         {:ok, key} <- HTTP.public_key(),
         {true, _, _} <- JOSE.JWT.verify(key, token)
    do
      conn
    else
      # if the JWT failed to verify.
      {false, _, _}    -> send_resp(conn, 401, "unauthorized token.")
      # An error happened verifying.
      {:error, reason} -> send_resp(conn, 400, "token verification error: " <> format_error(reason))
      # The header didn't match the pattern.
      [_auth_header]   -> send_resp(conn, 400, "bad auth header.")
      [_ | _]          -> send_resp(conn, 400, "too many auth headers.")
      []               -> send_resp(conn, 400, "no auth header supplied.")
      # some other problem
      other            -> send_resp(conn, 500, format_error(other))
    end
  end

  def handle_dev(conn, _opts), do: conn
  def handle_test(conn, opts), do: handle_dev(conn, opts)

  defp format_error(err) when is_binary(err), do: err
  defp format_error(err), do: inspect err

end
