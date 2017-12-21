defmodule Farmbot.CeleryScript.AST.Arg.LhsTest do
  use FarmbotTestSupport.AST.ArgTestCase
  alias Farmbot.CeleryScript.AST.Arg.Lhs

  test "encodes x axis" do
    Lhs.encode(:x) |> assert_cs_arg_encode_ok("x")
  end

  test "encodes y axis" do
    Lhs.encode(:y) |> assert_cs_arg_encode_ok("y")
  end

  test "encodes z axis" do
    Lhs.encode(:z) |> assert_cs_arg_encode_ok("z")
  end

  test "decodes x axis" do
    Lhs.decode("x") |> assert_cs_arg_decode_ok(:x)
  end

  test "decodes y axis" do
    Lhs.decode("y") |> assert_cs_arg_decode_ok(:y)
  end

  test "decodes z axis" do
    Lhs.decode("y") |> assert_cs_arg_decode_ok(:y)
  end

  test "encodes pin number" do
    Lhs.encode({:pin, 13}) |> assert_cs_arg_encode_ok("pin13")
  end

  test "decodes pin number" do
    Lhs.decode("pin13") |> assert_cs_arg_decode_ok({:pin, 13})
  end

  test "can't decode unknown data" do
    Lhs.decode("some_other_lhs_arg") |> assert_cs_arg_decode_err
  end
end
