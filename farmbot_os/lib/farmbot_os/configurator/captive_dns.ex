defmodule FarmbotOS.Configurator.CaptiveDNS do
  use GenServer
  alias __MODULE__, as: State

  defstruct [:dns_socket, :dns_port, :ifname]

  def start_link(ifname, port) do
    GenServer.start_link(__MODULE__, [ifname, port])
  end

  @impl GenServer
  def init([ifname, port]) do
    send(self(), :open_dns)
    # use charlist here because :inet module works with charlists
    {:ok, %State{dns_port: port, ifname: to_charlist(ifname)}}
  end

  @impl GenServer
  # open a UDP socket on port 53
  def handle_info(:open_dns, state) do
    case :gen_udp.open(state.dns_port, [:binary, active: true, reuseaddr: true]) do
      {:ok, socket} ->
        {:noreply, %State{state | dns_socket: socket}}

      error ->
        {:stop, error, state}
    end
  end

  # binary dns message from the socket
  def handle_info(
        {:udp, socket, ip, port, packet},
        %{dns_socket: socket} = state
      ) do
    record = DNS.Record.decode(packet)
    {answers, state} = handle_dns(record.qdlist, [], state)
    response = DNS.Record.encode(%{record | anlist: answers})
    _ = :gen_udp.send(socket, ip, port, response)
    {:noreply, state}
  end

  # recursively check for dns queries, respond to each of them with the local ip address.

  # respond to `a` with our current ip address
  defp handle_dns(
         [%{type: :a} = q | rest],
         answers,
         state
       ) do
    ifname = state.ifname
    {:ok, interfaces} = :inet.getifaddrs()
    {^ifname, ifinfo} = List.keyfind(interfaces, ifname, 0)

    addr =
      Enum.find_value(ifinfo, fn
        {:addr, {_, _, _, _} = ipv4_addr} -> ipv4_addr
        _ -> false
      end)

    answer = make_record(q.domain, q.type, 120, addr)
    handle_dns(rest, [answer | answers], state)
  end

  # stop recursing when qdlist is fully enumerated
  defp handle_dns([], answers, state) do
    {Enum.reverse(answers), state}
  end

  defp make_record(domain, type, ttl, data) do
    %DNS.Resource{
      domain: domain,
      class: :in,
      type: type,
      ttl: ttl,
      data: data
    }
  end
end
FarmbotOS.Configurator.CaptiveDNS.start_link("lo0", 4040)