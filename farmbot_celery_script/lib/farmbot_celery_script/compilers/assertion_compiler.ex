defmodule FarmbotCeleryScript.Compiler.Assertion do
  alias FarmbotCeleryScript.Compiler
  import Compiler.Utils
  @doc "`Assert` is a internal node useful for self testing."
  def assertion(
        %{
          args: %{lua: expression, assertion_type: assertion_type, _then: then_ast},
          comment: comment
        },
        env
      ) do
    comment_header =
      if comment do
        "[#{comment}] "
      else
        "[Assertion] "
      end

    quote location: :keep do
      comment_header = unquote(comment_header)
      assertion_type = unquote(assertion_type)

      case FarmbotCeleryScript.SysCalls.eval_assertion(
             unquote(comment),
             unquote(Compiler.compile_ast(expression, env))
           ) do
        {:error, reason} ->
          FarmbotCeleryScript.SysCalls.log_assertion(
            false,
            assertion_type,
            "#{comment_header}failed to evaluate, aborting"
          )

          {:error, reason}

        true ->
          FarmbotCeleryScript.SysCalls.log_assertion(
            true,
            assertion_type,
            "#{comment_header}passed, continuing execution"
          )

          :ok

        false when assertion_type == "continue" ->
          FarmbotCeleryScript.SysCalls.log_assertion(
            false,
            assertion_type,
            "#{comment_header}failed, continuing execution"
          )

          :ok

        false when assertion_type == "abort" ->
          FarmbotCeleryScript.SysCalls.log_assertion(
            false,
            assertion_type,
            "#{comment_header}failed, aborting"
          )

          {:error, "Assertion failed (aborting)"}

        false when assertion_type == "recover" ->
          FarmbotCeleryScript.SysCalls.log_assertion(
            false,
            assertion_type,
            "#{comment_header}failed, recovering and continuing"
          )

          unquote(compile_block(then_ast, env))

        false when assertion_type == "abort_recover" ->
          FarmbotCeleryScript.SysCalls.log_assertion(
            false,
            assertion_type,
            "#{comment_header}failed, recovering and aborting"
          )

          then_block = unquote(compile_block(then_ast, env))

          then_block ++
            [
              FarmbotCeleryScript.Compiler.compile(%AST{kind: :abort, args: %{}}, [])
            ]
      end
    end
  end
end
