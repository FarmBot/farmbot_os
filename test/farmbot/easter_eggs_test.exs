defmodule Farmbot.EasterEggsTest do
  @moduledoc false
  use ExUnit.Case, async: true
  setup_all do
    write_me = test_json() |> Poison.encode!
    File.write!("/tmp/test.json", write_me)
    :ok
  end

  test "starts the server with a path to a file" do
    path = "/tmp/test.json"
    {:ok, pid} = Farmbot.EasterEggs.start_link({:name, :test_1}, {:path, path})
    assert is_pid(pid) == true
  end

  test "starts the server with a json object" do
    json = test_json_with_strings()
    {:ok, pid} = Farmbot.EasterEggs.start_link({:name, :test_2}, {:json, json})
    assert is_pid(pid) == true
  end

  test "adds a new json to the state" do
    path = "/tmp/test.json"
    {:ok, pid} = Farmbot.EasterEggs.start_link({:name, :test_3}, {:path, path})
    assert is_pid(pid) == true
    state1 = GenServer.call(pid, :state)
    assert state1 == %{nouns: %{}, verbs: []}

    new_json = %{"nouns" => [%{"somehting" => "heyo"}], "verbs" => []}
    Farmbot.EasterEggs.load_json(new_json, pid)
    state2 = GenServer.call(pid, :state)
    assert state2 ==  %{nouns: %{somehting: "heyo"}, verbs: []}
  end

  test "logs a thing" do
    path = "/tmp/test.json"
    {:ok, pid} = Farmbot.EasterEggs.start_link({:name, :test_4}, {:path, path})
    assert is_pid(pid) == true
    state1 = GenServer.call(pid, :state)
    assert state1 == %{nouns: %{}, verbs: []}

    GenServer.cast pid, "hey this will get logged but logger is disabled hur dur dur"
    #??? i cant actually test that?
  end

  def test_json do
    %{nouns: [], verbs: []}
  end

  def test_json_with_strings do
    %{"nouns" => [], "verbs" => []}
  end
end
