defmodule RPC.SpecTest do
  use ExUnit.Case, async: true
  alias RPC.Spec.Request, as: Request
  alias RPC.Spec.Response, as: Response
  alias RPC.Spec.Notification, as: Notification

  test "builds a request" do
    hopefully_request =
    Request.create(%{"method" => "pickle_a_pinecone",
                     "params" => [],
                     "id" => "12345"})
    assert(hopefully_request.method == "pickle_a_pinecone")
    assert(hopefully_request.params == [])
    assert(hopefully_request.id == "12345")
  end

  test "builds a response" do
    hopefully_response =
    Response.create(%{"result" => "a_pickled_pinecone",
                     "error" => nil,
                     "id" => "12345"})
    assert(hopefully_response.result == "a_pickled_pinecone")
    assert(hopefully_response.error == nil)
    assert(hopefully_response.id == "12345")
  end

  test "builds a notification" do
    hopefully_notification =
    Notification.create(%{
      "method" => "pinecone_pickling",
      "params" => [%{"percent" => 44}],
      "id" => nil
      })
    assert(hopefully_notification.method == "pinecone_pickling")
    assert(hopefully_notification.params == [%{"percent" => 44}])
    assert(hopefully_notification.id == nil)
  end
end
