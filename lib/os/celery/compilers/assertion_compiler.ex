defmodule FarmbotOS.Celery.Compiler.Assertion do
  alias FarmbotOS.Celery.Compiler
  @doc "`Assert` is a internal node useful for self testing."
  def assertion(
        %{
          args: %{
            lua: expression,
            assertion_type: assertion_type,
            _then: then_ast
          },
          comment: comment
        },
        cs_scope
      ) do
    comment_header =
      if comment do
        "[#{comment}] "
      else
        "[Assertion] "
      end

    lua_code = Compiler.celery_to_elixir(expression, cs_scope)
    result = FarmbotOS.Celery.Compiler.Lua.do_lua(lua_code, cs_scope)

    quote location: :keep do
      comment_header = unquote(comment_header)
      assertion_type = unquote(assertion_type)
      cs_scope = unquote(cs_scope)
      result = unquote(result)

      case result do
        {:error, reason} ->
          FarmbotOS.Celery.SysCallGlue.log_assertion(
            false,
            assertion_type,
            "#{comment_header}failed to evaluate, aborting"
          )

          {:error, reason}

        {:ok, [true]} ->
          FarmbotOS.Celery.SysCallGlue.log_assertion(
            true,
            assertion_type,
            "#{comment_header}passed, continuing execution"
          )

          :ok

        {:ok, _} when assertion_type == "continue" ->
          FarmbotOS.Celery.SysCallGlue.log_assertion(
            false,
            assertion_type,
            "#{comment_header}failed, continuing execution"
          )

          :ok

        {:ok, _} when assertion_type == "abort" ->
          FarmbotOS.Celery.SysCallGlue.log_assertion(
            false,
            assertion_type,
            "#{comment_header}failed, aborting"
          )

          {:error, "Assertion failed (aborting)"}

        {:ok, _} when assertion_type == "recover" ->
          FarmbotOS.Celery.SysCallGlue.log_assertion(
            false,
            assertion_type,
            "#{comment_header}failed, recovering and continuing"
          )

          unquote(Compiler.Utils.compile_block(then_ast, cs_scope))

        {:ok, _} when assertion_type == "abort_recover" ->
          FarmbotOS.Celery.SysCallGlue.log_assertion(
            false,
            assertion_type,
            "#{comment_header}failed, recovering and aborting"
          )

          then_block = unquote(Compiler.Utils.compile_block(then_ast, cs_scope))
          abort = %FarmbotOS.Celery.AST{kind: :abort, args: %{}}

          then_block ++
            [
              FarmbotOS.Celery.Compiler.compile(abort, cs_scope)
            ]
      end
    end
  end
end
