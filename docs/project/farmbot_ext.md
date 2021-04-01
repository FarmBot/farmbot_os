# FarmBot Ext OTP App

the `farmbot_ext` OTP app contains extended FarmbotCore functionality.
This includes mostly network functionality that isn't
possible to do in `farmbot_core`.

## Bootstrap subsystem

Subsystem responsible for bootstrapping a connection to the
FarmBot network services. This includes authenticating with
the FarmBot API, connecting to MQTT and syncing
the bare minimum resources to get up and running.

## HTTP/Sync subsystem

This is the subsystem that synchronizes FarmBot with the remote API.
It uses HTTP to download an index of all the data FarmBot cares about,
and compares timestamps to determine who has the most up to date data.
The basic flow is whoever has the most recent `updated_at` field will
become the "most truthy". If FarmBot has a more recent `updated_at` field,
FarmBot will do an HTTP PUT of it's data. If the remote resource does not
exist, FarmBot will do an HTTP POST of it's data. If the remote data has a more
recent `updated_at` field, FarmBot will do an HTTP GET and replace it's own data.

## MQTT subsystem

FarmBot maintains a connection to the API for real time communication. This
real time communication connection is multiplexed over multiple `channel`s.
Below is a description of the channels:

* bot_state - pushes a JSON encoded version of the `bot_state`
  process (from `farmbot_core`)
* celery_script - receives/sends JSON encoded celery_script.
  Used for controlling FarmBot externally
* log - sends log messages from `farmbot_core`'s logger
* ping/pong - echos everything received. used for detecting active connection
* auto_sync - the API dispatches every REST resource change on this channel.
  Used to speed up HTTP requests
* telemetry - similar to the log channel, but sends consumable events,
  rather than human readable messages

## Image uploader subsystem

This subsystem watches a local directory, and as matching files appear in that directory,
it uploads them using the FarmBot image upload protocol. Basically an HTTP request
to fetch credentials that are used to preform another HTTP request to upload
the photo.
