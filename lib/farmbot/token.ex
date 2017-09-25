defmodule Farmbot.Token do
  defimpl Inspect, for: __MODULE__ do
    def inspect(dict, _opts) do
      << a :: size(16), _rest :: binary>>  = dict.encoded
      "#Token<#{a}>"
    end
  end

  defmodule Unencoded do
    @moduledoc """
    The unencoded version of the token.
    """

    @type t :: %__MODULE__{
      os_update_server: String.t,

      # Dates for when the token expires and was issued at.
      exp: number,
      iat: number,
      # Bot name for logging into MQTT.
      bot: String.t,

      # Issuer (api server)
      iss: String.t,
      # mqtt broker
      mqtt: String.t,
      # uuid
      jti: String.t,
      # Email
      sub: String.t
    }
    defstruct [:bot,
               :exp,
               :os_update_server,
               :iat,
               :iss,
               :jti,
               :mqtt,
               :sub]
  end
  @moduledoc """
    Token Object
  """
  defstruct [:encoded, :unencoded]
  @type t :: %__MODULE__{
    encoded: binary,
    unencoded: Unencoded.t
  }

  @doc """
    Creates a valid token from json.
  """
  @spec create(map | {:ok, map}) :: {:ok, t} | :not_valid
  def create(%{"encoded" => encoded,
               "unencoded" =>
                %{"bot" => bot,
                  "exp" => exp,
                  "os_update_server" => os_update_server,
                  "iat" => iat,
                  "iss" => iss,
                  "jti" => jti,
                  "mqtt" => mqtt,
                  "sub" => sub}})
  do
    f =
      %__MODULE__{encoded: encoded,
           unencoded: %Unencoded{
             bot: bot,
             exp: exp,
             iat: iat,
             iss: iss,
             jti: jti,
             mqtt: mqtt,
             sub: sub,
             os_update_server: os_update_server
             }}
     {:ok, f}
  end
  def create(_), do: :not_valid
  def create!(thing) do
    case create(thing) do
      {:ok, win} -> win
      fail -> raise "failed to create token: #{inspect fail}"
    end
  end
end
