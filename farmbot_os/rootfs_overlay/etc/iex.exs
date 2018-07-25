# Pull in Nerves-specific helpers to the IEx session
use Nerves.Runtime.Helpers

# Be careful when adding to this file. Nearly any error can crash the VM and
# cause a reboot.
alias Farmbot.System.{	
  ConfigStorage	
}	
	
alias Farmbot.Asset	
alias Farmbot.Asset.{	
  Device,	
  FarmEvent,	
  GenericPointer,	
  Peripheral,	
  Point,	
  Regimen,	
  Sensor,	
  Sequence,	
  ToolSlot,	
  Tool	
}
