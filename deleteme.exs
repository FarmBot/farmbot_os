
use Amnesia
{:ok, reg} = Farmbot.Sync.Database.Regimen.validate %{"id" => 1, "color" => "red", "name" => "abc", "device_id" => 123}
Amnesia.transaction do
  Farmbot.Sync.Database.Regimen.write(reg)
end
{:ok, item} = Farmbot.Sync.Database.RegimenItem.validate %{"id" => 5, "time_offset" => 123, "regimen_id" => 1, "sequence_id" => 3}
Amnesia.transaction do
  Farmbot.Sync.Database.RegimenItem.write(item)
end
a = Scheduler.Regimen.VM.get_regimen_item_for_regimen(reg)
