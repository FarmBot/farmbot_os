defmodule Farmbot.Lib.Helpers do
  @moduledoc """
    Helper Functions/Macros for common things.
  """

  @doc """
    Helper for checking if a binary is a uuid.
  """
  def uuid?(uuid) do
    match?(
      <<
        _::size(64),
        <<45>>,
        _::size(32),
        <<45>>,
        _::size(32),
        <<45>>,
        _::size(32),
        <<45>>,
        _::size(96)
      >>,
      uuid
    )
  end

  @doc """
    Checks if a binary is 36 bytes.
  """
  defmacro is_uuid(uuid) do
    quote do
      byte_size(unquote(uuid)) == 36
    end
  end
end
