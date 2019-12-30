# FarmBot OS Source Glossary

This file contains a basic glossary of commonly used terms

## FarmBot Specific Terms

* Asset - REST resource stored in Farmbot's database stored on the SD card
* Arduino Firmware - The code that runs on the Arduino.
  * [Source](https://github.com/farmbot/farmbot-arduino-firmware)
* CelleryScript - FarmBot OS's scripting language
* FarmbBot API/Web App - The REST server FarmBot communicates with

## General Terms

* Elixir - Programming language FarmBot is developed in
  * [More info](https://elixir-lang.org/)
  * [Docs](https://hexdocs.pm/elixir/Kernel.html)
* Erlang - Programming language and VM that Elixir compiles down too
  * [More info](https://elixir-lang.org/)
  * [Even more info](#OTP-Terms)
  * [Docs](https://www.erlang.org/docs)
* UART - **U**niversal **A**synchronous **R**eceiver/**T**ransmitter.
  hardware based transport mechanism
* SSH - **S**ecure **S**hell.
* MQTT/AMQP - network protocols for pub/sub data transport
* HTTP - network protocol for accessing REST resource

## Nerves Specific Terms

* Nerves - Framework that allows cross compilation of Elixir code
  * [More info](https://nerves-project.org/)
  * [Docs](https://hexdocs.pm/nerves/getting-started.html)
* NervesHub - Cloud based firmware management
  * [More info](https://www.nerves-hub.org/)
  * [Docs](https://github.com/nerves-hub/documentation)
* Firmware - Usually refers to the code that gets deployed onto the Raspberry Pi

## OTP Terms

* Beam - Virtual machine that runs compiled Erlang bytecode
* OTP - Open Telecom Platform. Erlang's runtime libraries
  * [More info](https://erlang.org/doc/design_principles/des_princ.html)
* Supervisor - OTP `Process` responsible for supervising `Workers`
* Worker - OTP `Process` responsible for doing `work`. Usually `Supervised`
* Process - OTP concept responsible for sending/receiving messages.
  **everything** is a process in erlang
* Application - OTP concept responsible for containing many `Supervisor`s and `Worker`s
* Distribution - OTP concept of networking multiple Beam instances together
* ETS - **E**rlang **T**erm **S**torage. OTP application for storing
  data in memory
* DETS - **D**isk **E**rlang **T**erm **S**torage. OTP application for
  storing data on disk