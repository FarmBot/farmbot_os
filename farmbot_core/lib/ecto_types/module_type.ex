defmodule Farmbot.EctoTypes.ModuleType do
  @moduledoc """
  Custom Ecto.Type for changing a string to a module.
  """

  defmacro __using__(opts) do
    mods = Keyword.fetch!(opts, :valid_mods)

    quote do
      @valid_short_strs unquote(mods)
      @valid_mods Enum.map(unquote(mods), fn(mod) ->
        Module.concat([Farmbot, Asset, mod])
      end)

      @moduledoc """
      Custom Ecto.Type for changing a string field to one of
      #{inspect(@valid_short_strs)}
      """
      @behaviour Ecto.Type

      def type, do: :string

      def cast(exp) do
        do_cast(exp)
      end

      def do_cast(string) when is_binary(string), do: {:ok, string}

      def do_cast(module) when is_atom(module) do
        if match?(<<"Elixir.", _::binary>>, to_string(module)) do
          module
          |> Module.split()
          |> List.last()
          |> (fn mod -> {:ok, mod} end).()
        else
          :error
        end
      end

      def load(exp) do
        {:ok, exp}
      end

      def dump(exp) do
        {:ok, Module.concat([Farmbot, Asset, exp]) |> to_string()}
      end
    end
  end
end
