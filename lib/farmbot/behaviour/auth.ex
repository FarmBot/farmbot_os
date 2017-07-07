defmodule Farmbot.Behaviour.Auth do
  @moduledoc "Farmbot Auth GenServer behaviour."

  @typedoc """
    The public key that lives at http://<server>/api/public_key
  """
  @type public_key :: binary

  @typedoc "Encrypted secret."
  @type secret :: binary

  @typedoc "Server auth is connected to."
  @type server :: binary

  @typedoc "Password binary"
  @type password :: binary

  @typedoc "Email binary"
  @type email :: binary

  @typedoc "Interim credentials."
  @type interim :: {email, password, server}

  @callback get_public_key(context, server) :: :ok

  @typedoc false
  @type context :: Farmbot.Behaviour.Types.context
  @typedoc "Server for Farmbot.Context"
  @type otp_server :: GenServer.server

  @doc "start_link for OTP"
  @callback start_link(context, GenServer.options) :: GenServer.on_start
end
