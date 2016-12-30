defmodule Farmbot.CeleryScript.Ast do
  @moduledoc """
    Handy functions for turning various data types into Farbot Celery Script
    Ast nodes.
  """
  @type t :: %__MODULE__{
    args: map,
    body: [t,...],
    kind: String.t
  }
  @enforce_keys [:args, :body, :kind]
  defstruct @enforce_keys

  @doc """
    Parses json and traverses the tree and turns everything can
    possibly be parsed.
  """
  @spec parse({:ok, map}) :: t
  def parse({:ok, map}), do: parse(map) # this allows me to pipe from Poison

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

  def parse(_), do: %__MODULE__{kind: "nothing", args: %{}, body: []}

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
      if is_map(val) do
        # if it is a map, it could be another node so parse it too.
        real_val = parse(val)
        Map.put(acc, String.to_atom(key), real_val)
      else
        Map.put(acc, String.to_atom(key), val)
      end
    end)
  end

  @doc """
    Creates a new AST node. No validation is preformed on this other than making
    sure its syntax is valid.
  """
  def create(kind, args, body) when is_map(args) and is_list(body) do
    %__MODULE__{kind: kind, args: args, body: body}
  end
end
