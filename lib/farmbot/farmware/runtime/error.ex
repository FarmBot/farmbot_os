defmodule Farmbot.Farmware.RuntimeError do
  @moduledoc """
    Farmware RuntimeError
  """
  defexception [:message]

  @doc false
  def exception(value) when is_binary(value) do
    %__MODULE__{message: value}
  end
end
