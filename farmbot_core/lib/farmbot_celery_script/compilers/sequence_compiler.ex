defmodule FarmbotCeleryScript.Compiler.Sequence do
  import FarmbotCeleryScript.Compiler.Utils
  alias FarmbotCeleryScript.Compiler.IdentifierSanitizer

  def sequence(%{args: %{locals: %{body: params_or_iterables}}} = ast, env) do
    # if there is an iterable AST here,
    # we need to compile _many_ sequences, not just one.

    iterable_ast = FarmbotCeleryScript
    .Compiler
    .ParameterSupport
    .extract_iterable(params_or_iterables)

    if iterable_ast do
      compile_sequence_iterable(iterable_ast, ast, env)
    else
      compile_sequence(ast, env)
    end
  end

  def compile_sequence_iterable(
        iterable_ast,
        %{
          args: %{locals: %{body: _} = locals} = sequence_args,
          meta: sequence_meta
        } = sequence_ast,
        env
      ) do
    sequence_name =
      sequence_meta[:sequence_name] || sequence_args[:sequence_name]

    # will be a point_group or every_point node
    group_ast = iterable_ast.args.data_value
    # check if it's a point_group first, then fall back to every_point
    point_group_arg =
      group_ast.args[:point_group_id] || group_ast.args[:resource_id]

    # lookup all point_groups related to this value
    case FarmbotCeleryScript.SysCalls.find_points_via_group(point_group_arg) do
      {:error, reason} ->
        quote location: :keep, do: Macro.escape({:error, unquote(reason)})

      %{name: group_name} = point_group ->
        total = Enum.count(point_group.point_ids)
        # Map over all the points returned by `find_points_via_group/1`
        {body, _} =
          Enum.reduce(point_group.point_ids, {[], 1}, fn point_id,
                                                         {acc, index} ->
            parameter_application = %FarmbotCeleryScript.AST{
              kind: :parameter_application,
              args: %{
                # inject the replacement with the same label
                label: iterable_ast.args.label,
                data_value: %FarmbotCeleryScript.AST{
                  kind: :point,
                  args: %{pointer_type: "GenericPointer", pointer_id: point_id}
                }
              }
            }

            sequence_name =
              case FarmbotCeleryScript.SysCalls.point(
                     "GenericPointer",
                     point_id
                   ) do
                %{name: name, x: x, y: y, z: z} when is_binary(sequence_name) ->
                  pos = FarmbotCeleryScript.FormatUtil.format_coord(x, y, z)
                  sequence_name <> " [#{index} / #{total}] - #{name} #{pos}"

                %{name: name, x: x, y: y, z: z} ->
                  pos = FarmbotCeleryScript.FormatUtil.format_coord(x, y, z)

                  "unnamed iterable sequence [#{index} / #{total}] - #{name} #{
                    pos
                  }"

                _ ->
                  "unknown iterable [#{index} / #{total}]"
              end

            # compile a `sequence` ast, injecting the appropriate `point` ast with
            # the matching `label`
            # TODO(Connor) - the body of this ast should have the
            # params as sorted earlier. Figure out why this doesn't work
            body =
              compile_sequence(
                %{
                  sequence_ast
                  | meta: %{sequence_name: sequence_name},
                    args: %{locals: %{locals | body: [parameter_application]}}
                },
                env
              )

            {acc ++ body, index + 1}
          end)

        add_sequence_init_and_complete_logs_ittr(
          body,
          sequence_name <> " - #{group_name} (#{total} items)"
        )
    end
  end

  def create_better_params(body, env) do
    parameter_declarations =
      Enum.reduce(env, %{}, fn
        {key, value}, map ->
          encoded_label = "#{key}"

          if String.starts_with?(encoded_label, "unsafe_") do
            Map.put(map, IdentifierSanitizer.to_string(encoded_label), value)
          else
            map
          end
      end)

    Enum.reduce(body, parameter_declarations, fn ast, map ->
      case ast do
        %{kind: :parameter_application} ->
          args = Map.fetch!(ast, :args)
          label = Map.fetch!(args, :label)
          Map.put(map, label, Map.fetch!(args, :data_value))

        %{kind: :variable_declaration} ->
          args = Map.fetch!(ast, :args)
          label = Map.fetch!(args, :label)
          Map.put(map, label, Map.fetch!(args, :data_value))

        %{kind: :parameter_declaration} ->
          map
      end
    end)
  end

  def compile_sequence(
        %{args: %{locals: %{body: params}} = args, body: block, meta: meta},
        env
      ) do
    # Sort the args.body into two arrays.
    # The `params` side gets turned into
    # a keyword list. These `params` are passed in from a previous sequence.
    # The `body` side declares variables in _this_ scope.
    # === DON'T USE THIS IN NEW CODE.
    #     SCHEDULED FOR DEPRECATION.
    #     USE `better_params` INSTEAD.
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

    better_params = create_better_params(params, env)

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
          better_params = unquote(better_params)
          _ = inspect(better_params)
          # Unquote the remaining sequence steps.
          unquote(steps)
        end
      end
    ]
  end
end
