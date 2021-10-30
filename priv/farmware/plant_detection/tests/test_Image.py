#!/usr/bin/env python
"""Image Tests

For Plant Detection.
"""
import os
import unittest
import numpy as np
from plant_detection.Image import Image
from plant_detection.Parameters import Parameters
from plant_detection.DB import DB


class ImageTest(unittest.TestCase):
    """Check plant identification"""

    def setUp(self):
        self.parameters = Parameters()
        self.db = DB()
        self.image = Image(self.parameters, self.db)

    def test_wrong_parameters(self):
        """Check that incompatible parameters are fixed"""
        self.image.params.parameters['blur'] = 2
        self.image.params.parameters['morph'] = 0
        self.image.params.parameters['iterations'] = 0
        self.image.load('plant_detection/soil_image.jpg')
        self.image.initial_processing()
        self.assertEqual(self.image.params.parameters['blur'], 3)
        self.assertEqual(self.image.params.parameters['morph'], 1)
        self.assertEqual(self.image.params.parameters['iterations'], 1)

    def test_image_size_reduction(self):
        """Reduce large image"""
        large_image = np.zeros([5000, 1000, 3], np.uint8)
        self.image.image_name = None
        self.image.save('large', image=large_image)
        self.image.load('large.jpg')
        new_height = self.image.images['current'].shape[0]
        self.assertEqual(new_height, 4000)

    def tearDown(self):
        try:
            os.remove('large.jpg')
        except OSError:
            pass
