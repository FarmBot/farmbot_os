defmodule FarmbotCore.Celery.Corpus.ArgTest do
  use ExUnit.Case
  alias FarmbotCore.Celery.Corpus

  test "inspect" do
    assert "#Arg<_then [execute, nothing]>" = inspect(Corpus.arg("_then"))
  end
end
