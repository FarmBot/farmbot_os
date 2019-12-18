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