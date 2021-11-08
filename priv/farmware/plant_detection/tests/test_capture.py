#!/usr/bin/env python
"""Capture Tests

For Plant Detection.
"""
import os
import sys
import unittest
import numpy as np
from plant_detection.Capture import Capture


class CheckCameraTest(unittest.TestCase):
    """Check for camera"""

    def setUp(self):
        self.nullfile = open(os.devnull, 'w')
        sys.stdout = self.nullfile

    def test_camera_check(self):
        """Test camera check"""
        Capture().camera_check()

    def tearDown(self):
        self.nullfile.close()
        sys.stdout = sys.__stdout__


class CheckImageSaveTest(unittest.TestCase):
    """Save captured image"""

    def setUp(self):
        self.capture = Capture()
        shape = [100, 100, 3]
        self.capture.image = np.full(shape, 200, np.uint8)
        directory = os.path.dirname(os.path.realpath(__file__))[:-6] + os.sep
        self.expected_filename = directory + 'capture.jpg'

    def test_image_save(self):
        """Test image save"""
        img_filename = self.capture.save(add_timestamp=False)
        self.assertEqual(img_filename, self.expected_filename)

    def tearDown(self):
        os.remove(self.expected_filename)
