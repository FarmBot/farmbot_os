defmodule Farmbot.Target.Network.ScanResult do
  @moduledoc "Decoded from Nerves.Network scanning."

  alias Farmbot.Target.Network.ScanResult

  defstruct [
    :ssid, # ssid name
    :bssid, # usually macaddress.
    :noise, # signal noise in dBm.
    :level,  # Signal level in dBm.
    :capabilities, # Don't actually need this.
    :flags, # Used to decide security.
    :security # This feild is guessed.
  ]

  @doc "Decodes a map into a ScanResult, or a list of maps into a list of ScanResult."
  def decode(list) when is_list(list) do
    Enum.map(list, &decode(&1))
  end

  def decode(%{} = map) do
    struct(ScanResult, map)
  end


  @doc "Sorts a list of ssids by their level. This does not take noise into account."
  def sort_results(results) do
    # Pardon the magic.
    Enum.sort(results, &Kernel.>=(Map.get(&1, :level), Map.get(&2, :level)))
  end

  @doc "Tries to guess the security type of a network. Needs work."
  def decode_security(results) when is_list(results) do
    Enum.map(results, &decode_security(&1))
  end

  def decode_security(%{flags: flags} = scan_result) do
    Map.put(scan_result, :security, decode_security_flags(flags))
  end

  def decode_security_flags(str, state \\ %{in_flag: false, buffer: <<>>, acc: []})
  def decode_security_flags(<<>>, %{acc: acc}), do: Enum.reverse(acc) |> decode_security_acc()

  def decode_security_flags(<<"[", rest :: binary>>, %{in_flag: false} = state) do
    decode_security_flags(rest, %{state | in_flag: true, buffer: <<>>})
  end

  def decode_security_flags(<<"]", rest :: binary>>, %{in_flag: true, buffer: buffer, acc: acc} = state) do
    decode_security_flags(rest, %{state | in_flag: false, buffer: <<>>, acc: [buffer | acc]})
  end

  def decode_security_flags(<<char :: binary-size(1), rest :: binary>>, %{in_flag: true} = state) do
    decode_security_flags(rest, %{state | buffer: state.buffer <> char})
  end

  def decode_security_acc(list, security \\ :NONE)

  def decode_security_acc([<<"WPA2-EAP", _ :: binary>> | rest], _) do
    decode_security_acc(rest, :"WPA-EAP")
  end

  def decode_security_acc([<<"WPA2-PSK", _ :: binary>> | rest], _) do
    decode_security_acc(rest, :"WPA-PSK")
  end

  def decode_security_acc([<<"WPA-PSK", _ :: binary>> | rest], _) do
    decode_security_acc(rest, :"WPA-PSK")
  end

  def decode_security_acc([_unknown_flag | rest], security) do
    decode_security_acc(rest, security)
  end

  def decode_security_acc([], security), do: security
end
