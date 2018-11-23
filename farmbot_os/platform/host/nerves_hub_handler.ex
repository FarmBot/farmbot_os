defmodule Farmbot.Host.NervesHubHandler do
  @behaviour Farmbot.System.NervesHub

  def serial_number do
    {:ok, [_ | [{_ifname, info} | _]]} = :inet.getifaddrs()

    :io_lib.format('~2.16.0B~2.16.0B~2.16.0B~2.16.0B~2.16.0B~2.16.0B', info[:hwaddr])
    |> to_string()
    |> String.trim()
  end

  def connect, do: :ok

  def provision(_serial), do: :ok

  def configure_certs(_cert, _key), do: :ok

  def deconfigure, do: :ok

  def config,
    do: [
      serial_number(),
      "Not a real cert",
      "Not a real key"
    ]

  def check_update, do: nil

  def uuid, do: "1b10e3bb-ca47-52b1-f147-691fb90ebdd5"
end
