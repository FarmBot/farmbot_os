defmodule Farmbot.Farmware.RuntimeError do
  @moduledoc "Error executing a Farmware."

  defexception [:message, :state]

  @doc false
  def exception(opts) do
    struct(__MODULE__, [message: Keyword.fetch!(opts, :message), state: Keyword.fetch!(opts, :state)])
  end

  @doc false
  def message(%__MODULE__{message: m}), do: m |> to_string()


end
