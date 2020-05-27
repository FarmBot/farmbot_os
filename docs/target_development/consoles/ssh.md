# SSH console

Accessing an SSH console.

## Setup

FarmBot can be configured to start an SSH server to aid in debugging and development.
During configuration of Network, select `Advanced Settings` and paste your
[ssh public key](https://git-scm.com/book/en/v2/Git-on-the-Server-Generating-Your-SSH-Public-Key)
into the optional input section labeled: `id_rsa.pub`.
FarmBot requires a public key and will not allow a username + password combination.
If you followed the documentation described in
[building target firmware](/docs/target_development/building_target_firmware.md)
then your SSH key will be automatically added to the device.

## Connecting

From the same machine that owns the `id_rsa.pub` key and associated private key
you can simply `ssh <ip address>`. If your machine supports `mdns`, you can also
do `ssh farmbot-<node_name>` where `node_name` can be found in the `Device` panel
on the FarmBot web app.

## Disconnecting

To exit the SSH session, type `~.`.
This is an ssh escape sequence (See the ssh man page for other escape sequences).
Typing Ctrl+D or logoff at the IEx prompt to exit the session aren't implemented.
