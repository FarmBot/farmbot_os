defmodule Farmbot.Sync.Macros do
  defmacro generate(module, model, do_block \\ []) do
    quote do
      deftable unquote(module)
      deftable unquote(module), unquote(model), [type: :ordered_set] do
        @moduledoc """
          A #{unquote(module)} from the API.
          \nRequires: #{inspect unquote(model)}
        """
        use Syncable, name: __MODULE__, model: unquote(model)

        unquote do_block
        defp mutate(_k, v), do: {:ok, v}
      end
    end
  end
end
