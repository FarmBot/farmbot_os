defmodule Farmbot.Repo.ModuleType do
  @moduledoc """
  Custom Ecto.Type for changing a string to a module.
  """

  defmacro __using__(opts) do
    mods = Keyword.fetch!(opts, :valid_mods)

    quote do
      @valid_short_strs unquote(mods)
      @valid_mods Enum.map(unquote(mods), fn mod -> Module.concat([Farmbot, Repo, mod]) end)

      @moduledoc "Custom Ecto.Type for changing a string field to one of #{
                   inspect(@valid_short_strs)
                 }"
      @behaviour Ecto.Type
      require Logger

      def type, do: :string

      def cast(string) when is_binary(string), do: {:ok, string}

      def cast(module) when is_atom(module) do
        if match?(<<"Elixir.", _::binary>>, to_string(module)) do
          module
          |> Module.split()
          |> List.last()
          |> (fn mod -> {:ok, mod} end).()
        else
          :error
        end
      end

      def load(exp) when exp in @valid_short_strs do
        {:ok, Module.concat([Farmbot, Repo, exp])}
      end

      def load(exp) when exp in @valid_mods do
        {:ok, exp}
      end

      def load("Elixir." <> _ = mod), do: String.to_atom(mod) |> load()

      def load(_fail) do
        :error
      end

      def dump(exp) when exp in @valid_short_strs do
        {:ok, Module.concat([Farmbot, Repo, exp])}
      end

      def dump(fail) do
        Logger.error("failed to load #{inspect(fail)}")
        :error
      end
    end
  end
end
