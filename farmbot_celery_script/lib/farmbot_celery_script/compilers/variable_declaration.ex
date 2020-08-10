defmodule FarmbotCeleryScript.Compiler.VariableDeclaration do
  alias FarmbotCeleryScript.{Compiler, Compiler.IdentifierSanitizer}

  @doc "Compiles a variable asignment"
  def variable_declaration(
        %{args: %{label: var_name, data_value: data_value_ast}},
        env
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
    var_name = IdentifierSanitizer.to_variable(var_name)

    quote location: :keep do
      # ===
      unquote({var_name, [], nil}) =
        unquote(Compiler.compile_ast(data_value_ast, env))
        _ = inspect(unquote({var_name, [], nil}))
    end
  end
end
