defmodule FarmbotCeleryScript.Compiler.Execute do
  import FarmbotCeleryScript.Compiler.Utils
  alias FarmbotCeleryScript.Compiler

  @iterables [:point_group, :every_point]

  # Compiles an `execute` block.
  # This one is actually pretty complex and is split into two parts. 
  def execute(%{body: parameter_applications} = ast, env) do
    # if there is an iterable AST here, 
    # we need to compile _many_ sequences, not just one.

    loop_parameter_appl_ast =
      Enum.find_value(parameter_applications, fn
        # check if this parameter_application is a iterable type
        %{kind: :parameter_application, args: %{data_value: %{kind: kind}}} = iterable
        when kind in @iterables ->
          iterable

        _other ->
          false
      end)

    if loop_parameter_appl_ast,
      do: compile_execute_iterable(loop_parameter_appl_ast, ast, env),
      else: compile_execute(ast, env)
  end

  def compile_execute_iterable(
        loop_parameter_appl_ast,
        %{args: %{sequence_id: id}, body: parameter_applications},
        env
      ) do
    # remove the iterable from the parameter applications, 
    # since it will be injected after this.
    parameter_applications =
      Enum.reduce(parameter_applications, [], fn
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
    point_group_arg = group_ast.args[:resource_id] || group_ast.args[:every_point_type]

    # lookup all point_groups related to this value
    case FarmbotCeleryScript.SysCalls.get_point_group(point_group_arg) do
      {:error, reason} ->
        quote location: :keep, do: Macro.escape({:error, unquote(reason)})

      %{} = point_group ->
        # Map over all the points returned by `get_point_group/1`
        Enum.map(point_group.point_ids, fn point_id ->
          # check if it's an every_point node first, if not fall back go generic pointer
          pointer_type = group_ast.args[:every_point_type] || "GenericPointer"
          # compile a `execute` ast, injecting the appropriate `point` ast with
          # the matching `label`
          Compiler.compile_ast(
            %FarmbotCeleryScript.AST{
              kind: :execute,
              args: %{sequence_id: id},
              body: [
                # this is the injection. This parameter_application was removed
                %FarmbotCeleryScript.AST{
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
                # add all other parmeter_applications back in the case of variables, etc
                | parameter_applications
              ]
            },
            env
          )
        end)
    end
  end

  def compile_execute(%{args: %{sequence_id: id}, body: parameter_applications}, env) do
    quote location: :keep do
      # We have to lookup the sequence by it's id.
      case FarmbotCeleryScript.SysCalls.get_sequence(unquote(id)) do
        %FarmbotCeleryScript.AST{} = ast ->
          # compile the ast
          env = unquote(compile_params_to_function_args(parameter_applications, env))
          FarmbotCeleryScript.Compiler.compile(ast, env)

        error ->
          error
      end
    end
  end
end
