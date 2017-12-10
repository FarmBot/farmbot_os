defmodule FarmbotTestSupport.AST.ArgTestCase do
  use ExUnit.CaseTemplate

  defmodule ArgFuns do
    def assert_cs_arg_decode_ok(res, val \\ nil) do
      if val do
        assert match?({:ok, ^val}, res)
      else
        assert match?({:ok, _}, res)
      end

      res
    end

    def assert_cs_arg_decode_err(res) do
      assert match?({:error, _}, res)
      res
    end

    def assert_cs_arg_encode_ok(res, val \\ nil) do
      if val do
        assert match?({:ok, ^val}, res)
      else
        assert match?({:ok, _}, res)
      end
      res
    end

    def assert_cs_encode_err(res) do
      assert match?({:error, _}, res)
      res
    end

    defmacro arg_is_ast(mod) do
      quote do
        @nothing_json "{\"kind\": \"nothing\", \"args\": {}}"
        @mod unquote(mod)

        alias Farmbot.CeleryScript.AST

        test "decodes valid ast structure" do
          res = @mod.decode(@nothing_json) |> assert_cs_arg_decode_ok()
          assert match?({:ok, %AST{}}, res)
        end

        test "Won't decode bad data" do
          @mod.decode("this isn't an ast node") |> assert_cs_arg_decode_err
        end

        test "encodes valid ast" do
          {:ok, ast} = AST.decode(@nothing_json)
          @mod.encode(ast) |> assert_cs_arg_decode_ok
        end

        test "wont encode bad data" do
          @mod.encode("this isn't an ast node") |> assert_cs_encode_err
        end
      end
    end
  end

  using do
    quote do
      import ArgFuns
    end
  end
end
