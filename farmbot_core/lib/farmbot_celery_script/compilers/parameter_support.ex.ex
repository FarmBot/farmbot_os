defmodule FarmbotCeleryScript.Compiler.ParameterSupport do

  def extract_iterable(node_body) do
    iterables = Enum.filter(node_body, fn
      # check if this parameter_application is a iterable type
      %{
        kind: :parameter_application,
        args: %{data_value: %{kind: :point_group}}
      } = iterable ->
        iterable
      _other ->
        false
    end)

    case iterables do
      [] ->
        nil
      [i] ->
        i
      [_first | _rest] ->
        raise "Sequences can only operate on one group at a time."
    end
  end
end
