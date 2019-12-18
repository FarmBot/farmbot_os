# FarmBot CeleryScript OTP App

`farmbot_celery_script` is responsible for implementing the 
runtime that execute's [CeleryScript](/docs/celery_script/celery_script.md). 
It contains a handful of helpers, and several subsystems for working with CeleryScript. 
The most important being:
* AST - definition of the AST as it relates to FarmBot OS
* Compiler - Compiles CeleryScript to Elixir AST. 
  * See the [Elixir Macro Docs](https://hexdocs.pm/elixir/Macro.html)
* StepRunner - Process responsible for actually executing CeleryScript
* Scheduler - Process responsible for scheduling calls to the `StepRunner`
* SysCalls - module responsible for dispatching calls to the configured implementation
