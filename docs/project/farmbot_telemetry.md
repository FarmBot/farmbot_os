# FarmBot Telemetry OTP App

The `farmbot_telemetry` OTP application is responsible for
storage of telemetry events. Every major OTP app in the project
uses this application as a dependency. Telemetry events are
stored in a `DETS` table, and are polled occasionally
by an AMQP/MQTT worker. When the events are successfully
dispatched over the network, they are removed from the
database