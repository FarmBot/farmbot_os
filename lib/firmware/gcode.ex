defmodule FarmbotOS.Firmware.GCode do
  alias FarmbotOS.Firmware.FloatingPoint

  defstruct [:string, :command, :params, :echo]

  def new(command, params) do
    mapper = fn
      {:M, mode} -> "M#{fetch_m!(mode)}"
      {key, value} -> "#{key}#{FloatingPoint.encode(value)}"
    end

    p =
      params
      |> Enum.map(mapper)
      |> Enum.join(" ")

    %__MODULE__{
      string: String.trim("#{command} #{p}"),
      echo: nil,
      command: command,
      params: params
    }
  end

  @m_codes %{
    0 => 0,
    :input => 0,
    "input" => 0,
    "digital" => 0,
    :digital => 0,
    1 => 1,
    "output" => 1,
    :output => 1,
    "analog" => 1,
    :analog => 1,
    2 => 2,
    :input_pullup => 2,
    "input_pullup" => 2
  }

  defp fetch_m!(mode) do
    m = Map.get(@m_codes, mode)

    if m do
      FloatingPoint.encode(m)
    else
      valid_modes =
        @m_codes
        |> Map.keys()
        |> Enum.filter(&is_atom/1)
        |> Enum.sort()

      raise "Expect pin mode to be one of #{inspect(valid_modes)}. Got: #{inspect(mode)}"
    end
  end
end
