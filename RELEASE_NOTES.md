A list of important changes to FarmBot OS organized by major version.
Only includes notes about changes where user intervention is required.
For a complete list of changes and features, see the [changelog](CHANGELOG.md).
_This file is parsed by the FarmBot Web App._

# v6

* The calculation for `encoder scaling factor` has changed in v6.0.1 to `10000 * (motor resolution * microsteps) / encoder resolution`. If you are using encoders and have previously changed this setting, please check the updated value.

* The change also increases accuracy for FarmBots with `use encoders for positioning` enabled while using the default `encoder scaling factor` value. If you have previously enabled `use encoders for positioning`  please check movements to tool positions or other high-accuracy requirement movements.

* Sequence errors will now send an emergency stop command, locking FarmBot.

* If you are using `Farmduino (Genesis v1.3)`, check that `FIRMWARE` is correct after upgrading. If it isn't, choose the correct value from the drop-down.

# v7

* FarmBot OS now uses Python 3 rather than Python 2 when running Farmware. If you have added custom or 3rd-party Farmware, please check to make sure your FarmBot is still running as expected.

# v8

This release uses an improved Farmware API:
<br>
* If you have previously added custom or 3rd-party Farmware, you will need to reinstall the Farmware using the new manifest format.

* If you are a Farmware developer using Farmware Tools (`import farmware_tools`), the reinstalled Farmware should continue working as before. If you have authored a Farmware that does not use the package, you will need to replace any FarmBot device communication in your Farmware to use the `farmware_tools` package.

* See the [Farmware developer documentation](https://developer.farm.bot/docs/farmware) for more information.

# v9

FarmBot OS v8+ uses an improved Farmware API. See the [Farmware developer documentation](https://developer.farm.bot/docs/farmware) for more information.

# v10

FarmBot OS v10 features an improved *Mark As* step. If you have previously added *Mark As* steps to sequences, you will need to update them before they can be executed by FarmBot:
* Open any sequences with a caution icon next to the name.
* Click the `CONVERT` button in each old *Mark As* step.
* Save the sequence.
* If you have auto-sync disabled, press `SYNC NOW` once all sequences have been updated.
* Verify that any events using the updated sequences are running as expected.
<br>
FarmBot OS auto-update was disabled prior to this release. If you would like to continue receiving automatic updates, please re-enable auto-update.

# v11

* FarmBot OS v11 uses a new `MOVE` step. While the `MOVE TO` and `MOVE RELATIVE` steps in existing sequences will continue to work, only the new `MOVE` step can be added in the sequence editor.
* FarmBot OS v12 uses a new over-the-air update system. Updates from FarmBot OS versions older than v11.1.0 will first upgrade to v11.1.0, after which the new update system can be used to upgrade to FarmBot OS v12 and beyond.

# v12

# v13

 * FarmBot OS uses a new network transport that is more resilient to poor connectivity. If you experience a CODE 26 ERROR, you must unblock TCP port 8883.
