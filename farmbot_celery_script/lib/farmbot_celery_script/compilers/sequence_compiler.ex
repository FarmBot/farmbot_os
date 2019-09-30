defmodule FarmbotCeleryScript.Compiler.Sequence do
  import FarmbotCeleryScript.Compiler.Utils

  def sequence(%{args: %{locals: %{body: params}} = args, body: block, meta: meta}, env) do
    # Sort the args.body into two arrays.
    # The `params` side gets turned into
    # a keyword list. These `params` are passed in from a previous sequence.
    # The `body` side declares variables in _this_ scope.
    {params_fetch, body} =
      Enum.reduce(params, {[], []}, fn ast, {params, body} = _acc ->
        case ast do
          # declares usage of a parameter as defined by variable_declaration
          %{kind: :parameter_declaration} ->
            {params ++ [compile_param_declaration(ast, env)], body}

          # declares usage of a variable as defined inside the body of itself
          %{kind: :parameter_application} ->
            {params ++ [compile_param_application(ast, env)], body}

          # defines a variable exists
          %{kind: :variable_declaration} ->
            {params, body ++ [ast]}
        end
      end)

    {:__block__, env, assignments} = compile_block(body, env)
    sequence_name = meta[:sequence_name] || args[:sequence_name]
    steps = compile_block(block, env) |> decompose_block_to_steps()

    steps = add_sequence_init_and_complete_logs(steps, sequence_name)

    quote location: :keep do
      fn params ->
        # This quiets a compiler warning if there are no variables in this block
        _ = inspect(params)
        # Fetches variables from the previous execute()
        # example:
        # parent = Keyword.fetch!(params, :parent)
        unquote_splicing(params_fetch)
        unquote_splicing(assignments)

        # Unquote the remaining sequence steps.
        unquote(steps)
      end
    end
  end
end
