defmodule Farmbot.CeleryScript.Corpus.Node do
  @moduledoc """
  Type information about a CeleryScript Node on the Corpus.
  """

  defstruct [:allowed_args, :allowed_body_types, :name, :doc]

  @type name :: String.t()
  @type body_type :: String.t()
  @type doc :: String.t()

  @type t :: %Farmbot.CeleryScript.Corpus.Node{
          name: name(),
          doc: doc,
          allowed_args: Farmbot.CeleryScript.Corpus.Arg.name(),
          allowed_body_types: body_type()
        }

  defimpl Inspect do
    def inspect(data, _opts) do
      args =
        Enum.map(data.allowed_args, &Map.fetch!(&1, :name))
        |> Enum.join(", ")

      args = "(#{args})"

      body =
        data.allowed_body_types
        |> case do
          [] ->
            nil

          [_ | _] = body_types ->
            " [#{Enum.join(body_types, ", ")}]"
        end

      "#{Macro.camelize(data.name)}#{args}#{body}"
    end
  end
end
