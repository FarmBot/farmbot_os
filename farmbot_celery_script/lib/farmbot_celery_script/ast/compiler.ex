defmodule Farmbot.CeleryScript.AST.Compiler do
  @moduledoc """
  Responsible for compiling canonical CeleryScript AST into 
  Elixir AST.
  """

  alias Farmbot.CeleryScript.AST

  @doc """
  Recursive function that will emit Elixir AST from CeleryScript AST.

  ## CeleryEnv
  A keyword list of the compile environment.
  * resource_id
  * resource_type
  """
  def compile(ast, celery_env \\ [resource_id: 0, resource_type: "unspecified"])

  # Compiles a `sequence` into an Elixir `fn`.
  def compile(
        %AST{kind: :sequence, args: %{locals: %{body: params}}, body: block} = ast,
        celery_env
      ) do
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

    quote do
      fn params ->
        # Fetches variables from the previous execute()
        # example:
        # parent = Keyword.fetch!(params, :parent)
        unquote_splicing(params)
        # Unquote the remaining sequence steps.
        unquote(compile_block(body ++ block, celery_env))
      end
    end
    |> add_meta(ast, celery_env)
  end

  # Compiles a variable asignment. 
  def compile(
        %AST{kind: :variable_declaration, args: %{label: var_name, data_value: data_value_ast}} =
          ast,
        celery_env
      ) do
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
    {:=, [], [{String.to_atom(var_name), [], __MODULE__}, compile(data_value_ast, celery_env)]}
    |> add_meta(ast, celery_env)
  end

  # Compiles an if statement.
  def compile(
        %AST{
          kind: :_if,
          args: %{_then: then_ast, _else: else_ast, lhs: lhs, op: op, rhs: rhs}
        } = ast,
        celery_env
      ) do
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
        "pin" <> pin -> {:read_pin, [], [String.to_integer(pin), nil]}
        %AST{} = ast -> compile(ast, celery_env)
      end

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
          # The ast will look like: {:==, [], lhs, compile(rhs)}
          quote do
            unquote(lhs) == unquote(compile(rhs, celery_env))
          end

        "not" ->
          # ast will look like: {:!=, [], [lhs, compile(rhs)]}
          quote do
            unquote(lhs) != unquote(compile(rhs, celery_env))
          end

        "is_undefined" ->
          # ast will look like: {:is_nil, [], [lhs]}
          quote do
            is_nil(unquote(lhs))
          end

        "<" ->
          # ast will look like: {:<, [], [lhs, compile(rhs)]}
          quote do
            unquote(lhs) < unquote(compile(rhs, celery_env))
          end

        ">" ->
          # ast will look like: {:>, [], [lhs, compile(rhs)]}
          quote do
            unquote(lhs) > unquote(compile(rhs, celery_env))
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
        do: unquote(compile_block(then_ast, celery_env)),
        else: unquote(compile_block(else_ast, celery_env))
    end
    |> add_meta(ast, celery_env)
  end

  # Compiles an `execute` block.
  def compile(
        %AST{kind: :execute, args: %{sequence_id: id}, body: variable_declarations} = ast,
        celery_env
      ) do
    quote do
      # We have to lookup the sequence by it's id. 
      case get_sequence(unquote(id)) do
        {:ok, %AST{} = ast, new_celery_env} ->
          # compile the ast
          fun = unquote(__MODULE__).compile(ast, new_celery_env)
          # And call it, serializing all the variables it expects.
          # see the `compile_param_application/1` docs for more info.
          fun.(unquote(compile_param_application(variable_declarations)))

        err ->
          handle_error(err)
      end
    end
    |> add_meta(ast, celery_env)
  end

  # Compiles `execute_script`
  # TODO(Connor) - make this actually usable
  def compile(
        %AST{kind: :execute_script, args: %{label: package}, body: params} = ast,
        celery_env
      ) do
    env =
      Enum.map(params, fn %{args: %{label: key, value: value}} ->
        {to_string(key), value}
      end)

    quote do
      execute_script(unquote(package), unquote(Map.new(env)))
    end
    |> add_meta(ast, celery_env)
  end

  # TODO(Connor) - see above TODO
  def compile(%AST{kind: :take_photo} = ast, celery_env) do
    # {:execute_script, [], ["take_photo", {:%{}, [], []}]}
    quote do
      execute_script("take_photo", %{})
    end
    |> add_meta(ast, celery_env)
  end

  # Compiles a nothing block. 
  def compile(%AST{kind: :nothing} = ast, celery_env) do
    # AST looks like: {:nothing, [], []}
    quote do
      nothing()
    end
    |> add_meta(ast, celery_env)
  end

  # Compiles move_absolute
  def compile(
        %AST{
          kind: :move_absolute,
          args: %{location: location, offset: offset, speed: speed}
        } = ast,
        celery_env
      ) do
    quote do
      # Extract the location arg
      %{x: locx, y: locy, z: locz} = unquote(compile(location, celery_env))
      # Extract the offset arg
      %{x: offx, y: offy, z: offz} = unquote(compile(offset, celery_env))

      # Subtract the location from offset.
      # Note: list syntax here for readability. 
      [x, y, z] = [offx - locx, offy - locy, offz - locz]
      move_absolute(x, y, z, unquote(compile(speed, celery_env)))
    end
    |> add_meta(ast, celery_env)
  end

  # compiles move_relative into move absolute
  def compile(
        %AST{kind: :move_relative, args: %{x: x, y: y, z: z, speed: speed}} = ast,
        celery_env
      ) do
    quote do
      # build a vec3 of passed in args
      %{x: locx, y: locy, z: locz} = %{
        x: unquote(compile(x, celery_env)),
        y: unquote(compile(y, celery_env)),
        z: unquote(compile(z, celery_env))
      }

      # build a vec3 of the current position
      %{x: offx, y: offy, z: offz} = %{
        x: get_current_x(),
        y: get_current_y,
        z: get_current_y()
      }

      # Subtract the location from offset.
      # Note: list syntax here for readability. 
      [x, y, z] = [offx - locx, offy - locy, offz - locz]
      move_absolute(x, y, z, unquote(compile(speed, celery_env)))
    end
    |> add_meta(ast, celery_env)
  end

  # compiles write_pin
  def compile(
        %AST{kind: :write_pin, args: %{pin_number: num, pin_mode: mode, pin_value: val}} = ast,
        celery_env
      ) do
    quote do
      write_pin(
        unquote(compile(num, celery_env)),
        unquote(compile(mode, celery_env)),
        unquote(compile(val, celery_env))
      )
    end
    |> add_meta(ast, celery_env)
  end

  # compiles read_pin
  def compile(%AST{kind: :read_pin, args: %{pin_number: num, pin_mode: mode}} = ast, celery_env) do
    quote do
      read_pin(unquote(compile(num, celery_env)), unquote(compile(mode, celery_env)))
    end
    |> add_meta(ast, celery_env)
  end

  # Expands find_home(all) into three find_home/1 calls
  def compile(%AST{kind: :find_home, args: %{axis: "all", speed: speed}} = ast, celery_env) do
    quote do
      find_home("x", unquote(compile(speed, celery_env)))
      find_home("y", unquote(compile(speed, celery_env)))
      find_home("z", unquote(compile(speed, celery_env)))
    end
    |> add_meta(ast, celery_env)
  end

  # compiles find_home
  def compile(%AST{kind: :find_home, args: %{axis: axis, speed: speed}} = ast, celery_env) do
    quote do
      find_home(unquote(compile(axis, celery_env)), unquote(compile(speed, celery_env)))
    end
    |> add_meta(ast, celery_env)
  end

  # compiles wait
  def compile(%AST{kind: :wait, args: %{milliseconds: millis}} = ast, celery_env) do
    quote do
      find_home(unquote(compile(millis, celery_env)))
    end
    |> add_meta(ast, celery_env)
  end

  # compiles send_message
  def compile(
        %AST{kind: :send_message, args: %{message: msg, message_type: type}, body: channels} =
          ast,
        celery_env
      ) do
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
        unquote(compile(type, celery_env)),
        unquote(compile(msg, celery_env)),
        unquote(channels)
      )
    end
    |> add_meta(ast, celery_env)
  end

  # compiles coordinate
  # Coordinate should return a vec3
  def compile(%AST{kind: :coordinate, args: %{x: x, y: y, z: z}} = ast, celery_env) do
    quote do
      coordinate(
        unquote(compile(x, celery_env)),
        unquote(compile(y, celery_env)),
        unquote(compile(z, celery_env))
      )
    end
    |> add_meta(ast, celery_env)
  end

  # compiles point 
  def compile(%AST{kind: :point, args: %{pointer_type: type, pointer_id: id}} = ast, celery_env) do
    quote do
      point(unquote(compile(type, celery_env)), unquote(compile(id, celery_env)))
    end
    |> add_meta(ast, celery_env)
  end

  # compile a named pin
  def compile(%AST{kind: :named_pin, args: %{pin_id: id, pin_type: type}} = ast, celery_env) do
    quote do
      pin(unquote(compile(type, celery_env)), unquote(compile(id, celery_env)))
    end
    |> add_meta(ast, celery_env)
  end

  # compiles identifier into a variable.
  # We have to use Elixir ast syntax here because
  # var! doesn't work quite the way we want.
  def compile(%AST{kind: :identifier, args: %{label: var_name}} = ast, celery_env) do
    meta = [celery_kind: :identifier, celery_comments: []]

    {String.to_atom(var_name), meta, __MODULE__}
    |> add_meta(ast, celery_env)
  end

  # Numbers and strings are treated as literals.
  def compile(lit, _celery_env) when is_number(lit), do: lit
  def compile(lit, _celery_env) when is_binary(lit), do: lit

  @doc """
  Recursively compiles a list or single Celery AST into an Elixir `__block__` 
  """
  def compile_block(asts, celery_env, acc \\ [])

  def compile_block(%AST{} = ast, celery_env, _) do
    case compile(ast, celery_env) do
      {_, _, _} = compiled ->
        {:__block__, [], [compiled]}

      compiled when is_list(compiled) ->
        {:__block__, [], compiled}
    end
  end

  def compile_block([ast | rest], celery_env, acc) do
    case compile(ast, celery_env) do
      {_, _, _} = compiled ->
        compile_block(rest, celery_env, acc ++ [compiled])

      compiled when is_list(compiled) ->
        compile_block(rest, celery_env, acc ++ compiled)
    end
  end

  def compile_block([], _, acc), do: {:__block__, [], acc}

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

  @doc "Adds metadata about a celery ast to the resulting elixir ast."
  def add_meta({a, meta, body}, %AST{kind: kind, comment: comment}, more \\ []) do
    meta =
      meta
      |> Keyword.update(:celery_comments, [comment], fn comments ->
        (comment || []) ++ comments
      end)
      |> Keyword.put(:celery_kind, kind)
      |> Keyword.merge(more)

    {a, meta, body}
  end
end
