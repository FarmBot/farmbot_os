defmodule FarmbotCore.Asset.View do
  @doc "Format data to be JSON encodable."
  @callback render(map) :: map

  @doc "Delegates rendering to an asset's `render/1` function."
  @spec render(module, map) :: map
  def render(module, object), do: module.render(object)

  @doc "Helper to define a `render/1` function"
  defmacro view(data, block) do
    quote do
      def render(unquote(data)), unquote(block)
    end
  end
end
