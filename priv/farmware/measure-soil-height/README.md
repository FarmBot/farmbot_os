# Measure Soil Height
Farmware to measure soil height using OpenCV

# Concept

Simulate a virtual stereo camera using FarmBot's CNC camera positioning system.

Stereo photography, like binocular vision, provides depth information
via parallax, where subjects closer to the lens move further in the frame
between lens positions than subjects farther from the lens. OpenCV computes
this disparity between detected object positions in stereo image frames.

This process is performed at multiple locations to develop equation
coefficients for a correlation between disparity and distance for a particular
camera and environment. These coefficients are applied to the computed disparity
values (with the soil as the subject) to calculate distance, which is finally
combined with camera position data from FarmBot's known coordinate system
to calculate the z axis coordinate of the soil.

With the soil position mapped to FarmBot's coordinate system, FarmBot can
perform actions that engage the soil surface such as seeding and weeding.

## Alternatives
 * Manually measure the distance from the FarmBot's UTM to the soil and
 subtract it from the current z-axis position.
 * Move FarmBot to the soil surface using manual controls and record the
 z-axis position.
 * Add a button to FarmBot's UTM that triggers when it collides with the
 soil surface.
 * Use an ultrasonic, infrared, or LiDAR distance sensor.
 * Use a stereo camera.

# Usage

## Install
[Farmware panel](https://my.farm.bot/app/designer/farmware) install URL:
```
https://raw.githubusercontent.com/FarmBot-Labs/measure-soil-height/main/manifest.json
```

## Run
1. Move FarmBot to a location where the camera has a clear view of a wide area of soil.
Ensure the Y and Z axes have room to move away from home/zero.
3. Measure the distance from the camera lens to the soil with a tape measure.
4. Select **Measure Soil Height** in the [Farmware panel](https://my.farm.bot/app/designer/farmware).
5. Enter the measured distance in millimeters in the
_Measured distance from camera to soil_ input.
6. Press **CALIBRATE**. FarmBot will (see [capture images](#capture-images) for a diagram):
    * take a photo
    * move the y-axis a small amount
    * take another photo
    * move the z-axis
    * take another photo
    * move the y-axis back
    * take another photo
    * move the z-axis back
7. Check the calibration results and image output.
See [interpreting output images](#interpreting-output-images) and
[possible failures](#possible-failures).

At this point, calibration is complete. Soil height can now be measured and
recorded by pressing **MEASURE** in the **Measure Soil Height** Farmware panel
or using a **Measure Soil Height** sequence command and running the sequence
(execute the sequence over a point grid group for full garden soil mapping).

The measured soil z coordinate will be shown in a toast message and saved
to a soil height point in the _Points_ panel. An image will be saved to the
_Photos_ panel which will also be shown in the map if the camera has been
calibrated (via the `Camera calibration` section of the _Photos_ panel).

To re-calibrate, press **RESET CALIBRATION VALUES** in the
**Measure Soil Height** Farmware panel and follow the [steps to run](#run).

For output customization, see [verbosity settings](#verbosity-settings).

# Workflow

## Capture images
Move to locations a short distance apart to simulate a stereo camera.

<img
alt="virtual stereo"
height="360px"
src="https://user-images.githubusercontent.com/12681652/100785207-307cef00-33c5-11eb-96e6-2cfe00d994ae.png">

For calibration, move to multiple z-axis locations and capture stereo pairs
at each.

<img
alt="calibration movements"
height="360px"
src="https://user-images.githubusercontent.com/12681652/100785204-307cef00-33c5-11eb-818b-db956bbccbe5.png">

## Prepare images
Adjust the captured images as necessary to create an aligned stereo image pair.

![raw stereo inputs](https://user-images.githubusercontent.com/12681652/100785210-31158580-33c5-11eb-8d20-679e9329a60f.jpg)

Detect camera rotation using optical flow:

![raw optical flow vector overlay](https://user-images.githubusercontent.com/12681652/100785212-31158580-33c5-11eb-910b-6f9c2f3bc469.jpg)

For the stereo depth calculation to work correctly, features in the left input
image must trace a horizontal path to the right input image.

![adjusted optical flow vector overlay](https://user-images.githubusercontent.com/12681652/100785215-31ae1c00-33c5-11eb-8002-b27eb500d020.jpg)

## Compute depth map
Combine stereo images to generate a disparity/depth map.

![stereo inputs](https://user-images.githubusercontent.com/12681652/100785130-16431100-33c5-11eb-8e97-d8f17922eff5.png)

![combined stereo inputs](https://user-images.githubusercontent.com/12681652/100785125-15aa7a80-33c5-11eb-9020-8b9b0154a897.jpg)

![depth map](https://user-images.githubusercontent.com/12681652/100785199-2f4bc200-33c5-11eb-91ff-82dc743ea578.jpg)

Histogram illustrating occurrence frequency of values in depth map:

![disparity histogram](https://user-images.githubusercontent.com/12681652/100785222-32df4900-33c5-11eb-924b-5936090c1ad6.jpg)

## Determine location of soil in image
Assume the most common depth map value represents the soil.
In the following image, the selected soil depth is highlighted in green.
Depth values for objects far from the soil level are highlighted with red,
with bright red indicating objects closer to the camera and dark red
indicating objects farther from the camera.

![annotated disparity histogram](https://user-images.githubusercontent.com/12681652/100785225-34107600-33c5-11eb-8cdc-387fd06d0078.jpg)

Annotate the depth map using the same color-coding:

![annotated depth map](https://user-images.githubusercontent.com/12681652/100785224-34107600-33c5-11eb-9fc9-5e2811166d4e.jpg)

Exclude plants using HSV filtering with the values provided in the
`Weed detector` section of the _Photos_ panel.

Plants selected:

![plants selected](https://user-images.githubusercontent.com/12681652/100788591-20b3d980-33ca-11eb-8783-dedbf1fd9f6a.jpg)

Plants removed from depth map to not interfere with soil surface selection:

![annotated depth map with plants filtered](https://user-images.githubusercontent.com/12681652/100785219-32df4900-33c5-11eb-8271-04489e6381c5.jpg)

## Calibrate disparity vs distance conversion factors

<img
alt="distance vs disparity chart"
height="360px"
src="https://user-images.githubusercontent.com/12681652/100785234-370b6680-33c5-11eb-991f-ad42253a487d.jpg">

Two coefficients are necessary to calculate distance from the raw disparity
data. The following are used:
 * a disparity multiplication factor (`calibration_factor`)
 * a disparity offset constant (`disparity_offset`)

Example calculations, where:
 * Soil was measured 250mm from camera when camera was at z = 0
 * Soil disparity was calculated from a stereo image pair (`disparity_offset`)
 at z = 0
  * Soil disparity was calculated from a stereo image pair (`disparity_value`)
 at z = -50

```
disparity_delta = disparity_value - disparity_offset
64              = 176             - 112

z_offset = measured_at_z - current_z
50       = 0             - (-50)

calibration_factor = z_offset / disparity_delta
0.7812             = 50       / 64
```

See [calculate distance and soil z](#calculate-distance-and-soil-z) for z
calculations.

## Calculate distance and soil z

Example calculations, where:
 * Soil was measured 250mm from camera when camera was at z = 0
 * Calibration values were previously calculated (`calibration_factor`
 and `disparity_offset`)
 * Soil disparity was calculated from a stereo image pair (`disparity_value`)
 at z = -50

```
measured_soil_z = measured_at_z - measured_distance
-250            = 0             - 250

disparity_delta = disparity_value - disparity_offset
64              = 176             - 112

distance_offset = disparity_delta * calibration_factor
50              = 64              * 0.7812

distance = measured_distance - distance_offset
200      = 250               - 50

calculated_soil_z = current_z  - distance
-250              = -50        - 200
```

# I/O

## Inputs

* Farmware inputs. _Measured distance from camera to soil_ is the only required input.
* Current position. Retrieved via Farmware bot state API.
* Images from camera (at different locations).

## Outputs

See [verbosity settings](#verbosity-settings) for customization.

* Logs: calculated soil z, debug messages.
* Points: `Soil Height` point with calculated z coordinate of soil.
* Images: depth map, debug images.
* FarmwareEnvs: with `measure_soil_height_calibration_` prefix (calibration only)
* Data files: settings, results JSON (local development only)

# Interpreting output images

## Recognizing good data

A large portion of the annotated depth map should be green, which represents
a large area of detected soil at a consistent height.

![green depth](https://user-images.githubusercontent.com/12681652/100785224-34107600-33c5-11eb-9fc9-5e2811166d4e.jpg)

The rotated stereo image pair should show features that are offset horizontally
to the left between the left and right frames.

![right to left features](https://user-images.githubusercontent.com/12681652/100785227-34a90c80-33c5-11eb-9490-1a13e17b94bf.png)

The disparity histogram should show a prominent spike, which represents a
large number of similar depth values.

![depth histogram spike](https://user-images.githubusercontent.com/12681652/100785222-32df4900-33c5-11eb-924b-5936090c1ad6.jpg)

For examples of poorly configured captures, see [possible failures](#possible-failures).

# Possible failures

## Incorrect input orientation

When the left and right stereo pair images are swapped, or the images are not
corrected for camera rotation (so that objects are not offset orthogonally
between left and right frames), the disparity computation produces noise:

![random noise](https://user-images.githubusercontent.com/12681652/100785230-35da3980-33c5-11eb-8bfd-9a9f29df87d7.jpg)

And the corresponding histogram is relatively flat with no large count of
similar depth values:

![flat depth histogram](https://user-images.githubusercontent.com/12681652/100785231-3672d000-33c5-11eb-8861-90865c7ed11d.jpg)

## Non-linear disparity

When the disparity calculation fails to produce linear differences between
distance values, an incorrect distance is calculated.

<img
alt="linear vs non-linear points on plot"
height="360px"
src="https://user-images.githubusercontent.com/12681652/100785236-370b6680-33c5-11eb-9702-02e6c0c6ffd2.jpg">

This may be caused by poor quality image captures or subject matter,
or by motor stalls.

## Insufficient detail

Disparity cannot be properly calculated if the algorithm cannot match objects
between stereo frames, or the disparity is the same between frames.

### Too blurry

Try moving the camera closer or choosing a higher resolution setting.

### Un-featured soil

Try choosing a different soil location, moving the camera closer, or
choosing a higher resolution setting.

### Too far

Try moving the camera closer or choosing a higher resolution setting.

## Error messages

`Problem getting image`:
Verify camera is working by taking a photo.

`Calibration measured distance input required`:
Provide a distance measurement (see [steps to run](#run)).

`Image size must match calibration`:
Recalibrate or revert change to image capture size or rotation.

`Not enough detail`:
Verify the camera is working and enough light is present.

`Couldn't find surface` or `Not enough disparity information` or `Zero disparity`:
See [incorrect input orientation](#incorrect-input-orientation)
and [insufficient detail](#insufficient-detail).

`Soil height calculation error` or `Zero disparity difference` or `Zero offset`:
Verify z-axis motor is working or try recalibrating at a different location.

# Verbosity settings

Some outputs can be customized via inputs.
For an overview of all outputs, see [outputs](#outputs).

## Logs

Log verbosity is adjustable via the `Log verbosity` input value.

| log type | output               |  0  |  1  |  2  |  3  |
|:---------|:---------------------|:---:|:---:|:---:|:---:|
| success  | result toast message |     |  x  |  x  |  x  |
| debug    | basic operation logs |     |     |  x  |  x  |
| debug    | low-level debug logs |     |     |     |  x  |

## Images

Output image verbosity is adjustable via the `Image output option` input value.

| description         |  0  |  1  |  2  |  3  |  4  |  5  |  6  |  7  |
|:--------------------|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| color map w/ img    |     |     |  x  |     |     |     |  x  |  x  |
| b/w depth map       |     |     |     |  x  |     |     |  x  |  x  |
| stereo images       |     |     |     |     |  x  |     |  x  |  x  |
| collage             |     |     |     |     |     |  x  |  x  |  x  |
| color depth map     |     |     |     |     |     |     |  x  |  x  |
| depth histogram     |     |     |     |     |     |     |  x  |  x  |
| image histogram     |     |     |     |     |     |     |  x  |  x  |
| raw depth histogram |     |     |     |     |     |     |  x  |  x  |
| plant selection     |     |     |     |     |     |     |     |  x  |
| grayscale inputs    |     |     |     |     |     |     |     |  x  |
| rotated inputs      |     |     |     |     |     |     |     |  x  |
| rotated depth map   |     |     |     |     |     |     |     |  x  |
| rotation values     |     |     |     |     |     |     |     |  x  |
| calibration plot*   |     |     |  x  |  x  |  x  |  x  |  x  |  x  |

\* Only available during calibration.

# Organizational overview

## Scripts
__MeasureHeight__ - Move bot to photo locations, capture images, and run calculations.
If calibration values are not present, capture images at two different z-axis
positions to complete calibration. Otherwise, calculate and record the soil
z coordinate at the current location.

__test__ - _(for development only)_ Calculate soil height in the provided test images.

## Modules
 - __CalculateMultiple__ - Calculate soil height for any number of stereo image pairs.
Generate and save summary data and plot of the calculations at each stereo height.
   - __Plot__ - Simple plot generation. Used for disparity vs distance graph.
   - __Calculate__ - Calculate soil height or calibration values from a stereo image pair.
     - __Angle__ - Input image rotation detection.
     - __Images__ - Manage input and output images.
   - __ProcessImage__ - Individual image handling and processing.
     - __ReduceData__ - Data reduction and analysis. Find the most common depth in an image.
     - __Histogram__ - Generate image and text histograms from the provided data.
 - __Core__ - Wraps Settings, Log, Results, and FarmwareTools for ease of use.
   - __Settings__ - Import and manage inputs provided via environment variables.
(includes `Farmware` page inputs, `Run Farmware` step inputs, and other `FarmwareEnvs`.)
   - __Log__ - Send log messages, toasts, and errors.
   - __Results__ - Summarize and handle all output. Saves files and uploads results.
   - __SerialDevice__ - _(for local development only)_ Communicate with a device running the
[FarmBot Arduino Firmware](https://github.com/FarmBot/farmbot-arduino-firmware)
over a serial connection. Can be used instead of `farmware_tools.device`
for local development purposes.

![module graph](module_graph.svg)
