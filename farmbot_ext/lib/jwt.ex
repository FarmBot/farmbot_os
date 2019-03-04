defmodule Farmbot.JWT do
  @moduledoc "Functions for dealing with the Farmbot JSON Web Token"

  defstruct [
    :bot,
    :exp,
    :iss,
    :mqtt,
    :vhost,
    :os_update_server,
    :beta_os_update_server,
    :interim_email
  ]

  @typedoc "Type def for Farmbot Web Token."
  @type t :: %__MODULE__{
          bot: binary,
          exp: number,
          iss: binary,
          mqtt: binary,
          os_update_server: binary,
          vhost: binary,
          interim_email: binary
        }

  @doc "Decode a token."
  @spec decode(binary) :: {:ok, t} | {:error, term}
  def decode(tkn) when is_binary(tkn) do
    body = tkn |> String.split(".") |> Enum.at(1)

    with {:ok, json} <- Base.decode64(body, padding: false),
         {:ok, data} <- Farmbot.JSON.decode(json),
         {:ok, jwt} <- decode_map(data) do
      {:ok, jwt}
    else
      :error -> {:error, "base64_decode_fail"}
      {:error, _resson} -> {:error, "json_decode_error"}
    end
  end

  @doc "Decodes a token, raises if it fails."
  @spec decode!(binary) :: t | no_return
  def decode!(tkn) do
    case decode(tkn) do
      {:ok, tkn} -> tkn
      {:error, reason} -> raise(reason)
    end
  end

  defp decode_map(%{} = map) do
    {:ok,
     struct(
       Farmbot.JWT,
       bot: map["bot"],
       exp: map["exp"],
       iss: map["iss"],
       mqtt: map["mqtt"],
       vhost: map["vhost"],
       os_update_server: map["os_update_server"],
       beta_os_update_server: map["beta_os_update_server"],
       interim_email: map["interim_email"]
     )}
  end
end
