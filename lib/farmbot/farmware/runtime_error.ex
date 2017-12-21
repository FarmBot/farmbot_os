defmodule Farmbot.Farmware.RuntimeError do
  @moduledoc "Error executing a Farmware."

  defexception [:message, :state]

  @doc false
  def exception(opts) do
    struct_opts = [
      message: Keyword.fetch!(opts, :message),
      state: Keyword.fetch!(opts, :state)
    ]
    struct(__MODULE__, struct_opts)
  end

  @doc false
  def message(%__MODULE__{message: m}), do: m |> to_string()
end
