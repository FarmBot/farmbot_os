# Development Profiles
Profiles are loaded synchronously right after the local settings database is setup.
A profile can modify any global setting to farmbot os. Profiles are *NOT* loaded
at compile time. This means, that if deployed to a target such as Raspberry Pi 3,
your host environment variables will not be loaded.

# Selecting a profile
Load a profile by doing:
```bash
FBOS_PROFILE=profile_name iex -S mix
```

## Chaining profiles
Profiles can be chained with commas. They will be evaluated in order supplied.
```bash
FBOS_PROFILE=admin,setup_arduino iex -S mix
