if Code.ensure_loaded? Farmbot do
  alias Farmbot.{
    Auth,
    Context,
    EventSupervisor,
    HTTP,
    Regimen,
    SysFormatter,
    BotState,
    Database,
    FarmEvent,
    ImageWatcher,
    Regimen.Runner,
    CeleryScript,
    DebugLog,
    FarmEvent.Runner,
    Lib,
    Sequence.Runner,
    Token,
    Configurator,
    EasterEggs,
    Farmware,
    Serial,
    Transport
  }

  context = Context.new()
end
