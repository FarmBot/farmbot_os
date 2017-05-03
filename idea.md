# Nerves Runtime Bootstrapper
Application gets split into (up too)? three parts.

## Boot Up
Boot up could go something like:
```
Power ON
  ├── Hardware Bootloader (uboot, etc)
  ├── Linux Kernel
  ├── Erlinit
  └── Nerves Bootloader
     └──Nerves Bootstrapper
        ├── Hardware init (driver loading)
        ├── Filesystem init (see block diagram)
        ├── Network Init
        └── HTTP Init (Maybe this could be generalized as a `Transport` as to not be locked into http?)
            └── Download an archive of some sort containing our actual application code (this is the hard part)
                ├── Extract/Verify (with black magic?) package
                └── Somehow shim into (and supervise) this package
```
## Partitions
So a partition map would look a little different
```
 ______________________________________________________________________________
|        A        |          B          |        C         |         D        |
|    Bootloader   | Nerves Bootstrapper | Application Code | Application Data |
|  (per platform) |     (Read only)     |    (Read Only)   |    (Read/Write)  |
|_________________|_____________________|__________________|__________________|
```
* A - Bootloader
  * Will be different per platform.
  * Black magic
* B - Nerves Bootstrapper
  * Will contain `linux` rootfs with `erlinit` and friends.
  * Should be read only, and _probably_ not need a mirror/backup partition. (Hopefully)
  * Should contain `Nerves.Bootloader`
* C - Application Code
  * One (or maybe many???) Erlang releases containing beam files and friends.
  * Read only at runtime. `BootStrapper` should be the only thing with access to overwriting.
  * Should be persistent, but if mangled somehow, BootStrapper can fix it/Request new Firmware
  * Hot code reloading
  * Probably have backup/mirror partition.
* D - Application Data
  * General Data partition

## Implementation

### Compile
* Application require the `NervesBootstrapper` dep, giving some configuration.
* `NervesBootstrapper` Provides a plugin for Distillery or something that:
  * Constructs the (cross compiled) release, and `Bootstrapper` firmware.
    * Bootstrapper will be a `.fw` file.
    * Application code will be a archive of some sort of just your release.

`mix firmware` Could still compile a fw file with your application code baked in thanks to `fwup`

### Running

`mix firmware.burn` could Still burn an entire firmware with your application code baked in.

## Problems
Biggest problem i can see is shimming into a second Erlang release. Maybe we can have two
instances of `erlinit`?

Semantics of bringing up hardware will need to be hashed out.
