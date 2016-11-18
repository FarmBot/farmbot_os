defmodule Farmbot.RPC.Handler do
  @moduledoc """
    Handles RPC commands. This is @handler in config.
  """
  require Logger
  use GenEvent
  import Farmbot.RPC.Requests
  @transport Application.get_env(:json_rpc, :transport)

  @doc """
    an ack_msg with just an id is concidered a valid good we win packet

    an ack_msg with an id, and an error ( {method, message} ) is a good valid
    error packet
  """
  @spec ack_msg(String.t) :: binary
  def ack_msg(id) when is_bitstring(id) do
    Poison.encode!(
    %{id: id,
      error: nil,
      result: %{"OK" => "OK"} })
  end

  # JSON RPC RESPONSE ERROR
  @spec ack_msg(String.t, {String.t, String.t}) :: binary
  def ack_msg(id, {name, message}) do
    Logger.error("RPC ERROR")
    Logger.debug("#{inspect {name, message}}")
    Poison.encode!(
    %{id: id,
      error: %{name: name,
               message: message },
      result: nil})
  end

  @doc """
    Builds a log message to send to the fronend.
  """
  @spec log_msg(String.t, [channel,...], [String.t, ...]) :: binary
  def log_msg(message, channels, tags)
  when is_list(channels)
       and is_list(tags)
       and is_bitstring(message)
  do
    status =
      %{ status:
          %{location: Farmbot.BotState.get_current_pos}, # Shhhh
            time: :os.system_time(:seconds),
            message: message,
            channels: channels,
            tags: tags }
    %Notification{
      id: nil,
      method: "log_message",
      params: [status]} |> Poison.encode!
  end


  @doc """
    Shortcut for logging a message to the frontend.
    =  Channel can be  =
    |   :ticker        |
    |   :error_ticker  |
    |   :error_toast   |
    |   :success_toast |
    |   :warning_toast |
  """
  @type channel :: :ticker | :error_ticker | :error_toast | :success_toast | :warning_toast
  @spec log(String.t, [channel,...], [String.t]) :: :ok | {:error, atom}
  def log(message, channels, tags)
  when is_bitstring(message)
   and is_list(channels)
   and is_list(tags) do
     log_msg(message, channels, tags) |> @transport.emit
  end

  # when a request message comes in, we send an ack that we got the message
  @spec handle_incoming(Request.t | Response.t | Notification.t) :: any
  def handle_incoming(%Request{} = rpc) do
    case handle_request(rpc.method, rpc.params) do
      :ok ->
        @transport.emit(ack_msg(rpc.id))
      {:error, name, message} ->
        @transport.emit(ack_msg(rpc.id, {name, message}))
      unknown ->
        @transport.emit(ack_msg(rpc.id, {"unknown error", unknown}))
    end
  end

  # The bot itself doesn't make requests so it shouldn't ever get a response.
  def handle_incoming(%Response{} = rpc) do
    Logger.warn("Farmbot doesn't know what to do with this message:
                  #{inspect rpc}")
  end

  # The frontend doesn't send notifications so the bot shouldn't get a notification.
  def handle_incoming(%Notification{} = rpc) do
    Logger.warn("Farmbot doesn't know what to do with this message:
                  #{inspect rpc}")
  end

  # Just to be sure
  def handle_incoming(_) do
    Logger.warn("Farmbot got a malformed RPC Message.")
  end

  @doc """
    Builds a json to send to the frontend
  """
  @spec build_status(Farmbot.BotState.Monitor.State.t) :: binary
  def build_status(%Farmbot.BotState.Monitor.State{} = unserialized) do
    # unserialized = GenEvent.call(BotStateEventManager, __MODULE__, :state)
    m = %Notification{
      id: nil,
      method: "status_update",
      params: [serialize_state(unserialized)] }
    Poison.encode!(m)
  end

  # @doc """
  #   Sends the status message over whatever transport.
  # """
  # @spec send_status :: :ok | {:error, atom}
  # def send_status do
  #   build_status |> @transport.emit
  # end

  @doc """
    Takes the cached bot state, and then
    serializes it into thr correct shape for the frontend
    to be sent over mqtt
  """
  @spec serialize_state(Farmbot.BotState.Monitor.State.t) :: Serialized.t
  def serialize_state(%Farmbot.BotState.Monitor.State{
    hardware: hardware, configuration: configuration, scheduler: scheduler
  }) do
    %Serialized{
      mcu_params: hardware.mcu_params,
      location: hardware.location,
      pins: hardware.pins,

      # configuration
      locks: configuration.locks,
      configuration: configuration.configuration,
      informational_settings: configuration.informational_settings,

      # farm scheduler
      farm_scheduler: scheduler
    }
  end

  # GENEVENT CALLBACKS DON'T EVEN WORRY ABOUT IT

  def handle_event({:dispatch, state}, old_state)
  when state == old_state do
    {:ok, state}
  end

  # Event from BotState.
  def handle_event({:dispatch, state}, _) do
    build_status(state) |> @transport.emit
    {:ok, state}
  end

  # Gets the most recent "cached" BotState
  def handle_call(:state, state) do
    {:ok, state, state}
  end

  def handle_call(:force_dispatch, state) do
    build_status(state) |> @transport.emit
    {:ok, :ok, state}
  end

  def start_link(_args) do
    Farmbot.BotState.Monitor.add_handler(__MODULE__)
    {:ok, self()}
  end
end
