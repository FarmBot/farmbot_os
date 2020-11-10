# Erlang Distribution Console

Accessing an Erlang Distribution console

## Setup

No additional setup is required for setting up erlang distribution on the target.
On your `host` machine, you need to have Erlang Distribution running. This can
usually be accomplished by starting `epmd`:

```bash
epmd --daemon
```

## Connecting

From your `host` terminal, connecting to a running device can be done by using the
`remsh` feature of elixir's built in console.

```bash
iex --name console --cookie democookie --remsh farmbot@farmbot-<SERIAL_NUMBER>.local
```

## Disconnecting

Issuing a `ctrl+c` to the `host` terminal should disconnect you from the session.

# Remote Debug / Profiling of a FarmBot

1. On host machine, run: `iex --name me@TARGET_IP_HERE --cookie COOKIE_GOES_HERE`
1. An IEx session begins.
1. Run `:observer.start()` to start the observer GUI.
1. A window appears. Select `Node -> Connect Node`.
1. Enter `farmbot@DEVICE_HOSTNAME_HERE`.
1. The node appears in the list under the `Node` menu bar. Select it: `Node -> farmbot@DEVICE_HOSTNAME_HERE`.
1. You're ready to debug!
