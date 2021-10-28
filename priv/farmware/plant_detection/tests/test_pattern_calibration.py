#!/usr/bin/env python

"""PatternCalibration Tests

For Plant Detection.
"""
import unittest
import cv2
import numpy as np
from plant_detection.PatternCalibration import PatternCalibration
from .test_P2C import rotate


class PatternCalibrationTest(unittest.TestCase):
    """Check calibration results."""

    def test_calibration_results(self, ):
        """Check calibration results."""
        offset_groups = [
            {'offsets': [[0, 0], [0, 50], [-50, 50]],
             'origin': [0, 1], 'angle': -13.76},
            {'offsets': [[0, 0], [0, 50], [50, 50]],
             'origin': [1, 1], 'angle': -15.15},
            {'offsets': [[0, 0], [0, -50], [-50, -50]],
             'origin': [0, 0], 'angle': -13.76},
            {'offsets': [[0, 0], [0, -50], [50, -50]],
             'origin': [1, 0], 'angle': -15.15},
        ]
        for offset_group in offset_groups:
            results = {}
            pattern_calibration = PatternCalibration(results)
            images = []
            for i, offset in enumerate(offset_group['offsets']):
                images.append(np.zeros([1000, 2000, 3], np.uint8))
                for j in range(5):
                    for k in range(4):
                        loc = ((165 + j * 30) * 4 + offset[0],
                               (70 + k * 30) * 4 + offset[1])
                        cv2.circle(images[i], loc, 20, (255, 255, 255), -1)
                    for k in range(3):
                        loc = ((150 + j * 30) * 4 + offset[0],
                               (85 + k * 30) * 4 + offset[1])
                        cv2.circle(images[i], loc, 20, (255, 255, 255), -1)
                images[i] = rotate(images[i], 15)
            pattern_calibration.dot_images = {
                0: {'image': images[0], 'coordinates': {'z': 0}},
                1: {'image': images[1], 'coordinates': {'z': 0}},
                2: {'image': images[2], 'coordinates': {'z': 0}},
            }

            pattern_calibration.calibrate()

            origin = offset_group['origin']
            angle = offset_group['angle']
            self.assertEqual(results['image_bot_origin_location'], origin)
            self.assertEqual(results['center_pixel_location'], [1000, 500])
            self.assertEqual(results['total_rotation_angle'], angle)
            self.assertEqual(results['camera_z'], 0)
            self.assertEqual(results['coord_scale'], 0.25)

    def test_calculate_rotation(self):
        """Check rotation calculation."""
        pattern_calibration = PatternCalibration({})
        center = [320, 240]
        pattern_calibration.center = center

        angles = range(0, 370, 10)
        thetas = np.deg2rad(angles)
        xs = center[0] + 100 * np.cos(thetas)
        ys = center[1] + 100 * np.sin(thetas)

        for angle, x, y in zip(angles, xs, ys):
            adjusted_angle = angle - 180 if angle > 90 else angle
            adjusted_angle = angle - 360 if angle > 269 else adjusted_angle
            rotation = pattern_calibration.rotation_calc([x, y])
            self.assertEqual(round(rotation, 2), round(adjusted_angle, 2))

    def test_calculate_origin(self):
        """Check origin calculation."""
        pattern_calibration = PatternCalibration({})
        center = [150, 200]

        for origin_x in range(2):
            for origin_y in range(2):
                x = [center[0], center[1] + 50 * (1 if origin_y else -1)]
                y = [center[0] + 50 * (1 if origin_x else -1), center[1]]
                rotated_axis_points = np.array(
                    [[center] * 3, [x] * 3, [y] * 3],
                    dtype='float32')
                origin = pattern_calibration.calculate_origin(
                    rotated_axis_points)
                self.assertEqual(origin, [origin_x, origin_y])
