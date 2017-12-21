defmodule FarmbotTestSupport.AST.NodeTestCase do
  use ExUnit.CaseTemplate

  setup do
    {:ok, %{env: struct(Macro.Env, [])}}
  end

  using do
    quote do
      @after_compile(unquote(__MODULE__))

      def assert_cs_env_mutation(impl, %Macro.Env{module: module, file: file}) do
        assert impl == module
        assert to_string(module.module_info[:compile][:source]) == file
      end

      def assert_cs_success(res) do
        assert match?({:ok, %Macro.Env{}}, res)
        res
      end

      def assert_cs_success(res, module) do
        assert match?({:ok, %Farmbot.CeleryScript.AST{kind: module}, %Macro.Env{}}, res)
        res
      end

      def assert_cs_fail(res, reason \\ nil) do
        if reason do
          assert match?({:error, ^reason, %Macro.Env{}}, res)
        else
          assert match?({:error, _, %Macro.Env{}}, res)
        end
      end

      def nothing(env \\ struct(Macro.Env, [])) do
        {:ok, res, _} = Farmbot.CeleryScript.AST.Node.Nothing.execute(%{}, [], env)
        res
      end

    end
  end

  defmacro __after_compile__(env, _) do
    exports = env.module.module_info[:exports]
    unless {:"test mutates env", 1} in exports do
      IO.warn "#{env.module} does not test for env mutation.", []
    end
  end
end
