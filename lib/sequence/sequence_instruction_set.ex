defmodule SequenceInstructionSet do
  require Logger
  def create_instruction_set(%{"tag" => tag_version, "args" => allowed_args_list, "nodes" => allowed_nodes_list}) do
    initial =
      "
      defmodule Corpus_#{tag_version} do
        use GenServer
        require Logger
        def start_link(args) do
          GenServer.start_link(__MODULE__, args, name: __MODULE__)
        end

        def init(_args) do
          {:ok, %{}}
        end
      "
    Module.create(SiS, create_instructions(initial, allowed_args_list, allowed_nodes_list ), Macro.Env.location(__ENV__))
  end

  def create_instructions(initial, arg_list, node_list) when is_list(arg_list) and is_list(node_list) do
    initial
    <>create_arg_instructions(arg_list, "")
    <>create_node_instructions(node_list, "")
    <>" end" |> Code.string_to_quoted!
  end

  def create_arg_instructions([], str) do
    str
  end

  def create_arg_instructions(arg_list, old) when is_list arg_list do
    arg = List.first(arg_list) || ""
    arg_code_str = create_arg_instructions(arg)
    create_arg_instructions(arg_list -- [arg], old<>" "<>arg_code_str)
  end

  def create_arg_instructions(%{"name" => name, "allowed_values" => allowed_values})
  when  is_bitstring(name) and is_list(allowed_values) do
    "
    def #{name}(val) do
      val
    end
    "
  end

  def create_node_instructions([], str) do
    str
  end

  def create_node_instructions(arg_list, old) when is_list arg_list do
    arg = List.first(arg_list) || ""
    arg_code_str = create_node_instructions(arg)
    create_node_instructions(arg_list -- [arg], old<>" "<>arg_code_str)
  end

  def create_node_instructions(%{"name" => name, "allowed_args" => [], "allowed_body_types" => allowed_body_types})
  when is_bitstring(name) and is_list(allowed_body_types) do
    "
    def #{name}() do
      Logger.debug(\"node #{name} is not implemented\")
    end
    "
  end

  def create_node_instructions(%{"name" => name, "allowed_args" => allowed_args, "allowed_body_types" => allowed_body_types})
  when is_bitstring(name) and is_list(allowed_args) and is_list(allowed_body_types) do
    b = Enum.reduce(allowed_args, "", fn(x, acc) -> acc <> "\"#{x}\" => #{x}, "end)
    args = String.slice(b, 0, String.length(b) - 2)
    "
    def #{name}( %{#{args}} ) do
      Logger.debug(\"node #{name} is not implemented\")
    end
    "
  end
end
