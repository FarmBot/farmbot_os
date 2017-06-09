defmodule Farmbot.Farmware.Installer.Error do
  @moduledoc """
    Farmware Installer Error
  """
  defexception [:message]

  @doc false
  def exception(value) when is_binary(value) do
    %__MODULE__{message: value}
  end
end
