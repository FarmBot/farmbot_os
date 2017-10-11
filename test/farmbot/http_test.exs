defmodule Farmbot.HTTPTest do
  @moduledoc "Http tests"

  use ExUnit.Case
  alias Farmbot.HTTP

  setup_all do
    # Starts a http client but with no token. This module does not make any http requests.
    {:ok, http} = Farmbot.HTTP.start_link(nil, [])
    %{http: http}
  end

  test "bang functions raise an error", %{http: http} do
    assert_raise HTTP.Error, fn ->
      HTTP.request!(http, :get, "https://some_not_real_url.blerp")
    end
  end

  @moduletag [external: true]

  @tag :httpbin
  test "makes a basic http request", %{http: http} do
    r = HTTP.request(http, :get, "https://httpbin.org")
    assert match?({:ok, _}, r)
    {:ok, resp} = r
    assert resp.status_code == 200
    assert resp.body =~ "<!DOCTYPE html>"
  end

  @tag :httpbin
  test "ensures we use the farmbot os user-agent", %{http: http} do
    {:ok, resp} = HTTP.request(http, :get, "https://httpbin.org/user-agent")
    {:ok, json} = Poison.decode(resp.body)
    assert json["user-agent"]
    assert json["user-agent"] =~ "FarmbotOS"
  end

  @tag :httpbin
  test "makes a post request", %{http: http} do
    r = HTTP.post(http, "https://httpbin.org/post", "some data")
    assert match?({:ok, _}, r)
    {:ok, resp} = r
    assert resp.status_code == 200
    assert resp.body =~ "\"some data\""

    r = HTTP.post!(http, "https://httpbin.org/post", "some more data")
    refute match?({:ok, _}, r)
    assert r.status_code == 200
    assert r.body =~ "\"some more data\""
  end

  @tag :httpbin
  test "makes a patch request", %{http: http} do
    r = HTTP.patch(http, "https://httpbin.org/patch", "some patch data")
    assert match?({:ok, _}, r)
    {:ok, resp} = r
    assert resp.status_code == 200
    assert resp.body =~ "\"some patch data\""

    r = HTTP.patch!(http, "https://httpbin.org/patch", "some more patch data")
    refute match?({:ok, _}, r)
    assert r.status_code == 200
    assert r.body =~ "\"some more patch data\""
  end

  @tag :httpbin
  test "makes a put request", %{http: http} do
    r = HTTP.put(http, "https://httpbin.org/put", "some put data")
    assert match?({:ok, _}, r)
    {:ok, resp} = r
    assert resp.status_code == 200
    assert resp.body =~ "\"some put data\""

    r = HTTP.put!(http, "https://httpbin.org/put", "some more put data")
    refute match?({:ok, _}, r)
    assert r.status_code == 200
    assert r.body =~ "\"some more put data\""
  end

  @tag :httpbin
  test "makes a delete request", %{http: http} do
    r = HTTP.delete(http, "https://httpbin.org/delete", "some delete data")
    assert match?({:ok, _}, r)
    {:ok, resp} = r
    assert resp.status_code == 200
    assert resp.body =~ "\"some delete data\""

    r = HTTP.delete!(http, "https://httpbin.org/delete", "some more delete data")
    refute match?({:ok, _}, r)
    assert r.status_code == 200
    assert r.body =~ "\"some more delete data\""
  end

  @tag :httpbin
  test "makes a get request", %{http: http} do
    r = HTTP.get(http, "https://httpbin.org/get")
    assert match?({:ok, _}, r)
    {:ok, resp} = r
    assert resp.status_code == 200
    assert resp.body =~ "\"https://httpbin.org/get\""

    r = HTTP.get!(http, "https://httpbin.org/get")
    refute match?({:ok, _}, r)
    assert r.status_code == 200
    assert r.body =~ "\"https://httpbin.org/get\""
  end

  @tag :httpbin
  test "raises if the response isnt 2xx", %{http: http} do
    assert_raise HTTP.Error, fn ->
      HTTP.request!(http, :get, "https://httpbin.org/status/404")
    end
  end

  test "bang functions only return the HTTP.Response", %{http: http} do
    r = HTTP.request!(http, :get, "https://google.com")
    refute match?({:ok, _}, r)
    assert r.status_code == 200
  end
end
