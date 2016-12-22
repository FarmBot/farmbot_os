defmodule CeleryScript.CommandBuilder do
  defmacro __using__(_) do
    quote do
      import CeleryScript.CommandBuilder
    end
  end

  defmacro command(kind, args, body \\ [], do: block) when is_bitstring(kind) do
    function_name = String.to_atom(kind)
    quote do
      def unquote(function_name)(unquote(args), unquote(body)), do: unquote(block)
      def unquote(function_name)(_, _), do: {:error, :bad_args_or_body}
    end
  end
end
