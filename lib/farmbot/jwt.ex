defmodule Farmbot.Jwt do
  @moduledoc "Functions for dealing with the Farmbot JSON Web Token"

  defstruct [
    :bot,
    :exp,
    :iss,
    :mqtt,
    :os_update_server
  ]

  @typedoc "Type def for Farmbot Web Token."
  @type t :: %__MODULE__{
          bot: binary,
          exp: number,
          iss: binary,
          mqtt: binary,
          os_update_server: binary
        }

  @doc "Decode a token."
  @spec decode(binary) :: {:ok, t} | {:error, term}
  def decode(tkn) do
    body = tkn |> String.split(".") |> Enum.at(1)

    with {:ok, json} <- Base.decode64(body, padding: false),
         {:ok, jwt} <- Poison.decode(json, as: %__MODULE__{}),
         do: {:ok, jwt}
  end

  @doc "Decodes a token, raises if it fails."
  @spec decode!(binary) :: t | no_return
  def decode!(tkn) do
    case decode(tkn) do
      {:ok, tkn} -> tkn
      :error -> raise "Failed to base64 decode."
      {:error, {:invalid, _char, _pos}} -> raise "Failed to json decode."
    end
  end
end
