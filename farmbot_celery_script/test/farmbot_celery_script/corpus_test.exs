defmodule Farmbot.CeleryScript.CorpusTest do
  use ExUnit.Case, async: true
  alias Farmbot.CeleryScript.Corpus

  test "lists all node names" do
    assert "sequence" in Corpus.all_node_names()
    assert "move_absolute" in Corpus.all_node_names()
  end

  test "gets a node spec by its name" do
    assert match?(%{name: "sequence", allowed_args: _}, Corpus.node("sequence"))
    assert match?(%{name: "sequence", allowed_args: _}, Corpus.node(:sequence))
  end

  test "gets a node by a defined function" do
    assert match?(%{name: "sequence", allowed_args: _}, Corpus.sequence())
  end

  test "list all arg names" do
    assert "_else" in Corpus.all_arg_names()
    assert "location" in Corpus.all_arg_names()
  end

  test "gets a arg spec by it's name" do
    assert match?(%{name: "_else"}, Corpus.arg("_else"))
    assert match?(%{name: "_else"}, Corpus.arg(:_else))
  end
end
