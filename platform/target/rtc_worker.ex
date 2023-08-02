defmodule FarmbotOS.Platform.Target.RTCWorker do
  @moduledoc """
  Handler for synchronizing time with an RTC and ntpd
  """

  use GenServer
  require Logger
  alias Circuits.I2C
  @eleven_minutes 660_000
  if Code.ensure_compiled(NervesTime) do
    @nerves_time NervesTime
  else
    @nerves_time nil
  end

  @doc "checks if an RTC is available on the I2C bus"
  @spec rtc_available?(I2C.bus()) :: boolean()
  def rtc_available?(i2c) do
    case I2C.write_read(i2c, 0x51, <<0x00>>, 1) do
      {:ok, ok} when byte_size(ok) == 1 ->
        Logger.info("detected RTC")
        true

      {:error, :i2c_nak} ->
        false
    end
  end

  @doc "Checks the VL bit on the `seconds` register"
  def get_vl_from_rtc(i2c) do
    case I2C.write_read(i2c, 0x51, <<0x02>>, 1) do
      # clock integrity is guaranteed
      {:ok, <<0::integer-1, _::size(7)>>} ->
        {:ok, true}

      # clock integrity NOT guaranteed
      {:ok, <<1::integer-1, _::size(7)>>} ->
        {:ok, false}

      {:error, error} ->
        {:error, error}
    end
  end

  @doc "Saves a NaiveDateTime onto the RTC"
  @spec set_time_to_rtc(I2C.bus(), NaiveDateTime.t()) :: :ok | {:error, term()}
  def set_time_to_rtc(i2c, %NaiveDateTime{} = date_time) do
    # discard top bit
    <<_::bits-1, second::integer-7>> = int_to_bcd(date_time.second)
    # discard top bit
    <<_::bits-1, minute::integer-7>> = int_to_bcd(date_time.minute)
    # discard 2 bits
    <<_::bits-2, hour::integer-6>> = int_to_bcd(date_time.hour)
    <<_::bits-2, day::integer-6>> = int_to_bcd(date_time.day)
    <<_::bits-3, month::integer-5>> = int_to_bcd(date_time.month)
    year = int_to_bcd(date_time.year - 2000)

    I2C.write(i2c, 0x51, [
      <<0x02>>,
      # unset the VL bit. The clock is guaranteed after this.
      <<0::integer-1, second::integer-7>>,
      # drop first bit
      <<0::integer-1, minute::integer-7>>,
      # drop first two bits
      <<0::integer-2, hour::integer-6>>,
      <<0::integer-2, day::integer-6>>,
      # weekday
      <<0::size(8)>>,
      # first bit is century. drop 2 bits.
      <<1::integer-1, 0::integer-2, month::integer-5>>,
      year
    ])
  end

  @doc "Gets a NaiveDateTime from the rtc"
  @spec get_time_from_rtc(I2C.bus()) ::
          {:ok, NaiveDateTime.t()} | {:error, term()}
  def get_time_from_rtc(i2c) do
    with {:ok, <<_vl::bits-1, second::bits-7>>} <-
           I2C.write_read(i2c, 0x51, <<0x02>>, 1),
         {:ok, <<_::bits-1, minute::bits-7>>} <-
           I2C.write_read(i2c, 0x51, <<0x03>>, 1),
         {:ok, <<_::bits-2, hour::bits-6>>} <-
           I2C.write_read(i2c, 0x51, <<0x04>>, 1),
         {:ok, <<_::bits-2, day::bits-6>>} <-
           I2C.write_read(i2c, 0x51, <<0x05>>, 1),
         {:ok, <<_c::bits-1, _::bits-2, month::bits-5>>} <-
           I2C.write_read(i2c, 0x51, <<0x07>>, 1),
         # implied 20XX
         {:ok, <<year::bits-8>>} <- I2C.write_read(i2c, 0x51, <<0x08>>, 1) do
      dt = %NaiveDateTime{
        day: bcd_to_int(day),
        hour: bcd_to_int(hour),
        minute: bcd_to_int(minute),
        month: bcd_to_int(month),
        second: bcd_to_int(second),
        year: 2000 + bcd_to_int(year)
      }

      {:ok, dt}
    end
  end

  @doc "Sets the system clock from a NaiveDateTime"
  @spec set_system_clock(NaiveDateTime.t()) :: :ok | {:error, term()}
  def set_system_clock(%NaiveDateTime{} = dt) do
    str = format_date_time(dt)

    case System.cmd("date", ["-u", "-s", str], stderr_to_stdout: true) do
      {_, 0} -> :ok
      {error, _} -> {:error, String.trim(error)}
    end
  end

  def format_date_time(%NaiveDateTime{} = dt) do
    str =
      :io_lib.format(
        ~c"~4..0B-~2..0B-~2..0B ~2..0B:~2..0B:~2..0B",
        [dt.year, dt.month, dt.day, dt.hour, dt.minute, dt.second]
      )

    to_string(str)
  end

  @doc "Converts an integer to a 8bit BCD encoded binary"
  def int_to_bcd(value) when value <= 9 do
    <<0::integer-4, value::integer-4>>
  end

  def int_to_bcd(value) when value <= 99 do
    tens = div(value, 10)
    units = rem(value, 10)
    <<tens::integer-4, units::integer-4>>
  end

  @doc "Converts an BCD encoded binary to an integer"
  def bcd_to_int(value, power \\ 10)

  # 5 bit bcd
  def bcd_to_int(<<tens::integer-1, units::integer-4>>, pow),
    do: bcd_to_int(tens, units, pow)

  # 6 bit bcd
  def bcd_to_int(<<tens::integer-2, units::integer-4>>, pow),
    do: bcd_to_int(tens, units, pow)

  # 7 bit bcd
  def bcd_to_int(<<tens::integer-3, units::integer-4>>, pow),
    do: bcd_to_int(tens, units, pow)

  # 8 bit bcd
  def bcd_to_int(<<tens::integer-4, units::integer-4>>, pow),
    do: bcd_to_int(tens, units, pow)

  def bcd_to_int(tens, units, pow) when units >= pow,
    do: bcd_to_int(tens, units, pow * 10)

  def bcd_to_int(tens, units, pow),
    do: tens * pow + units

  @doc false
  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl GenServer
  def init(_args) do
    with {:ok, i2c} <- I2C.open("i2c-1"),
         true <- rtc_available?(i2c) do
      Logger.debug("beginning RTC sync")
      send(self(), :set_system_time_from_rtc)
      {:ok, %{i2c: i2c}}
    else
      _ ->
        Logger.info("Could not detect RTC.")
        {:ok, %{i2c: nil}}
    end
  end

  @impl GenServer
  def handle_info(:set_system_time_from_rtc, %{i2c: i2c} = state) do
    with {:ok, true} <- get_vl_from_rtc(i2c),
         {:ok, %NaiveDateTime{} = dt} <- get_time_from_rtc(i2c),
         :ok <- set_system_clock(dt) do
      Logger.info("set system time from RTC: #{dt}")
    else
      {:ok, false} ->
        Logger.error("Not setting system time from RTC. VL bit is unset")

      error ->
        Logger.error(
          "failed to get time from rtc or set system time: #{inspect(error)}"
        )
    end

    Process.send_after(self(), :set_rtc_from_ntp, @eleven_minutes)
    {:noreply, state}
  end

  def handle_info(:set_rtc_from_ntp, %{i2c: i2c} = state) do
    dt = NaiveDateTime.utc_now()

    if @nerves_time do
      if @nerves_time.synchronized?() do
        set_time_to_rtc(i2c, dt)
        Process.send_after(self(), :set_rtc_from_ntp, @eleven_minutes)
      else
        send(self(), :set_system_time_from_rtc)
      end
    end

    {:noreply, state}
  end
end
