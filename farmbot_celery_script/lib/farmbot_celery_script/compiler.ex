defmodule FarmbotCeleryScript.Compiler do
  @moduledoc """
  Responsible for compiling canonical CeleryScript AST into
  Elixir AST.
  """

  alias FarmbotCeleryScript.{AST, Compiler, Compiler.IdentifierSanitizer, SysCalls}
  use Compiler.Tools
  @valid_entry_points [:sequence, :rpc_request]

  # TODO(Connor) - Delete this when the new corpus is published
  @kinds "regisiter_gpio"
  @kinds "unregisiter_gpio"
  @kinds "config_update"

  @typedoc """
  Compiled CeleryScript node should compile to an anon function.
  Entrypoint nodes such as
  * `rpc_request`
  * `sequence`
  will compile to a function that takes a Keyword list of variables. This function
  needs to be executed before scheduling/executing.

  Non entrypoint nodes compile to a function that symbolizes one individual step.

  ## Examples

  `rpc_request` will be compiled to something like:
  ```
  fn params ->
    [
      # Body of the `rpc_request` compiled in here.
    ]
  end
  ```

  as compared to a "simple" node like `wait` will compile to something like:
  ```
  fn() -> wait(200) end
  ```
  """
  @type compiled :: (Keyword.t() -> [(() -> any())]) | (() -> any())

  @doc """
  Recursive function that will emit Elixir AST from CeleryScript AST.
  """
  @spec compile(AST.t(), Keyword.t()) :: [compiled()]
  def compile(%AST{kind: kind} = ast, env \\ []) when kind in @valid_entry_points do
    # compile the ast
    {_, _, _} = compiled = compile_ast(ast)

    delete_me(compiled)
    # entry points must be evaluated once more with the calling `env`
    # to return a list of compiled `steps`

    # TODO: investigate why i have to turn this to a string
    # before eval ing it?
    # case Code.eval_quoted(compiled, [], __ENV__) do
    case Macro.to_string(compiled) |> Code.eval_string([], __ENV__) do
      {fun, _} when is_function(fun, 1) -> apply(fun, [env])
      {{:error, error}, _} -> {:error, error}
    end
  end

  # The compile macro right here is generated by the Compiler.Tools module.
  # The goal of the macro is to do two things:
  # 1) take out all the common code between each node impl.
  #    Example:
  #       compile :fire_laser, %{after: 100}, targets, do: quote, do: fire_at(targets)
  #    will compile down to:
  #       def compile_ast(%AST{kind: :fire_laser, args: %{after: 100}, body: targets})
  #
  # 2) Accumulate implemented nodes behind the scenes.
  #    This allows for the Corpus to throw warnings when a new node
  #    is added.

  # Compiles a `sequence` into an Elixir `fn`.
  compile :sequence, %{locals: %{body: params}}, block do
    # Sort the args.body into two arrays.
    # The `params` side gets turned into
    # a keyword list. These `params` are passed in from a previous sequence.
    # The `body` side declares variables in _this_ scope.
    {params_fetch, body} =
      Enum.reduce(params, {[], []}, fn ast, {params, body} = _acc ->
        case ast do
          # declares usage of a paramater as defined by variable_declaration
          %{kind: :parameter_declaration} -> {params ++ [compile_param_declaration(ast)], body}
          # declares usage of a variable as defined inside the body of itself
          %{kind: :parameter_application} -> {params ++ [compile_param_application(ast)], body}
          # defines a variable exists
          %{kind: :variable_declaration} -> {params, body ++ [ast]}
        end
      end)

    {:__block__, [], assignments} = compile_block(body)
    steps = compile_block(block) |> decompose_block_to_steps()

    quote location: :keep do
      fn params ->
        import SysCalls
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

  compile :rpc_request, %{label: _label}, block do
    steps = compile_block(block) |> decompose_block_to_steps()

    quote location: :keep do
      fn params ->
        import SysCalls
        unquote(steps)
      end
    end
  end

  # Compiles a variable asignment.
  compile :variable_declaration, %{label: var_name, data_value: data_value_ast} do
    # Compiles the `data_value`
    # and assigns the result to a variable named `label`
    # Example:
    # {
    #       "kind": "variable_declaration",
    #       "args": {
    #         "label": "parent",
    #         "data_value": {
    #           "kind": "point",
    #           "args": {
    #             "pointer_type": "Plant",
    #             "pointer_id": 456
    #           }
    #         }
    #       }
    # }
    # Will be turned into:
    #   parent = point("Plant", 456)
    # NOTE: This needs to be Elixir AST syntax, not quoted
    # because var! doesn't do what what we need.
    var_name = IdentifierSanitizer.to_variable(var_name)

    quote location: :keep do
      unquote({var_name, [], nil}) = unquote(compile_ast(data_value_ast))
    end
  end

  # Compiles an if statement.
  compile :_if, %{_then: then_ast, _else: else_ast, lhs: lhs, op: op, rhs: rhs} do
    # Turns the left hand side arg into
    # a number. x, y, z, and pin{number} are special that need to be
    # evaluated before evaluating the if statement.
    # any AST is also aloud to be on the lefthand side as
    # well, so if that is the case, compile it first.
    lhs =
      case lhs do
        "x" ->
          quote [location: :keep], do: get_current_x()

        "y" ->
          quote [location: :keep], do: get_current_y()

        "z" ->
          quote [location: :keep], do: get_current_z()

        "pin" <> pin ->
          quote [location: :keep], do: read_pin(unquote(String.to_integer(pin)), nil)

        %AST{} = ast ->
          compile_ast(ast)
      end

    rhs = compile_ast(rhs)

    # Turn the `op` arg into Elixir code
    if_eval =
      case op do
        "is" ->
          # equality check.
          # Examples:
          # get_current_x() == 0
          # get_current_y() == 10
          # get_current_z() == 200
          # read_pin(22, nil) == 5
          # The ast will look like: {:==, [], lhs, compile_ast(rhs)}
          quote location: :keep do
            unquote(lhs) == unquote(rhs)
          end

        "not" ->
          # ast will look like: {:!=, [], [lhs, compile_ast(rhs)]}
          quote location: :keep do
            unquote(lhs) != unquote(rhs)
          end

        "is_undefined" ->
          # ast will look like: {:is_nil, [], [lhs]}
          quote location: :keep do
            is_nil(unquote(lhs))
          end

        "<" ->
          # ast will look like: {:<, [], [lhs, compile_ast(rhs)]}
          quote location: :keep do
            unquote(lhs) < unquote(rhs)
          end

        ">" ->
          # ast will look like: {:>, [], [lhs, compile_ast(rhs)]}
          quote location: :keep do
            unquote(lhs) > unquote(rhs)
          end
      end

    # Finally, compile the entire if statement.
    # outputted code will look something like:
    # if get_current_x() == 123 do
    #    execute(123)
    # else
    #    nothing()
    # end
    quote location: :keep do
      if unquote(if_eval),
        do: unquote(compile_block(then_ast)),
        else: unquote(compile_block(else_ast))
    end
  end

  # Compiles an `execute` block.
  compile :execute, %{sequence_id: id}, parameter_applications do
    quote location: :keep do
      # We have to lookup the sequence by it's id.
      %FarmbotCeleryScript.AST{} = ast = get_sequence(unquote(id))
      # compile the ast
      env = unquote(compile_params_to_function_args(parameter_applications))
      unquote(__MODULE__).compile(ast, env)
    end
  end

  # Compiles `execute_script`
  # TODO(Connor) - make this actually usable
  compile :execute_script, %{label: package}, params do
    env =
      Enum.map(params, fn %{args: %{label: key, value: value}} ->
        {to_string(key), value}
      end)

    quote location: :keep do
      execute_script(unquote(compile_ast(package)), unquote(Macro.escape(Map.new(env))))
    end
  end

  # TODO(Connor) - see above TODO
  compile :take_photo do
    # {:execute_script, [], ["take_photo", {:%{}, [], []}]}
    quote location: :keep do
      execute_script("take_photo", %{})
    end
  end

  compile :set_user_env, _args, pairs do
    kvs =
      Enum.map(pairs, fn %{kind: :pair, args: %{label: key, value: value}} ->
        quote location: :keep do
          set_user_env(unquote(key), unquote(value))
        end
      end)

    quote location: :keep do
      (unquote_splicing(kvs))
    end
  end

  compile :install_farmware, %{url: url} do
    quote location: :keep do
      install_farmware(unquote(compile_ast(url)))
    end
  end

  compile :update_farmware, %{package: package} do
    quote location: :keep do
      update_farmware(unquote(compile_ast(package)))
    end
  end

  compile :remove_farmware, %{package: package} do
    quote location: :keep do
      remove_farmware(unquote(compile_ast(package)))
    end
  end

  compile :install_first_party_farmware, _ do
    quote location: :keep do
      install_first_party_farmware()
    end
  end

  # Compiles a nothing block.
  compile :nothing do
    # AST looks like: {:nothing, [], []}
    quote location: :keep do
      nothing()
    end
  end

  # Compiles move_absolute
  compile :move_absolute, %{location: location, offset: offset, speed: speed} do
    quote location: :keep do
      # Extract the location arg
      %{x: locx, y: locy, z: locz} = unquote(compile_ast(location))
      # Extract the offset arg
      %{x: offx, y: offy, z: offz} = unquote(compile_ast(offset))

      # Subtract the location from offset.
      # Note: list syntax here for readability.
      [x, y, z] = [
        locx - offx,
        locy - offy,
        locz - offz
      ]

      move_absolute(x, y, z, unquote(compile_ast(speed)))
    end
  end

  # compiles move_relative into move absolute
  compile :move_relative, %{x: x, y: y, z: z, speed: speed} do
    quote location: :keep do
      # build a vec3 of passed in args
      %{x: locx, y: locy, z: locz} = %{
        x: unquote(compile_ast(x)),
        y: unquote(compile_ast(y)),
        z: unquote(compile_ast(z))
      }

      # build a vec3 of the current position
      %{x: offx, y: offy, z: offz} = %{
        x: get_current_x(),
        y: get_current_y(),
        z: get_current_y()
      }

      # Subtract the location from offset.
      # Note: list syntax here for readability.
      [x, y, z] = [offx - locx, offy - locy, offz - locz]
      move_absolute(x, y, z, unquote(compile_ast(speed)))
    end
  end

  # compiles write_pin
  compile :write_pin, %{pin_number: num, pin_mode: mode, pin_value: val} do
    quote location: :keep do
      write_pin(
        unquote(compile_ast(num)),
        unquote(compile_ast(mode)),
        unquote(compile_ast(val))
      )
    end
  end

  # compiles read_pin
  compile :read_pin, %{pin_number: num, pin_mode: mode} do
    quote location: :keep do
      read_pin(unquote(compile_ast(num)), unquote(compile_ast(mode)))
    end
  end

  # compiles set_servo_angle
  compile :set_servo_angle, %{pin_number: pin_number, pin_value: pin_value} do
    quote location: :keep do
      set_servo_angle(unquote(compile_ast(pin_number)), unquote(compile_ast(pin_value)))
    end
  end

  # Expands find_home(all) into three find_home/1 calls
  compile :find_home, %{axis: "all", speed: speed} do
    quote location: :keep do
      find_home("x", unquote(compile_ast(speed)))
      find_home("y", unquote(compile_ast(speed)))
      find_home("z", unquote(compile_ast(speed)))
    end
  end

  # compiles find_home
  compile :find_home, %{axis: axis, speed: speed} do
    quote location: :keep do
      find_home(unquote(compile_ast(axis)), unquote(compile_ast(speed)))
    end
  end

  # Expands home(all) into three home/1 calls
  compile :home, %{axis: "all", speed: speed} do
    quote location: :keep do
      home("x", unquote(compile_ast(speed)))
      home("y", unquote(compile_ast(speed)))
      home("z", unquote(compile_ast(speed)))
    end
  end

  # compiles home
  compile :home, %{axis: axis, speed: speed} do
    quote location: :keep do
      home(unquote(compile_ast(axis)), unquote(compile_ast(speed)))
    end
  end

  # Expands zero(all) into three zero/1 calls
  compile :zero, %{axis: "all", speed: speed} do
    quote location: :keep do
      zero("x", unquote(compile_ast(speed)))
      zero("y", unquote(compile_ast(speed)))
      zero("z", unquote(compile_ast(speed)))
    end
  end

  # compiles zero
  compile :zero, %{axis: axis, speed: speed} do
    quote location: :keep do
      zero(unquote(compile_ast(axis)), unquote(compile_ast(speed)))
    end
  end

  # Expands calibrate(all) into three calibrate/1 calls
  compile :calibrate, %{axis: "all"} do
    quote location: :keep do
      calibrate("x")
      calibrate("y")
      calibrate("z")
    end
  end

  # compiles calibrate
  compile :calibrate, %{axis: axis} do
    quote location: :keep do
      calibrate(unquote(compile_ast(axis)))
    end
  end

  compile :wait, %{milliseconds: millis} do
    quote location: :keep do
      wait(unquote(compile_ast(millis)))
    end
  end

  compile :send_message, %{message: msg, message_type: type}, channels do
    # body gets turned into a list of atoms.
    # Example:
    #   [{kind: "channel", args: {channel_name: "email"}}]
    # is turned into:
    #   [:email]
    channels =
      Enum.map(channels, fn %{kind: :channel, args: %{channel_name: channel_name}} ->
        String.to_atom(channel_name)
      end)

    quote location: :keep do
      # send_message("success", "Hello world!", [:email, :toast])
      send_message(
        unquote(compile_ast(type)),
        unquote(compile_ast(msg)),
        unquote(channels)
      )
    end
  end

  # compiles coordinate
  # Coordinate should return a vec3
  compile :coordinate, %{x: x, y: y, z: z} do
    quote location: :keep do
      coordinate(
        unquote(compile_ast(x)),
        unquote(compile_ast(y)),
        unquote(compile_ast(z))
      )
    end
  end

  # compiles point
  compile :point, %{pointer_type: type, pointer_id: id} do
    quote location: :keep do
      point(unquote(compile_ast(type)), unquote(compile_ast(id)))
    end
  end

  # compile a named pin
  compile :named_pin, %{pin_id: id, pin_type: type} do
    quote location: :keep do
      named_pin(unquote(compile_ast(type)), unquote(compile_ast(id)))
    end
  end

  # compiles identifier into a variable.
  # We have to use Elixir ast syntax here because
  # var! doesn't work quite the way we want.
  compile :identifier, %{label: var_name} do
    var_name = IdentifierSanitizer.to_variable(var_name)

    quote location: :keep do
      unquote({var_name, [], nil})
    end
  end

  compile :tool, %{tool_id: tool_id} do
    quote location: :keep do
      get_tool(unquote(compile_ast(tool_id)))
    end
  end

  compile :emergency_lock do
    quote location: :keep do
      emergency_lock()
    end
  end

  compile :emergency_unlock do
    quote location: :keep do
      emergency_unlock()
    end
  end

  compile :read_status do
    quote location: :keep do
      read_status()
    end
  end

  compile :sync do
    quote location: :keep do
      sync()
    end
  end

  compile :check_updates, %{package: "farmbot_os"} do
    quote location: :keep do
      check_update()
    end
  end

  compile :flash_firmware, %{package: package_name} do
    quote location: :keep do
      flash_firmware(unquote(compile_ast(package_name)))
    end
  end

  compile :power_off do
    quote location: :keep do
      power_off()
    end
  end

  compile :reboot, %{package: "farmbot_os"} do
    quote location: :keep do
      reboot()
    end
  end

  compile :reboot, %{package: "arduino_firmware"} do
    quote location: :keep do
      firmware_reboot()
    end
  end

  compile :factory_reset, %{package: "farmbot_os"} do
    quote location: :keep do
      factory_reset()
    end
  end

  compile :change_ownership, %{}, _body do
    quote location: :keep do
      # Add code here
    end
  end

  compile :dump_info do
    quote location: :keep do
      dump_info()
    end
  end

  compile :toggle_pin, %{pin_number: pin_number} do
    quote location: :keep do
      # mode 0 = digital
      case read_pin(unquote(compile_ast(pin_number)), 0) do
        0 -> write_pin(unquote(compile_ast(pin_number)), 0, 1)
        _ -> write_pin(unquote(compile_ast(pin_number)), 0, 0)
      end
    end
  end

  # not actually used
  compile :channel, %{channel_name: _channel_name} do
    quote location: :keep do
      nothing()
    end
  end

  # not actually used
  compile :explanation, %{message: _message} do
    quote location: :keep do
      nothing()
    end
  end

  # not actually used
  compile :rpc_ok, %{label: _label} do
    quote location: :keep do
      nothing()
    end
  end

  # not actually used
  compile :rpc_error, %{label: _label}, _body do
    quote location: :keep do
      nothing()
      # Add code here
    end
  end

  # not actually used
  compile :pair, %{label: _label, value: _value} do
    quote location: :keep do
      nothing()
    end
  end

  # not actually used
  compile :scope_declaration, _args, _body do
    quote location: :keep do
      nothing()
    end
  end

  @doc """
  Recursively compiles a list or single Celery AST into an Elixir `__block__`
  """
  def compile_block(asts, acc \\ [])

  def compile_block(%AST{} = ast, _) do
    case compile_ast(ast) do
      {_, _, _} = compiled ->
        {:__block__, [], [compiled]}

      compiled when is_list(compiled) ->
        {:__block__, [], compiled}
    end
  end

  def compile_block([ast | rest], acc) do
    case compile_ast(ast) do
      {_, _, _} = compiled ->
        compile_block(rest, acc ++ [compiled])

      compiled when is_list(compiled) ->
        compile_block(rest, acc ++ compiled)
    end
  end

  def compile_block([], acc), do: {:__block__, [], acc}

  @doc """
  Compiles a `execute` block to a paramater block

  # Example
  The body of this `execute` node

      {
        "kind": "execute",
        "args": {
          "sequence_id": 123
        },
        "body": [
          {
            "kind": "variable_declaration",
            "args": {
              "label": "variable_in_this_scope",
              "data_value": {
                "kind": "identifier",
                "args": {
                  "label": "variable_in_next_scope"
                }
              }
            }
          }
        ]
      }

  Would be compiled to:

      [variable_in_next_scope: variable_in_this_scope]
  """
  def compile_params_to_function_args(list, acc \\ [])

  def compile_params_to_function_args(
        [%{kind: :parameter_application, args: args} | rest],
        acc
      ) do
    %{
      label: next_scope_var_name,
      data_value: data_value
    } = args

    next_scope_var_name = IdentifierSanitizer.to_variable(next_scope_var_name)
    # next_value = compile_ast(data_value)

    var =
      quote location: :keep do
        {unquote(next_scope_var_name), unquote(compile_ast(data_value))}
      end

    compile_params_to_function_args(rest, [var | acc])
  end

  def compile_params_to_function_args([], acc), do: acc

  @doc """
  Compiles a function block's params.

  # Example
  A `sequence`s `locals` that look like
      {
        "kind": "scope_declaration",
        "args": {},
        "body": [
          {
            "kind": "parameter_declaration",
            "args": {
              "label": "parent",
              "default_value": {
                "kind": "coordinate",
                "args": {
                  "x": 100.0,
                  "y": 200.0,
                  "z": 300.0
                }
            }
          }
        ]
      }

  Would be compiled to

      parent = Keyword.get(params, :parent, %{x: 100, y: 200, z: 300})
  """
  # Add parameter_declaration to the list of implemented kinds
  @kinds "parameter_declaration"
  def compile_param_declaration(%{args: %{label: var_name, default_value: default}}) do
    var_name = IdentifierSanitizer.to_variable(var_name)

    quote location: :keep do
      unquote({var_name, [], __MODULE__}) =
        Keyword.get(params, unquote(var_name), unquote(compile_ast(default)))
    end
  end

  @doc """
  Compiles a function block's assigned value.

  # Example
  A `sequence`s `locals` that look like
      {
        "kind": "scope_declaration",
        "args": {},
        "body": [
          {
            "kind": "parameter_application",
            "args": {
              "label": "parent",
              "data_value": {
                "kind": "coordinate",
                "args": {
                  "x": 100.0,
                  "y": 200.0,
                  "z": 300.0
                }
              }
            }
          }
        ]
      }
  """
  # Add parameter_application to the list of implemented kinds
  @kinds "parameter_application"
  def compile_param_application(%{args: %{label: var_name, data_value: value}}) do
    var_name = IdentifierSanitizer.to_variable(var_name)

    quote location: :keep do
      unquote({var_name, [], __MODULE__}) = unquote(compile_ast(value))
    end
  end

  defp decompose_block_to_steps({:__block__, _, steps} = _orig) do
    Enum.map(steps, fn step ->
      quote location: :keep do
        fn -> unquote(step) end
      end
    end)
  end

  defp delete_me(compiled) do
    compiled
    |> Macro.to_string()
    |> Code.format_string!()
    |> IO.puts()
  end
end
