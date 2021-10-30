#!/usr/bin/env python

"""Calibrate camera using a grid of circles calibration card."""

import os
from time import time
import math
import cv2
import numpy as np
try:
    from farmware_tools import device
    USE_FARMWARE_TOOLS = True
except ImportError:
    from plant_detection import CeleryPy
    USE_FARMWARE_TOOLS = False
from plant_detection.Capture import Capture
from plant_detection.Log import log

ROW_COLORS = [(0, 0, 255), (0, 127, 255), (0, 186, 186), (0, 255, 0),
              (187, 187, 0), (255, 0, 0), (255, 0, 255)]
AXIS_INDEX = {'init': 0, 'x': 2, 'y': 1}
AXIS_COLORS = [
    (255, 255, 255),  # init/center: white
    (0, 0, 255),  # y-axis: red
    (255, 0, 0),  # x-axis: blue
]
RELATIVE_MOVEMENTS = [
    {'x': 0, 'y': 0, 'z': 0},
    {'x': 0, 'y': 50, 'z': 0},
    {'x': 50, 'y': 0, 'z': 0},
]


class PatternCalibration(object):
    """Determine camera calibration data using a circle grid calibration card.

    # Card details

              5 cols
     _______________________
    |                       |
    |    o   o   o   o   o  |
    |  o   o   o   o   o    |
    |    o   o   o   o   o  |
    |  o   o   o   o   o    | 7 rows
    |    o   o   o   o   o  |
    |  o   o   o   o   o    |
    |    o   o   o   o   o  |
    |_______________________|

    30mm center to center circles along horizontal and vertical lines
    15mm center to center circles in each row

    # Process

    Will take a photo, then move +50mm on the y-axis, take another photo,
    and finally move +50mm on the x-axis and take a third photo.

    Pattern must be visible in all three images, but can be in any orientation.

    positions moved to:
    | 1 > 2
    | ^
    | 0
    '-----

    where calibration card ends up in frame:
    |     0
    |     v
    | 2 < 1
    '-----
    """

    def __init__(self, calibration_data):
        """Set initial attributes.

        Arguments:
            calibration_data: P2C().calibration_params JSON
        """
        self.calibration_data = calibration_data
        self.capture = Capture(directory='/tmp/').capture
        self.pattern = {
            'size': (5, 7),
            'type': cv2.CALIB_CB_ASYMMETRIC_GRID,
            'row_circle_separation': 30,
        }
        self.dot_images = {
            AXIS_INDEX['init']: {},
            AXIS_INDEX['x']: {},
            AXIS_INDEX['y']: {},
        }
        self.output_img = None
        self.center = None
        self.axis_points = None
        self.rotation_angles = []
        self.success_flag = True
        self.relative_starting_position = None

    def count_circles(self):
        """Total number of circles in pattern."""
        return self.pattern['size'][0] * self.pattern['size'][1]

    def row_length(self):
        """Length of circle row in millimeters."""
        return (self.pattern['size'][0] - 1) * self.pattern['row_circle_separation']

    @staticmethod
    def _move(amount):
        if USE_FARMWARE_TOOLS:
            device.move_relative(amount['x'], amount['y'], amount['z'], 100)
        else:
            CeleryPy.move_relative(
                (amount['x'], amount['y'], amount['z']), speed=100)

    def move_and_capture(self):
        """Move the bot along x and y axes, take photos, and detect circles."""
        for i, movement in enumerate(RELATIVE_MOVEMENTS):
            if i > 0:
                if self.relative_starting_position is None:
                    self.relative_starting_position = {'x': 0, 'y': 0, 'z': 0}
                log('Moving to next camera calibration photo location.',
                    message_type='info', title='camera-calibration')
                self._move(movement)
                for axis in movement:
                    self.relative_starting_position[axis] -= movement[axis]
            log('Taking camera calibration photo. ({}/3)'.format(i + 1),
                message_type='info', title='camera-calibration')
            img_filename = self.capture()
            if USE_FARMWARE_TOOLS:
                coordinates = device.get_current_position()
                for axis, coordinate in coordinates.items():
                    coordinates[axis] = float(coordinate)
            else:
                coordinates = {'z': 0}
            img = cv2.imread(img_filename, 1)
            os.remove(img_filename)
            ret, centers = self.find_pattern(img, True)
            if not self.success_flag:
                self.save_image(img, str(i + 1))
                return self.success_flag
            self.dot_images[i]['circles'] = centers
            self.dot_images[i]['found'] = ret
            self.dot_images[i]['image'] = img
            self.dot_images[i]['coordinates'] = coordinates
        self.return_to_start()
        return self.success_flag

    def return_to_start(self):
        """Move back to starting position."""
        if self.relative_starting_position is not None:
            log('Returning to starting location...',
                message_type='info', title='camera-calibration')
            self._move(self.relative_starting_position)

    def get_initial_img_info(self):
        """Get initial image details."""
        self.output_img = self.dot_images[AXIS_INDEX['init']]['image'].copy()
        rows, cols, _ = self.output_img.shape
        self.center = (int(cols / 2), int(rows / 2))
        self.axis_points = [[self.center] * self.count_circles(), [], []]

    @staticmethod
    def preprocess(img, basic=False):
        'Pre-process image in preparation for pattern detection.'
        def _divide_size_by(factor):
            height = img.shape[0]
            num = int(height / factor)
            return num + 1 if num % 2 == 0 else num
        block_size = {
            'blur': _divide_size_by(100),
            'threshold': _divide_size_by(15),
            'morph': _divide_size_by(50),
        }

        img = img.copy()
        img = cv2.bitwise_not(img)
        img = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
        img = cv2.medianBlur(img, block_size['blur'])

        if basic:
            return img

        method = cv2.ADAPTIVE_THRESH_MEAN_C
        thesh_type = cv2.THRESH_BINARY
        blocksize = block_size['threshold']
        img = cv2.adaptiveThreshold(img, 255, method, thesh_type, blocksize, 2)

        kernel = np.ones((block_size['morph'], block_size['morph']), np.uint8)
        img = cv2.morphologyEx(img, cv2.MORPH_DILATE, kernel, iterations=1)

        img = cv2.medianBlur(img, block_size['blur'])
        return img

    def detect_circles(self, img, downsample=False):
        'Detect pattern in image.'
        pattern_size = self.pattern['size']
        flags = self.pattern['type']
        large = img.shape[0] > 1200
        if large and downsample:
            img = cv2.pyrDown(img)
        try:
            ret, centers = cv2.findCirclesGrid(img, pattern_size, flags=flags)
        except Exception as exception:
            print(exception)
            ret, centers = False, None
        if large and downsample and ret:
            centers *= 2
        return ret, centers

    def find_pattern(self, img, move_back=False, save_output=None):
        """Find calibration pattern circles in single image."""
        if img is None:
            log('ERROR: Calibration failed. Image missing.',
                message_type='error', title='camera-calibration')
            self.success_flag = False
        original = img.copy()
        # first pass with basic pre-processing
        img = self.preprocess(original, basic=True)
        ret, centers = self.detect_circles(img)
        if not ret:
            # second pass with heavier pre-processing
            img = self.preprocess(original)
            ret, centers = self.detect_circles(img, downsample=True)
        if save_output is not None:
            cv2.drawChessboardCorners(img, self.pattern['size'], centers, ret)
            save_output(ret, img, original)
        if not ret and save_output is None:
            if move_back:
                self.return_to_start()
            log('ERROR: Calibration failed, calibration object not ' +
                'detected in image. Check recent photos.',
                message_type='error', title='camera-calibration')
            self.success_flag = False
        return ret, centers

    def find_pattern_in_all(self):
        """Find calibration pattern circles in all images."""
        for i, dot_image in enumerate(self.dot_images.values()):
            if dot_image.get('circles') is None:
                ret, centers = self.find_pattern(dot_image['image'])
                self.dot_images[i]['circles'] = centers
                self.dot_images[i]['found'] = ret

    def combine_data(self):
        """Combine detected circle data from the three images."""
        for i in range(self.count_circles()):
            prev_axis_index = 0
            for k in range(1, 3):
                from_dot = self.dot_images[prev_axis_index]['circles'][i][0]
                to_dot = self.dot_images[k]['circles'][i][0]
                prev_axis_index += 1
                if k == 1:  # draw initial detected dots on initial image
                    center = (int(from_dot[0]), int(from_dot[1]))
                    cv2.circle(self.output_img, center, 10,
                               ROW_COLORS[i // 5], -1)
                # translate axis compass at each circle to image center
                translated = self.translate_dot(from_dot, to_dot)
                cv2.line(self.output_img, self.center,
                         translated, AXIS_COLORS[k], 3)
                self.axis_points[k].append(translated)
                if k == AXIS_INDEX['x']:
                    self.rotation_angles.append(self.rotation_calc(translated))

    def translate_dot(self, from_dot, to_dot):
        """Translate axis compass to image center."""
        center_x, center_y = self.center
        from_dot_x, from_dot_y = from_dot
        to_dot_x, to_dot_y = to_dot
        translate_x, translate_y = from_dot_x - center_x, from_dot_y - center_y
        return (int(to_dot_x - translate_x),
                int(to_dot_y - translate_y))

    def rotation_calc(self, translated_dot):
        """Calculate rotation angle using x-axis translations."""
        center_x, center_y = self.center
        x_translation, y_translation = translated_dot
        delta_x = x_translation - center_x
        delta_y = y_translation - center_y
        if delta_x == 0:
            delta_x += 0.001
        return math.degrees(math.atan(delta_y / float(delta_x)))

    def generate_rotation_matrix(self, rotation):
        """For rotating images and points."""
        return cv2.getRotationMatrix2D(tuple(self.center), rotation, 1)

    def rotate_points(self, rotation_matrix):
        """Rotate an array of points using a rotation matrix."""
        axis_points = np.array(self.axis_points, dtype='float32')
        return cv2.transform(axis_points, rotation_matrix)

    def rotate_image(self, rotation_matrix):
        """Rotate an image using a rotation matrix."""
        rows, cols, _ = self.output_img.shape
        size = (cols, rows)
        self.output_img = cv2.warpAffine(
            self.output_img, rotation_matrix, size)

    @staticmethod
    def calculate_origin(rotated_axis_points):
        """Determine image origin location from dot axis compasses."""
        origin = []
        for i in range(2):
            diffs = rotated_axis_points[i] - rotated_axis_points[i + 1]
            avg_diffs = np.mean(diffs[:, 1 - i])
            if abs(avg_diffs) < 10:
                print('Warning: small deltas.')
            origin.append(1 if avg_diffs > 0 else 0)
        both = sum(origin) % 2 == 0
        origin = [1 - o for o in origin] if both else origin
        return origin

    def calculate_scale(self):
        """Use pattern dimensions to calculate image pixel scale."""
        # first circle in first row
        x_1, y_1 = self.dot_images[AXIS_INDEX['init']]['circles'][0][0]
        # last circle in first row
        x_2, y_2 = self.dot_images[AXIS_INDEX['init']]['circles'][4][0]
        pixel_separation = math.sqrt((x_2 - x_1) ** 2 + (y_2 - y_1) ** 2)
        return self.row_length() / pixel_separation

    def draw_origin(self):
        """Draw axis compass at image origin."""
        origin = self.calibration_data['image_bot_origin_location']
        origin_x = origin[0] * self.center[0] * 2
        origin_y = origin[1] * self.center[1] * 2
        cv2.line(self.output_img, (origin_x, origin_y + 100),
                 (origin_x, origin_y - 100), AXIS_COLORS[AXIS_INDEX['y']], 10)
        cv2.line(self.output_img, (origin_x - 100, origin_y),
                 (origin_x + 100, origin_y), AXIS_COLORS[AXIS_INDEX['x']], 10)

    def calculate_parameters(self):
        """Calculate camera calibration data."""
        rotation = np.mean(self.rotation_angles)
        rotation_matrix = self.generate_rotation_matrix(rotation)
        self.rotate_image(rotation_matrix)
        rotated_axis_points = self.rotate_points(rotation_matrix)
        origin = self.calculate_origin(rotated_axis_points)
        scale = self.calculate_scale()
        z_coordinate = self.dot_images[AXIS_INDEX['init']]['coordinates']['z']
        # save parameters
        self.calibration_data['center_pixel_location'] = list(self.center)
        self.calibration_data['image_bot_origin_location'] = origin
        self.calibration_data['total_rotation_angle'] = round(rotation, 2)
        self.calibration_data['camera_z'] = z_coordinate
        self.calibration_data['coord_scale'] = round(scale, 4)

    def save_image(self, img=None, name='output'):
        """Save output image."""
        if img is None:
            img = self.output_img
        title = 'pattern_calibration'
        filename = '{}_{}_{}.jpg'.format(title, int(time()), name)
        cv2.imwrite(filename, img)
        cv2.imwrite('/tmp/images/{}'.format(filename), img)

    def calibrate(self):
        """Calibrate camera. Requires three translated images of dot grid."""
        self.get_initial_img_info()
        self.find_pattern_in_all()
        if not self.success_flag:
            return self.success_flag
        self.combine_data()
        self.calculate_parameters()
        self.draw_origin()
        return self.success_flag


if __name__ == '__main__':
    calibration_results = {}
    pattern_calibration = PatternCalibration(calibration_results)
    success = pattern_calibration.move_and_capture()
    if success:
        pattern_calibration.calibrate()
        pattern_calibration.save_image()
