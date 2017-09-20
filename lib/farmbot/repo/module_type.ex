defmodule Farmbot.Repo.ModuleType do
  @moduledoc """
  Custom Ecto.Type for changing a string to a module.
  """

  defmacro __using__(opts) do
    mods = Keyword.fetch!(opts, :valid_mods)
    quote do
      @valid_mods unquote(mods)
      @moduledoc "Custom Ecto.Type for changing a string field to one of #{inspect @valid_mods}"
      @behaviour Ecto.Type

      def type, do: :string

      def cast(string) when is_binary(string), do: {:ok, string}

      def cast(module) when is_atom(module) do
        if match?(<<"Elixir.", _::binary>>, to_string(module)) do
          module
          |> Module.split()
          |> List.last
          |> fn(mod) -> {:ok, mod} end.()
        else
          :error
        end
      end

      # Load from DB
      Enum.map(@valid_mods, fn(exp) ->
        def load(exp) do
          {:ok, Module.concat([Farmbot, Repo, exp])}
        end
      end)

      def load(_), do: :error

      # Dump to DB
      Enum.map(@valid_mods, fn(exp) ->
        def dump(exp) do
          {:ok, exp}
        end
      end)

      def dump(_), do: :error
    end
  end
end
