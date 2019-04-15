defmodule FarmbotCeleryScript.Corpus.Arg do
  @moduledoc """
  Type information about a CeleryScript Arg on the Corpus.
  """

  defstruct [:name, :allowed_values, :doc]

  @type name :: String.t()
  @type value :: String.t()
  @type doc :: String.t()

  @type t :: %FarmbotCeleryScript.Corpus.Arg{
          name: name(),
          allowed_values: [value],
          doc: doc()
        }

  defimpl Inspect do
    def inspect(data, _opts) do
      values = Enum.map(data.allowed_values, fn %{"name" => name} -> name end)
      "#Arg<#{data.name} [#{Enum.join(values, ", ")}]>"
    end
  end
end
