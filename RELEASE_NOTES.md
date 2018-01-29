A list of important changes to FarmBot OS organized by major version.
_This file is parsed by the FarmBot Web App._

# v6

* The calculation for `encoder scaling factor` has changed in v6.0.1 to `10000 * (motor resolution * microsteps) / encoder resolution`. If you are using encoders and have previously changed this setting, please check the updated value.

* The change also increases accuracy for FarmBots with `use encoders for positioning` enabled while using the default `encoder scaling factor` value. If you have previously enabled `use encoders for positioning`  please check movements to tool positions or other high-accuracy requirement movements.

* Sequence errors will now send an emergency stop command, locking FarmBot.

* If you are using `Farmduino (Genesis v1.3)`, check that `FIRMWARE` is correct after upgrading. If it isn't, choose the correct value from the drop-down.
