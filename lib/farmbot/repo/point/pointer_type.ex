defmodule Farmbot.Repo.Point.PointerType do
  @moduledoc """
  Custom Ecto.Type for Pointer
  """

  @behaviour Ecto.Type
  @valid_pointer_types ["GenericPointer", "ToolSlot"]


  def type, do: :string

  def cast(string), do: {:ok, string}

  # Load from DB
  Enum.map(@valid_pointer_types, fn(exp) ->
    def load(unquote(exp)) do
      {:ok, Module.concat([Farmbot, Repo, unquote(exp)])}
    end
  end)

  def load(_), do: :error

  # Dump to DB
  Enum.map(@valid_pointer_types, fn(exp) ->
    def dump(unquote(exp)) do
      {:ok, unquote(exp)}
    end

    def dump(unquote(Module.concat([Farmbot, Repo, exp]))) do
      {:ok, unquote(exp)}
    end
  end)

  def dump(_), do: :error
end
