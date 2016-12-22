defmodule Farmbot.CeleryScript.Ast do
  @moduledoc """
    Everyone needs a little recursion in their life
  """
  @type t :: %__MODULE__{
    args: map,
    body: [t,...],
    kind: Strint.t
  }
  @enforce_keys [:args, :body, :kind]
  defstruct @enforce_keys

  @spec parse(map) :: t
  def parse(%{"kind" => kind, "args" => args, "body" => body}) do
    %__MODULE__{kind: kind, args: parse_args(args), body: parse(body)}
  end

  # The body is technically optional
  def parse(%{"kind" => kind, "args" => args}) do
    %__MODULE__{kind: kind, args: parse_args(args), body: []}
  end

  # If the map isnt stringed.
  def parse(%{kind: kind, args: args, body: body}) do
    %__MODULE__{kind: kind, args: parse_args(args), body: parse(body)}
  end

  # The body is technically optional
  def parse(%{kind: kind, args: args}) do
    %__MODULE__{kind: kind, args: parse_args(args), body: []}
  end

  # You can give a list of nodes.
  @spec parse([map,...]) :: [t,...]
  def parse(body) when is_list(body) do
    Enum.reduce(body, [], fn(blah, acc) ->
      acc ++ [parse(blah)]
    end)
  end

  # TODO: This is a pretty heavy memory leak, what should happen is
  # The corpus should create a bunch of atom, and then this should be
  # Strint.to_existing_atom
  @spec parse_args(map) :: map
  def parse_args(map) when is_map(map) do
    Enum.reduce(map, %{}, fn ({key, val}, acc) ->
      Map.put(acc, String.to_atom(key), val)
    end)
  end
end
