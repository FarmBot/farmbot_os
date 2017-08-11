use Mix.Config

config :farmbot, :authorization, [
  email: "admin@admin.com",
  password: "password123",
  server:   "http://localhost:3000",
  token:    "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJzdWIiOiJhZG1pbkBhZG1pbi5jb20iLCJpYXQiOjE1MDI0Mjc2MDUsImp0aSI6IjA3ZDk1MmRjLWQ2MDktNGRiYi04NTcwLTIxMTNkM2Q2ZWMzOSIsImlzcyI6Ii8vMTkyLjE2OC4yOS4yMDQ6MzAwMCIsImV4cCI6MTUwNTg4MzYwNSwibXF0dCI6IjE5Mi4xNjguMjkuMjA0Iiwib3NfdXBkYXRlX3NlcnZlciI6Imh0dHBzOi8vYXBpLmdpdGh1Yi5jb20vcmVwb3MvZmFybWJvdC9mYXJtYm90X29zL3JlbGVhc2VzL2xhdGVzdCIsImZ3X3VwZGF0ZV9zZXJ2ZXIiOiJodHRwczovL2FwaS5naXRodWIuY29tL3JlcG9zL0Zhcm1ib3QvZmFybWJvdC1hcmR1aW5vLWZpcm13YXJlL3JlbGVhc2VzL2xhdGVzdCIsImJvdCI6ImRldmljZV8yIn0.twtAOS9PXtkSB-a3Qjm3HrJSM7Nfm7oWOc8d4BFb7nBOaB3eGDUB4sb5u7pjAgMo37egIbAatKKkHlh_o9uNDJvrs9aPsLAn6O8dN_CDCkenjNyrbQjI8i_hjtL28X9AyHLOe1G0A8V8nRs4hZ8x5AcQSH8DkhaaRaBuh-0u1Yesfo7nwFIl34LTCoZ9amrdzHvIn0xP35BaPoEGziqolqtNJ5an2Bps4JGBV_kNSlODwGxPFESHO3uL1PrTgaXkM3_FSZpY7NxbgxC50ok9TspeMRLjluqntzyJG1EadxgHkbVOG0kuPH6R3Pa6UfkDNzBv7DWDHk4mOYPcDdABbQ"
]

# We reconfigure this later in tests.
config :farmbot, :init, []

# Replace some things to stub them out.
config :farmbot, :behaviour, [
  # Auth needs to be stubbed to not use configuration.
  authorization: Farmbot.Test.Authorization,
  # SystemTasks here, don't actually stop the vm so we can test them.
  system_tasks:  Farmbot.Test.SystemTasks
]
