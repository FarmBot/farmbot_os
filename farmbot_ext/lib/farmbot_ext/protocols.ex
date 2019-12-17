# TODO(Connor) delete this one day.
# this will require defining farmbot specific encode/decode
# protocols for both of these structures
require Protocol
Protocol.derive(Jason.Encoder, FarmbotExt.JWT)
Protocol.derive(Jason.Encoder, FarmbotCeleryScript.AST)
