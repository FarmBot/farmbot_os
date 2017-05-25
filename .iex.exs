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
    RegimenRunner,
    CeleryScript,
    DebugLog,
    FarmEventRunner,
    Lib,
    SequenceRunner,
    Token,
    Configurator,
    EasterEggs,
    Farmware,
    Serial,
    Transport
  }

  context = Context.new()
end
