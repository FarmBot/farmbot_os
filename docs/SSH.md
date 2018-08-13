# SSH

## Setup
FarmBot can be configured to start an SSH server to aid in debugging and development.
During configuration of Network, select `Advanced Settings` and paste your [ssh
public key](https://git-scm.com/book/en/v2/Git-on-the-Server-Generating-Your-SSH-Public-Key) into the
optional input section labeled: `id_rsa.pub`. FarmBot requires a public key and
will not allow a username + password combination. FarmBot also only allows one
key to be configured for security reasons.

## Connecting
From the same machine that owns the `id_rsa.pub` key and assosiated private key
you can simply `ssh <ip address>`. If your machine supports `mdns`, you can also
do `ssh farmbot-<node_name>` where `node_name` can be found in the `Device` panel
on the FarmBot web app.

## Usage
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
RingLogger.attach()
```

After that command you will see logs come across the screen in real time.

To exit the SSH session, type `~.`.
This is an ssh escape sequence (See the ssh man page for other escape sequences).
Typing Ctrl+D or logoff at the IEx prompt to exit the session aren't implemented.
