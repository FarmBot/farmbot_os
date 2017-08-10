defmodule Farmbot.Bootstrap.Authorization do
  @moduledoc "Functionality responsible for getting a JWT."

  @typedoc "Email used to configure this bot."
  @type email :: binary

  @typedoc "Password used to configure this bot."
  @type password :: binary

  @typedoc "Server used to configure this bot."
  @type server :: binary

  @typedoc "Token that was fetched with the credentials."
  @type token :: binary

  @doc """
  Callback for an authorization implementation.
  Should return {:ok, token} | {:error, term}
  """
  @callback authorize(email, password, server) :: {:ok, token} | {:error, term}
end
