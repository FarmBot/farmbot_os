defmodule Module.concat([Farmbot,System,"host", Benchmarks]) do
  @moduledoc """
    Various stuff for benchmarks.
  """
  @doc """
    Average the amount of time it takes to hit teh sync object
  """
  # TODO(Connor) make these not anon functions. was a Copy paste job.
  def sync_object_average(times) do
    f = fn(marker) ->
      now = :erlang.system_time(:seconds)
      Farmbot.Sync.sync
      nowa = :erlang.system_time(:seconds)
      nowa - now
    end

    g = fn(t) ->
      list = Enum.reduce(0..t, [], fn(cur, acc) ->
        time = f.(cur)
        [time | acc]
      end)
      |> Enum.reverse
      (Enum.sum(list) / Enum.count(list))
    end
    g.(times)
  end
end
