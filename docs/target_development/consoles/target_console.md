# FarmBot target console

The FarmBot OS target console is a repl for interacting with a running
farmbot instance. Depending on your development configuration, there are several
ways to access a console.

If you are using `host` mode, your console will be presented on stdin of your
terminal.

If you are on `target` mode (IE: deployed to the raspberry pi), there will
be a console available in 3 locations:

* UART (except on RPI0 since the on-board UART is used for the arduino-firmware)
  [Connect to a UART console](/docs/target_development/consoles/uart.md)
* SSH
  [Connect to an SSH console](/docs/target_development/consoles/ssh.md)
* Erlang Distribution
  [Connect to an Erlang Distribution console](/docs/target_development/consoles/erlang_distribution.md)

## Console Usage

The console a user will be presented with is _not_ a Linux console. There are
pretty much no Linux Utilities built-in. This includes but is not limited to:

* `bash`
* `apt-get`
* `make`
* `screen`
* `vi`
* `cp`
* `mkdir`
* `ln`
* `echo`
* etc

What is available is a console to the FarmBot OS runtime. You will need to be
familiar with the FarmBotOS Source code for this to be helpful.

If all you are looking for is Logs, you will probably want to do:

```elixir
RingLogger.tail()
```

After that command you will see logs come across the screen in real time.
