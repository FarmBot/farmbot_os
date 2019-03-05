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
      "#Arg<#{data.name} [#{Enum.join(data.allowed_values, ", ")}]>"
    end
  end
end
