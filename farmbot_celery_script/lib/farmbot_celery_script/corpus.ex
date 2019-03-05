defmodule FarmbotCeleryScript.Corpus do
  alias FarmbotCeleryScript.{Corpus, Corpus.Node, Corpus.Arg}

  @corpus_file "fixture/corpus.json"
  @external_resource @corpus_file

  %{"args" => args, "nodes" => nodes, "tag" => tag} =
    @corpus_file |> File.read!() |> Jason.decode!()

  @args args
  @nodes nodes
  @corpus_tag tag

  # Load and decode each arg in the json into an Arg struct
  @args Enum.map(args, fn %{"name" => name, "allowed_values" => allowed_values} = a ->
          %Arg{name: name, allowed_values: allowed_values, doc: a["doc"]}
        end)

  # Load and decode each node in the json into a Node struct.
  # This also expands the `allowed_args` into their respective Arg relationship.
  @nodes Enum.map(nodes, fn %{"name" => name, "allowed_args" => aa, "allowed_body_types" => abt} =
                              n ->
           allowed_args =
             Enum.map(aa, fn arg_name ->
               Enum.find(@args, fn
                 %{name: ^arg_name} = arg -> arg
                 _ -> false
               end) || Mix.raise("Unknown CeleryScript argument: #{arg_name}")
             end)

           %Node{name: name, allowed_args: allowed_args, allowed_body_types: abt, doc: n["doc"]}
         end)

  # Struct should never be created manually.
  defstruct args: @args,
            nodes: @nodes,
            tag: @corpus_tag

  @type t :: %Corpus{
          args: [Arg.t()],
          nodes: [Node.t()]
        }

  @doc "Returns a CeleryScript Argument by it's name."
  @spec arg(Arg.name() | atom) :: Arg.t()
  def arg(name)

  # Allow passing an atom to determine a name.
  def arg(name) when is_atom(name), do: arg(to_string(name))

  for %Arg{name: name} = arg <- @args do
    def arg(unquote(name)), do: unquote(Macro.escape(arg))
  end

  @doc "Returns a list of every known CeleryScript Argument."
  @spec all_args() :: [Arg.t()]
  def all_args, do: @args

  @doc "Returns every known CeleryScript Argument name."
  @spec all_arg_names() :: [Arg.name()]
  def all_arg_names, do: for(%{name: name} <- @args, do: name)

  @doc "Returns a CeleryScript Node by it's name."
  @spec node(Node.name() | atom) :: Node.t()
  def node(name)

  # This is an apply because node/1 is a function in Kernel
  def node(name) when is_atom(name) do
    apply(__MODULE__, :node, [to_string(name)])
  end

  for %Node{name: name} = node <- @nodes do
    def node(unquote(name)), do: unquote(Macro.escape(node))
  end

  @doc "Returns a list of every known CeleryScript Node"
  @spec all_nodes() :: [Node.t()]
  def all_nodes, do: @nodes

  @doc "Returns every known CeleryScript Node name."
  @spec all_node_names() :: [Node.name()]
  def all_node_names, do: for(%{name: name} <- @nodes, do: name)

  for n <- @nodes do
    if n.doc, do: @doc(n.doc)
    def unquote(String.to_atom(n.name))(), do: unquote(Macro.escape(n))
  end

  @node_doc Enum.map(@nodes, fn %{
                                  name: name,
                                  doc: doc,
                                  allowed_args: allowed_args,
                                  allowed_body_types: allowed_body_types
                                } ->
              args =
                Enum.map(allowed_args, fn %{name: name, doc: doc} ->
                  """
                    * [#{name}](#module-#{String.replace(name, "_", "")}) #{
                    if doc, do: "- " <> doc
                  }
                  """
                end)

              args = """
              ### #{Macro.camelize(name)} Args
              #{args}
              """

              body =
                Enum.map(allowed_body_types, fn name ->
                  """
                    * [#{name}](#module-#{String.replace(name, "_", "")}) #{
                    if doc, do: "- " <> doc
                  }
                  """
                end)

              body = """
              ### #{Macro.camelize(name)} Body Nodes
              #{body}
              """

              """
              ## #{Macro.camelize(name)}
              #{doc}
              #{if allowed_args != [], do: args}
              #{if allowed_body_types != [], do: body}
              """
            end)

  @arg_doc Enum.map(@args, fn %{name: name, allowed_values: values, doc: doc} ->
             values =
               Enum.map(values, fn val ->
                 """
                   * #{val}
                 """
               end)

             """
             ## #{Macro.camelize(name)}
             #{doc}
             #{values}
             """
           end)

  @moduledoc """
  Dynamically generated module storing information about every CelleryScript
  Node and Argument.

  Generated #{@corpus_tag}

  # Nodes
  #{@node_doc}

  # Args
  #{@arg_doc}
  """
end
