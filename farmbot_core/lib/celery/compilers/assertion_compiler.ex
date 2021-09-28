defmodule FarmbotCore.Celery.Compiler.Assertion do
  alias FarmbotCore.Celery.Compiler
  @doc "`Assert` is a internal node useful for self testing."
  def assertion(
        %{
          args: %{
            lua: expression,
            assertion_type: assertion_type,
            _then: then_ast
          },
          comment: comment
        }, cs_scope) do
    comment_header =
      if comment do
        "[#{comment}] "
      else
        "[Assertion] "
      end
    lua_code = Compiler.celery_to_elixir(expression, cs_scope)
    result = FarmbotCore.Celery.Compiler.Lua.do_lua(lua_code, cs_scope)

    quote location: :keep do
      comment_header = unquote(comment_header)
      assertion_type = unquote(assertion_type)
      cs_scope = unquote(cs_scope)
      result = unquote(result)
      case result do
        {:error, reason} ->
          FarmbotCore.Celery.SysCalls.log_assertion(
            false,
            assertion_type,
            "#{comment_header}failed to evaluate, aborting"
          )

          {:error, reason}

        {:ok, [true]} ->
          FarmbotCore.Celery.SysCalls.log_assertion(
            true,
            assertion_type,
            "#{comment_header}passed, continuing execution"
          )

          :ok

        {:ok, _} when assertion_type == "continue" ->
          FarmbotCore.Celery.SysCalls.log_assertion(
            false,
            assertion_type,
            "#{comment_header}failed, continuing execution"
          )

          :ok

        {:ok, _} when assertion_type == "abort" ->
          FarmbotCore.Celery.SysCalls.log_assertion(
            false,
            assertion_type,
            "#{comment_header}failed, aborting"
          )

          {:error, "Assertion failed (aborting)"}

        {:ok, _} when assertion_type == "recover" ->
          FarmbotCore.Celery.SysCalls.log_assertion(
            false,
            assertion_type,
            "#{comment_header}failed, recovering and continuing"
          )

          unquote(Compiler.Utils.compile_block(then_ast, cs_scope))

        {:ok, _} when assertion_type == "abort_recover" ->
          FarmbotCore.Celery.SysCalls.log_assertion(
            false,
            assertion_type,
            "#{comment_header}failed, recovering and aborting"
          )

          then_block = unquote(Compiler.Utils.compile_block(then_ast, cs_scope))
          abort = %FarmbotCore.Celery.AST{kind: :abort, args: %{}}
          then_block ++
            [
              FarmbotCore.Celery.Compiler.compile(abort, cs_scope)
            ]
      end
    end
  end
end
