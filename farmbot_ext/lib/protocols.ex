# DELETEME
require Protocol
# Bot State
Protocol.derive(Jason.Encoder, Farmbot.BotState)
Protocol.derive(Jason.Encoder, Farmbot.BotState.Configuration)
Protocol.derive(Jason.Encoder, Farmbot.BotState.InformationalSettings)
Protocol.derive(Jason.Encoder, Farmbot.BotState.LocationData)
Protocol.derive(Jason.Encoder, Farmbot.BotState.McuParams)
Protocol.derive(Jason.Encoder, Farmbot.BotState.Pin)
Protocol.derive(Jason.Encoder, Farmbot.BotState.JobProgress.Bytes)
Protocol.derive(Jason.Encoder, Farmbot.BotState.JobProgress.Percent)

Protocol.derive(Jason.Encoder, Farmbot.JWT)

Protocol.derive(Jason.Encoder, Farmbot.CeleryScript.AST)
