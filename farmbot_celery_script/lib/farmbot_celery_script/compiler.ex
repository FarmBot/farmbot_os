defmodule Farmbot.CeleryScript.Compiler do
  @moduledoc """
  Responsible for compiling canonical CeleryScript AST into
  Elixir AST.
  """

  alias Farmbot.CeleryScript.{AST, Compiler}
  use Compiler.Tools
  @valid_entry_points [:sequence, :rpc_request]

  @doc """
  Recursive function that will emit Elixir AST from CeleryScript AST.
  """
  def compile(%AST{kind: kind} = ast, env \\ []) when kind in @valid_entry_points do
    # compile the ast
    {_, _, _} = compiled = compile_ast(ast)
    # entry points must be evaluated once more with the calling `env`
    # to return a list of compiled `steps`
    case Code.eval_quoted(compiled, []) do
      {fun, _} when is_function(fun, 1) -> apply(fun, [env])
      {{:error, error}, _} -> {:error, error}
    end
  end

  # Compiles a `sequence` into an Elixir `fn`.
  def compile_ast(%AST{kind: :sequence, args: %{locals: %{body: params}}, body: block}) do
    # Sort the args.body into two arrays.
    # The `params` side gets turned into
    # a keyword list. These `params` are passed in from a previous sequence.
    # The `body` side declares variables in _this_ scope.
    {params, body} =
      Enum.reduce(params, {[], []}, fn ast, {params, body} = _acc ->
        case ast do
          %{kind: :parameter_declaration} -> {params ++ [compile_param_declaration(ast)], body}
          %{kind: :variable_declaration} -> {params, body ++ [ast]}
        end
      end)

    assignments = compile_block(body)
    steps = compile_block(block) |> decompose_block_to_steps()

    quote do
      fn params ->
        import Farmbot.CeleryScript.Syscalls
        # Fetches variables from the previous execute()
        # example:
        # parent = Keyword.fetch!(params, :parent)
        unquote_splicing(params)
        # Unquote the remaining sequence steps.
        unquote(assignments)
        unquote(steps)
      end
    end
  end

  # Compiles a variable asignment.
  def compile_ast(%AST{
        kind: :variable_declaration,
        args: %{label: var_name, data_value: data_value_ast}
      }) do
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
    {:=, [], [{String.to_atom(var_name), [], __MODULE__}, compile_ast(data_value_ast)]}
  end

  # Compiles an if statement.
  def compile_ast(%AST{
        kind: :_if,
        args: %{_then: then_ast, _else: else_ast, lhs: lhs, op: op, rhs: rhs}
      }) do
    # Turns the left hand side arg into
    # a number. x, y, z, and pin{number} are special that need to be
    # evaluated before evaluating the if statement.
    # any AST is also aloud to be on the lefthand side as
    # well, so if that is the case, compile it first.
    lhs =
      case lhs do
        "x" -> quote do: get_current_x()
        "y" -> quote do: get_current_y()
        "z" -> quote do: get_current_z()
        "pin" <> pin -> quote do: read_pin(unquote(String.to_integer(pin)), nil)
        %AST{} = ast -> compile_ast(ast)
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
          quote do
            unquote(lhs) == unquote(rhs)
          end

        "not" ->
          # ast will look like: {:!=, [], [lhs, compile_ast(rhs)]}
          quote do
            unquote(lhs) != unquote(rhs)
          end

        "is_undefined" ->
          # ast will look like: {:is_nil, [], [lhs]}
          quote do
            is_nil(unquote(lhs))
          end

        "<" ->
          # ast will look like: {:<, [], [lhs, compile_ast(rhs)]}
          quote do
            unquote(lhs) < unquote(rhs)
          end

        ">" ->
          # ast will look like: {:>, [], [lhs, compile_ast(rhs)]}
          quote do
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
    quote do
      if unquote(if_eval),
        do: unquote(compile_block(then_ast)),
        else: unquote(compile_block(else_ast))
    end
  end

  # Compiles an `execute` block.
  def compile_ast(%AST{kind: :execute, args: %{sequence_id: id}, body: variable_declarations}) do
    quote do
      # We have to lookup the sequence by it's id.
      %Farmbot.CeleryScript.AST{} = ast = get_sequence(unquote(id))
      # compile the ast
      compiled_fun = unquote(__MODULE__).compile(ast)

      # And call it, serializing all the variables it expects.
      # see the `compile_param_application/1` docs for more info.
      compiled_fun.(unquote(compile_param_application(variable_declarations)))
    end
  end

  # Compiles `execute_script`
  # TODO(Connor) - make this actually usable
  def compile_ast(%AST{kind: :execute_script, args: %{label: package}, body: params}) do
    env =
      Enum.map(params, fn %{args: %{label: key, value: value}} ->
        {to_string(key), value}
      end)

    quote do
      execute_script(unquote(package), unquote(Macro.escape(Map.new(env))))
    end
  end

  # TODO(Connor) - see above TODO
  def compile_ast(%AST{kind: :take_photo}) do
    # {:execute_script, [], ["take_photo", {:%{}, [], []}]}
    quote do
      execute_script("take_photo", %{})
    end
  end

  # Compiles a nothing block.
  def compile_ast(%AST{kind: :nothing}) do
    # AST looks like: {:nothing, [], []}
    quote do
      nothing()
    end
  end

  # Compiles move_absolute
  def compile_ast(%AST{
        kind: :move_absolute,
        args: %{location: location, offset: offset, speed: speed}
      }) do
    quote do
      # Extract the location arg
      %{x: locx, y: locy, z: locz} = unquote(compile_ast(location))
      # Extract the offset arg
      %{x: offx, y: offy, z: offz} = unquote(compile_ast(offset))

      # Subtract the location from offset.
      # Note: list syntax here for readability.
      [x, y, z] = [offx - locx, offy - locy, offz - locz]
      move_absolute(x, y, z, unquote(compile_ast(speed)))
    end
  end

  # compiles move_relative into move absolute
  def compile_ast(%AST{kind: :move_relative, args: %{x: x, y: y, z: z, speed: speed}}) do
    quote do
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
  def compile_ast(%AST{kind: :write_pin, args: %{pin_number: num, pin_mode: mode, pin_value: val}}) do
    quote do
      write_pin(
        unquote(compile_ast(num)),
        unquote(compile_ast(mode)),
        unquote(compile_ast(val))
      )
    end
  end

  # compiles read_pin
  def compile_ast(%AST{kind: :read_pin, args: %{pin_number: num, pin_mode: mode}}) do
    quote do
      read_pin(unquote(compile_ast(num)), unquote(compile_ast(mode)))
    end
  end

  # Expands find_home(all) into three find_home/1 calls
  def compile_ast(%AST{kind: :find_home, args: %{axis: "all", speed: speed}}) do
    quote do
      find_home("x", unquote(compile_ast(speed)))
      find_home("y", unquote(compile_ast(speed)))
      find_home("z", unquote(compile_ast(speed)))
    end
  end

  # compiles find_home
  def compile_ast(%AST{kind: :find_home, args: %{axis: axis, speed: speed}}) do
    quote do
      find_home(unquote(compile_ast(axis)), unquote(compile_ast(speed)))
    end
  end

  # compiles wait
  # def compile_ast(%AST{kind: :wait, args: %{milliseconds: millis}}) do
  #   quote do
  #     find_home(unquote(compile_ast(millis)))
  #   end
  # end

  compile :wait, %{milliseconds: millis} do
    quote do
      find_home(unquote(compile_ast(millis)))
    end
  end

  # # compiles send_message
  # def compile_ast(%AST{
  #       kind: :send_message,
  #       args: %{message: msg, message_type: type},
  #       body: channels
  #     }) do
  #   # body gets turned into a list of atoms.
  #   # Example:
  #   #   [{kind: "channel", args: {channel_name: "email"}}]
  #   # is turned into:
  #   #   [:email]
  #   channels =
  #     Enum.map(channels, fn %{kind: :channel, args: %{channel_name: channel_name}} ->
  #       String.to_atom(channel_name)
  #     end)

  #   quote do
  #     # send_message("success", "Hello world!", [:email, :toast])
  #     send_message(
  #       unquote(compile_ast(type)),
  #       unquote(compile_ast(msg)),
  #       unquote(channels)
  #     )
  #   end
  # end

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

    quote do
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
  def compile_ast(%AST{kind: :coordinate, args: %{x: x, y: y, z: z}}) do
    quote do
      coordinate(
        unquote(compile_ast(x)),
        unquote(compile_ast(y)),
        unquote(compile_ast(z))
      )
    end
  end

  # compiles point
  def compile_ast(%AST{kind: :point, args: %{pointer_type: type, pointer_id: id}}) do
    quote do
      point(unquote(compile_ast(type)), unquote(compile_ast(id)))
    end
  end

  # compile a named pin
  def compile_ast(%AST{kind: :named_pin, args: %{pin_id: id, pin_type: type}}) do
    quote do
      pin(unquote(compile_ast(type)), unquote(compile_ast(id)))
    end
  end

  # compiles identifier into a variable.
  # We have to use Elixir ast syntax here because
  # var! doesn't work quite the way we want.
  def compile_ast(%AST{kind: :identifier, args: %{label: var_name}}) do
    {String.to_atom(var_name), [], __MODULE__}
  end

  # Numbers and strings are treated as literals.
  def compile_ast(lit) when is_number(lit), do: lit
  def compile_ast(lit) when is_binary(lit), do: lit

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
  def compile_param_application(list, acc \\ [])

  def compile_param_application(
        [%{args: %{label: next_scope, data_value: %{args: %{label: current_scope}}}} | rest],
        acc
      ) do
    var = {String.to_atom(next_scope), {String.to_atom(current_scope), [], __MODULE__}}
    compile_param_application(rest, [var | acc])
  end

  def compile_param_application([], acc), do: acc

  @doc """
  Compiles a function blocks params.

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
              "data_type": "point"
            }
          }
        ]
      }

  Would be compiled to

      parent = Keyword.fetch!(params, :parent)
  """
  def compile_param_declaration(%{args: %{label: var_name, data_type: _type}}) do
    var_fetch =
      quote do
        Keyword.fetch!(params, unquote(String.to_atom(var_name)))
      end

    {:=, [], [{String.to_atom(var_name), [], __MODULE__}, var_fetch]}
  end

  defp decompose_block_to_steps({:__block__, _, steps} = _orig) do
    Enum.map(steps, fn step ->
      IO.inspect(step, label: "STEP")

      quote do
        fn ->
          unquote(step)
        end
      end
    end)
  end
end
