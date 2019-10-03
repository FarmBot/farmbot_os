defmodule FarmbotCeleryScript.Compiler.Sequence do
  import FarmbotCeleryScript.Compiler.Utils

  @iterables [:point_group, :every_point]

  def sequence(%{args: %{locals: %{body: params_or_iterables}}} = ast, env) do
    # if there is an iterable AST here, 
    # we need to compile _many_ sequences, not just one.

    loop_parameter_appl_ast =
      Enum.find_value(params_or_iterables, fn
        # check if this parameter_application is a iterable type
        %{kind: :parameter_application, args: %{data_value: %{kind: kind}}} = iterable
        when kind in @iterables ->
          iterable

        _other ->
          false
      end)

    if loop_parameter_appl_ast,
      do: compile_sequence_iterable(loop_parameter_appl_ast, ast, env),
      else: compile_sequence(ast, env)
  end

  def compile_sequence_iterable(
        loop_parameter_appl_ast,
        %{args: %{locals: %{body: params} = locals}} = sequence_ast,
        env
      ) do
    # remove the iterable from the parameter applications, 
    # since it will be injected after this.
    _params =
      Enum.reduce(params, [], fn
        # Remove point_group from parameter appls
        %{kind: :parameter_application, args: %{data_value: %{kind: :point_group}}}, acc -> acc
        # Remove every_point from parameter appls
        %{kind: :parameter_application, args: %{data_value: %{kind: :every_point}}}, acc -> acc
        # Everything else gets added back
        ast, acc -> acc ++ [ast]
      end)

    # will be a point_group or every_point node
    group_ast = loop_parameter_appl_ast.args.data_value
    # check if it's a point_group first, then fall back to every_point
    point_group_arg =
      group_ast.args[:point_group_id] || group_ast.args[:resource_id] ||
        group_ast.args[:every_point_type]

    # lookup all point_groups related to this value
    case FarmbotCeleryScript.SysCalls.get_point_group(point_group_arg) do
      {:error, reason} ->
        quote location: :keep, do: Macro.escape({:error, unquote(reason)})

      %{} = point_group ->
        # Map over all the points returned by `get_point_group/1`
        Enum.map(point_group.point_ids, fn point_id ->
          # check if it's an every_point node first, if not fall back go generic pointer
          pointer_type = group_ast.args[:every_point_type] || "GenericPointer"

          parameter_application = %FarmbotCeleryScript.AST{
            kind: :parameter_application,
            args: %{
              # inject the replacement with the same label
              label: loop_parameter_appl_ast.args.label,
              data_value: %FarmbotCeleryScript.AST{
                kind: :point,
                args: %{pointer_type: pointer_type, pointer_id: point_id}
              }
            }
          }

          # compile a `sequence` ast, injecting the appropriate `point` ast with
          # the matching `label`
          # TODO(Connor) - the body of this ast should have the 
          # params as sorted earlier. Figure out why this doesn't work
          compile_sequence(
            %{sequence_ast | args: %{locals: %{locals | body: [parameter_application]}}},
            env
          )
        end)
        |> List.flatten()
    end
  end

  def compile_sequence(%{args: %{locals: %{body: params}} = args, body: block, meta: meta}, env) do
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

    [
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
    ]
  end
end
