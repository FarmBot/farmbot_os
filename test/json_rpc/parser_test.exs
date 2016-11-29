defmodule RPC.ParserTest do
  use ExUnit.Case, async: true
  alias RPC.Spec.Notification, as: Notification
  alias RPC.Spec.Request, as: Request
  alias RPC.Spec.Response, as: Response

  test "parses a notification" do
    msg = RPC.Parser.parse(
    %{"id" => nil, "method" => "cry", "params" => [%{"hours" => 3}]})
    assert(%Notification{
      id: nil,
      method: "cry",
      params: [%{"hours" => 3}]
      } == msg)
  end

  test "parses a request" do
    msg = RPC.Parser.parse(
    %{"id" => "OVER NINETHOUSAND", "method" => "cry", "params" => [%{"hours" => 3}]})
    assert(%Request{
      id: "OVER NINETHOUSAND",
      method: "cry",
      params: [%{"hours" => 3}]
      } == msg)
  end

  test "parses a response" do
    msg = RPC.Parser.parse(
    %{"id" => "OVER NINETHOUSAND",
      "error" => nil,
      "result" => "what a good cry"})
    assert(%Response{
      id: "OVER NINETHOUSAND",
      error: nil,
      result: "what a good cry"
      } == msg)
  end
end
