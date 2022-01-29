# Manages state related to CeleryScript's variable scoping.
# These structs are passed between CeleryScript nodes to store
# variable names and values.
defmodule FarmbotOS.Celery.Compiler.Scope do
  alias FarmbotOS.Celery.AST

  defstruct [
    # 25 July 2021: I might remove this later to have scope
    # objects that are easier to `inspect()`.
    parent: nil,
    # Map<string, %AST{}>
    declarations: %{},
    valid: true
  ]

  def new(), do: new(nil, [])

  def new(parent_scope, declaration_array) do
    %__MODULE__{parent: parent_scope}
    |> apply_declarations(declaration_array)
  end

  # Attempts to "fill in the blank" for any missing variable
  # declarations by using the `default_value` in a list of
  # parameter_declarations.
  #
  # GIVEN
  #  * A Scope
  #  * A list of parameter_declarations (%AST{}[])
  # PRODUCES:
  #  * A new scope object.
  def apply_defaults(cs_scope, param_declrs) do
    param_declrs
    |> Enum.filter(fn ast -> ast.kind == :parameter_declaration end)
    |> Enum.map(fn %{args: a} -> {a.label, a.default_value} end)
    |> Enum.reduce(cs_scope, fn {key, value}, state ->
      if has_key?(state, key) do
        state
      else
        set(state, key, value)
      end
    end)
  end

  def has_key?(scope, label), do: Map.has_key?(scope.declarations, label)

  @nothing %AST{kind: :nothing, args: %{}, body: []}
  @not_allowed [
    :location_placeholder,
    :number_placeholder,
    :resource_placeholder,
    :text_placeholder
  ]
  def set(scope, key, value) do
    # If there is a `*_placeholder` node in the scope,
    # it means the user did not supply a value for a
    # parameter. We must exit the CSVM as soon as possible.
    if is_map(value) && Map.get(value, :kind) in @not_allowed do
      FarmbotOS.Celery.SysCallGlue.send_message(
        "error",
        "No value provided for " <> key,
        "toast"
      )

      declr = Map.put(scope.declarations, key, @nothing)
      %{scope | declarations: declr, valid: false}
    else
      %{scope | declarations: Map.put(scope.declarations, key, value)}
    end
  end

  # GIVEN A scope object and a label
  # PRODUCES an %AST{}
  # Raises KeyError if the identifier does not exist.
  def fetch!(scope, label) do
    if has_key?(scope, label) do
      {:ok, Map.fetch!(scope.declarations, label)}
    else
      warn_user_of_bad_var_name!(scope, label)
    end
  end

  # GIVEN
  #  * a parent scope
  #  * A list of `variable_declaration`s `parameter_application` AST nodes
  # PRODUCES a mapping of label (string) to CeleryScript %AST{}
  # maps.
  def apply_declarations(scope, declaration_array) do
    declaration_array
    |> Enum.filter(fn
      %{kind: :parameter_application} -> true
      %{kind: :variable_declaration} -> true
      _other -> false
    end)
    |> Enum.map(fn %{args: a} -> {a.data_value.kind, a.label, a.data_value} end)
    |> Enum.map(fn
      {:identifier, key, value} ->
        {:ok, new_value} = fetch!(scope.parent, value.args.label)
        {key, new_value}

      {_, key, value} ->
        {key, value}
    end)
    |> Enum.reduce(scope, fn {k, v}, declr -> set(declr, k, v) end)
  end

  # This function matters when dealing with point groups.
  # It takes a single scope object.
  # It returns a new scope object for each item in the point group.
  def expand(scope) do
    case get_point_group_ids(scope) do
      [] -> [scope]
      [{label, group_id}] -> do_perform_expansion(scope, {label, group_id})
      _ -> raise "You can only use one point group at a time."
    end
  end

  defp do_perform_expansion(scope, {label, group_id}) do
    case FarmbotOS.Asset.find_points_via_group(group_id) do
      nil ->
        {:error, "Point group not found: #{label}/#{group_id}"}

      pg ->
        group_size = Enum.count(pg.point_ids)

        pg
        |> Map.fetch!(:point_ids)
        |> Enum.map(&point/1)
        |> Enum.with_index(1)
        |> Enum.map(fn {point_ast, index} ->
          meta = %{name: pg.name, current_index: index, size: group_size}

          scope
          |> set(label, point_ast)
          |> set("__GROUP__", meta)
        end)
    end
  end

  # Retrieves all declared identifiers that are point_groups.
  # Return value is a tuple in the form {label, point_group_id}
  defp get_point_group_ids(scope) do
    scope.declarations
    |> Enum.filter(fn {_k, v} -> v.kind == :point_group end)
    |> Enum.map(fn {k, v} -> {k, v.args.point_group_id} end)
  end

  # Helper function that generates a `:point` %AST{}.
  defp point(id) do
    %AST{
      kind: :point,
      args: %{
        pointer_type: "GenericPointer",
        pointer_id: id
      }
    }
  end

  defp warn_user_of_bad_var_name!(scope, label) do
    vars =
      scope.declarations
      |> Map.keys()
      |> Enum.map(&inspect/1)

    msg =
      if Enum.count(vars) == 0 do
        "Attempted to access variable #{inspect(label)}, but no variables are declared."
      else
        all = Enum.join(vars, ", ")
        "Can't find variable #{inspect(label)}. Available variables: " <> all
      end

    {:error, msg}
  end
end
