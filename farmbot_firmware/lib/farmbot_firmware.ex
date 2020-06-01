defmodule FarmbotFirmware do
  @moduledoc """
  Firmware wrapper for interacting with Farmbot-Arduino-Firmware.
  This GenServer is expected to be a pretty simple state machine
  with no side effects to anything in the rest of the Farmbot application.
  Side effects should be implemented using a callback/pubsub system. This
  allows for indpendent testing.

  Functionality that is needed to boot the firmware:
    * parameters - Keyword list of {param_atom, float}

  Side affects that should be handled
    * position reports
    * end stop reports
    * calibration reports
    * busy reports

  # State machine
  The firmware starts in a `:transport_boot` state, moving to `:boot`. It then
  loads all parameters writes all parameters, and goes to idle if all params
  were loaded successfully.

  State machine flows go as follows:
  ## Boot
      :transport_boot
      |> :boot
      |> :no_config
      |> :configuration
      |> :idle

  ## Idle
      :idle
      |> :begin
      |> :busy
      |> :error | :invalid | :success

  # Constraints and Exceptions
  Commands will be queued as they received with some exceptions:
  * if a command is currently executing (state is not `:idle`),
    proceding commands will be queued in the order they are received.
  * the `:emergency_lock` and `:emergency_unlock` commands go to the front
    of the command queue and are started immediately.
  * if a `report_emergency_lock` message is received at any point during a
    commands execution, that command is considered an error.
    (this does not apply to `:boot` state, since `:parameter_write`
     is accepted while the firmware is locked.)
  * all reports outside of control flow reports (:begin, :error, :invalid,
    :success) will be discarded while in `:boot` state. This means while
    boot, position updates, end stop updates etc are ignored.

  # Transports
  GCODES should be exchanged in the following format:
      {tag, {command, args}}
  * `tag` - binary integer. This is translated to the `Q` parameter.
  * `command` - either a `RXX`, `FXX`, or `GXX` code.
  * `args` - a list of arguments to be processed.

  For example a report might look like:
      {"123", {:report_some_information, [h: 10.00, u: 90.10]}}
  and a command might look like:
      {"555", {:fire_laser, [w: 100.00]}}
  Numbers should be floats when possible. An Exeption to this is `:report_end_stops`
  where there is only two values: `1` or `0`.

  See the `GCODE` module for more information on available implemented GCODES.
  a `Transport` should be a process that implements standard `GenServer`
  behaviour.

  Upon `init/1` the args passed in should be a Keyword list required to configure
  the transport such as a serial device, etc. `args` will also contain a
  `:handle_gcode` function that should be called everytime a GCODE is received.

      Keyword.fetch!(args, :handle_gcode).({"999", {:report_software_version, ["Just a test!"]}})

  a transport should also implement a `handle_call` clause like:

      def handle_call({"166", {:parameter_write, [some_param: 100.00]}}, _from, state)

  and reply with `:ok | {:error, term()}`

  """
  use GenServer
  require Logger

  alias FarmbotFirmware, as: State
  alias FarmbotFirmware.{GCODE, Command, Request}

  @type status ::
          :transport_boot
          | :boot
          | :no_config
          | :configuration
          | :idle
          | :emergency_lock

  defstruct [
    :transport,
    :transport_pid,
    :transport_ref,
    :transport_args,
    :side_effects,
    :status,
    :tag,
    :configuration_queue,
    :command_queue,
    :caller_pid,
    :current,
    :reset
  ]

  @type state :: %State{
          transport: module(),
          transport_pid: nil | pid(),
          transport_ref: nil | reference(),
          transport_args: Keyword.t(),
          side_effects: nil | module(),
          status: status(),
          tag: GCODE.tag(),
          configuration_queue: [{GCODE.kind(), GCODE.args()}],
          command_queue: [{pid(), GCODE.t()}],
          caller_pid: nil | pid,
          current: nil | GCODE.t(),
          reset: module()
        }

  @doc """
  Command the firmware to do something. Takes a `{tag, {command, args}}`
  GCODE. This command will be queued if there is already a command
  executing. (this does not apply to `:emergency_lock` and `:emergency_unlock`)

  ## Response/Control Flow
  When executed, `command` will block until one of the following respones
  are received:
    * `{:report_success, []}` -> `:ok`
    * `{:report_invalid, []}` -> `{:error, :invalid_command}`
    * `{:report_error, []}` -> `{:error, :firmware_error}`
    * `{:report_emergency_lock, []}` -> `{:error, :emergency_lock}`

  If the firmware is in any of the following states:
    * `:boot`
    * `:transport_boot`
    * `:no_config`
    * `:configuration`
  `command` will fail with `{:error, state}`
  """
  defdelegate command(server \\ __MODULE__, code), to: Command

  @doc """
  Request data from the firmware.
  Valid requests are of kind:

      :parameter_read
      :status_read
      :pin_read
      :end_stops_read
      :position_read
      :software_version_read

  Will return `{:ok, {tag, {:report_*, args}}}` on success
  or `{:error, term()}` on error.
  """
  defdelegate request(server \\ __MODULE__, code), to: Request

  @doc """
  Close the transport, putting the Firmware State Machine back into
  the `:transport_boot` state.
  """
  def close_transport(_server \\ __MODULE__) do
    :ok
  end

  @doc """
  Opens the transport,
  """
  def open_transport(_server \\ __MODULE__, _module, _args) do
    :ok
  end

  def reset(_server \\ __MODULE__) do
    :ok
  end

  @doc """
  Starting the Firmware server requires at least:
  * `:transport` - a module implementing the Transport GenServer behaviour.
    See the `Transports` section of moduledoc.

  Every other arg passed in will be passed directly to the `:transport` module's
  `init/1` function.
  """
  def start_link(args, opts \\ [name: __MODULE__]) do
    GenServer.start_link(__MODULE__, args, opts)
  end

  def init(_args) do
    {:ok, %State{}}
  end
end
