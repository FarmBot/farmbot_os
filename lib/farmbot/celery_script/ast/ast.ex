defmodule Farmbot.CeleryScript.AST do
  @moduledoc """
  Handy functions for turning various data types into Farbot Celery Script
  Ast nodes.
  """

  defmodule Meta do
    @moduledoc "Metadata about an AST node."
    defstruct [precompiled: false, encoded: nil]
    @type t :: %__MODULE__{
      precompiled: boolean,
      encoded: binary
    }

    def new(ast) do
      bin = Map.from_struct(ast) |> Map.delete(:__meta__) |> Poison.encode! 
      encoded = :crypto.hash(:md5, bin) |> Base.encode16()
      struct(__MODULE__, encoded: encoded)
    end
  end

  alias Farmbot.CeleryScript.Error

  @typedoc """
  CeleryScript args.
  """
  @type args :: map

  @typedoc """
  Type for CeleryScript Ast's.
  """
  @type t :: %__MODULE__{
          __meta__: Meta.t,
          uid: binary,
          args: args,
          body: [t, ...],
          kind: String.t(),
          comment: String.t() | nil
        }

  @enforce_keys [:args, :body, :kind]
  defstruct [
    kind: nil,
    uid: nil,
    args: %{},
    body: [],
    comment: nil,
    __meta__: nil
  ]

  @doc """
  Parses json and traverses the tree and turns everything can
  possibly be parsed.
  """
  @spec parse(map | [map, ...]) :: t
  def parse(map_or_json_map)

  def parse(%{"kind" => kind, "args" => args} = thing) do
    body = thing["body"] || []
    comment = thing["comment"]
    uid = thing["uuid"] || generate_uid()
    before_meta = %__MODULE__{kind: kind, args: parse_args(args), body: parse(body), comment: comment, uid: uid}
    meta = thing["__meta__"] || Meta.new(before_meta)
    %{before_meta | __meta__: meta}
  end

  def parse(%{__struct__: _} = thing) do
    thing |> Map.from_struct() |> parse
  end

  def parse(%{kind: kind, args: args} = thing) do
    body = thing[:body] || []
    comment = thing[:comment]
    uid = thing[:uid] || generate_uid()
    before_meta = %__MODULE__{kind: kind, body: parse(body), args: parse_args(args), comment: comment, uid: uid}
    meta = thing[:__meta__] || Meta.new(before_meta)
    %{before_meta | __meta__: meta}
  end

  # You can give a list of nodes.
  def parse(body) when is_list(body) do
    Enum.reduce(body, [], fn blah, acc ->
      acc ++ [parse(blah)]
    end)
  end

  def parse(other_thing),
    do: raise(Error, message: "#{inspect(other_thing)} could not be parsed as CeleryScript.")

  # TODO: This is a pretty heavy memory leak, what should happen is
  # The corpus should create a bunch of atom, and then this should be
  # Strint.to_existing_atom
  @spec parse_args(map) :: map
  def parse_args(map) when is_map(map) do
    Enum.reduce(map, %{}, fn {key, val}, acc ->
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

  defp generate_uid do
    UUID.uuid1 |> String.split("-") |> List.first
  end
end
