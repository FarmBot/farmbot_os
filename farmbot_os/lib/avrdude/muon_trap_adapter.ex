defmodule Avrdude.MuonTrapAdapter do
  @type exe :: String.t()
  @type args :: [String.t()]
  @type io_stream :: Enumerable.t()
  @type option :: {:into, io_stream()} | {:stderr_to_stdout, boolean()}

  @callback cmd(exe, args, list(option)) :: {String.t(), non_neg_integer}

  @doc false
  def adapter do
    Application.get_env(:farmbot, :muon_trap_adapter, Avrdude.MuonTrapDefaultAdapter)
  end

  def cmd(exe, args, options) do
    adapter().cmd(exe, args, options)
  end
end
