# Changelog

## v1.4.2

* Bug fix
  * Updated non-standard UART speed configuration to use the newer termios2 API
    on Linux. This fixes a custom speed issue that was seen when using the older
    API. Thanks to Tom Boland for reporting the issue and providing a fix.

## v1.4.1

* Bug fix
  * Remove unneeded `terminate/2` that could crash under some situations.

## v1.4.0

* New Feature
  * Add `Circuits.UART.controlling_process/2`. This assigns a new controlling
    process Pid to a uart in similar to OTP functions like
   `:gen_udp.controlling_process/2`. Thanks to Robin Hilliard for adding this.

## v1.3.2

* Bug fixes
  * Fix incorrect switch in C that caused flow control enum to be incorrect.
    Thanks to Lee Bannard

## v1.3.1

* Bug fixes
  * Lengthen timeouts on messages sent to ports. This provides more slack time
    on heavily loaded uniprocessor devices that were missing timeouts by ~100 ms
    periodically.
  * Move C object files and the port executable to under the `_build` directory.
    This makes it easier to switch between host/target builds especially when
    using Elixir 1.8's mix target feature.

* Improvements
  * Handle iodata on `Circuits.UART.write` in addition to binaries and
    charlists.

## v1.3.0

Rebrand to `Circuits.UART`. No features or bugs were fixed in this version. To
upgrade, you will need to rename all occurences of `nerves_uart` to
`circuits_uart` and `Nerves.UART` to `Circuits.UART`.

## v1.2.1

* Bug fixes
  * Added missing ignore parity option to parity checking choices
  * Fix compiler warnings when built using newer versions of gcc

## v1.2.0

* Improvements
  * Added `id: pid` option. In active mode, this causes the receive
    notification messages to contain the pid of the Circuits.UART GenServer that
    sends them. Thanks to Tallak Tveide for this improvement.
  * Added `find_pids/0` diagnostic utility for finding lost `Circuits.UART` pids.
    This is handy when you need to close a serial port and don't know the pid.
  * Added `configuration/1` to get the current configuration of a UART.

## v1.1.1

The mix.exs file has the Elixir requirement bumped from 1.3 to 1.4. This was
done to fix a Dialyzer warning caused by a change in arguments to
`System.monotonic_time/1` with newer versions of Erlang and Elixir.
Unfortunately this broke compilation under Elixir 1.3.

* Bug fixes
  * Removed unnecessary open failure notification message. The failure gets
    returned from the open call already and the notification was due to an
    unfortunate path through the Linux file handle polling code.
  * Various Windows fixes:
    * Fixed unhandled tx ready event seen during big transfers at 250000.
      Thanks to Arne Ehrlich for figuring this out.
    * Fixed bogus file handle errors when an open fails and then an attempt to
      open again happens without a restart of the GenServer.

## v1.1.0

* Improvements
  * Added 4-byte framer both since it is periodically useful and as a very
    simple example of the framing feature.

* Bug fixes
  * Fix active mode state not being updated and a message being sent in
    passive mode on an open failure.
  * Maintain the elapsed time on passive mode reads to avoid reading forever
    when bytes keep arriving, but no messages get sent from the framer

## v1.0.1

* Improvements
  * Refactored Makefile logic to avoid 1-2 second hit when building. This was
    due to erl being called to get the directory containing the erl interface
    include/lib paths. Now mix.exs passes them down.
  * Trivial Elixir 1.6 formatting tweaks

## v1.0.0

* Bug fixes
  * Flush framing when closing a port
  * Fix broken spec's
  * Documentation and code cleanup

## v0.1.2

Prebuilt port binaries are no longer distributed in hex.pm for Windows users.
You'll need to install MinGW. Feedback was that it didn't work as well as I
thought it would.

* Bug fixes
  * Fix custom baudrates not working on OSX. Thanks to salzig for identifying
    the problem and helping to debug it.
  * Pass flush request through to framer as well as the serial port
  * Minor code cleanup

## v0.1.1

* New features
  * Enable experimental feature on Windows to use prebuilt
    port binary. Feedback appreciated.

## v0.1.0

* New features
  * Add support for adding and removing framing on data
    transferred over the serial port.
  * Add line framing implementation to support receiving
    notifications only for complete lines (lines ending
    in '\n' or '\r\n') or lines that are longer than a set
    length.

* Bugs fixed
  * Enable RTS when not using it. Keeping it cleared
    was stopping transmission on devices that supported
    flow control when the user wasn't using it.
  * Fix quirks on Windows when using com0com. This should
    improve support with at least one other serial driver
    based on user error reports.

* Known limitations
  * Framing receive timeouts only work in active mode.
    (I.e., you're waiting for a complete line to be received,
    but if it takes too long, then you want to receive a
    notification of a partial line.) Passive mode support is coming.

## v0.0.7

* Bugs fixed
  * Force elixir_make v0.3.0 so that it works OTP 19

## v0.0.6

* New features
  * Use elixir_make

## v0.0.5

* Bugs fixed
  * Fixed enumeration of ttyACM devices on Linux

## v0.0.4

* New features
  * Added hardware signal support (rts, cts, dtr, dsr, etc.)
  * Added support for sending breaks
  * Added support for specifying which queue to flush
    (:receive, :transmit, or :both)

* Bugs fixed
  * Fixed crash in active mode when sending and receiving
    at the same time

## v0.0.3

* Bugs fixed
  * Crosscompiling on OSX works now

## v0.0.2

* Bugs fixed
  * Fix hex.pm release by not publishing .o files

## v0.0.1

* Initial release
