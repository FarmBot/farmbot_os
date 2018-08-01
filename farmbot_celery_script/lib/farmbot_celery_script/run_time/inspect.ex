defimpl Inspect, for: Farmbot.CeleryScript.RunTime.FarmProc do
  def inspect(data, _opts) do
    "#FarmProc<[#{Farmbot.CeleryScript.RunTime.FarmProc.get_status(data)}] #{
      inspect(Farmbot.CeleryScript.RunTime.FarmProc.get_pc_ptr(data))
    }>"
  end
end
