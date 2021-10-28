"""Download an image from the Web App and use it to calibrate the camera.

download the image corresponding to the ID provided and run calibration
"""

import os
import sys

sys.path.insert(1, os.path.join(sys.path[0], '..'))

from plant_detection.PlantDetection import PlantDetection
from plant_detection import ENV
from plant_detection.Log import log

if __name__ == "__main__":
    IMAGE_ID = ENV.load('CAMERA_CALIBRATION_selected_image', get_json=False)
    if IMAGE_ID is None:
        log('No image selected.',
            message_type='error', title='historical-camera-calibration')
        sys.exit(0)
    PD = PlantDetection(coordinates=True, app=True, app_image_id=IMAGE_ID)
    PD.calibrate()
