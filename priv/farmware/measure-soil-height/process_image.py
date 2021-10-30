#!/usr/bin/env python3.8

'Image processing.'

import numpy as np
import cv2 as cv
from reduce_data import ReduceData
from histogram import Histogram, FONT, COLORS, normalize


def rotate(image, degrees):
    'Rotate image.'
    height, width = image.shape[:2]
    center = int(width / 2), int(height / 2)
    matrix = cv.getRotationMatrix2D(center, degrees, 1)
    image = cv.warpAffine(image, matrix, (width, height))
    return image


def odd(number):
    'Ensure number is odd.'
    if number % 2 == 0:
        number += 1
    return number


def shape(image):
    'Get image shape properties.'
    height, width = image.shape[:2]
    return {'width': width, 'height': height}


class ProcessImage():
    'Process image data.'

    def __init__(self, core, image, angle, info):
        self.core = core
        self.settings = core.settings.settings
        self.results = core.results
        self.image = image.copy()
        self.info = info
        self.viewer = False
        self.data = None
        self.histogram = None
        self.saved = False
        self.angle = angle

    def reduce_data(self, **kwargs):
        'Generate reduced data.'
        self.data = ReduceData(self.core, self.image, self.info, **kwargs)

    def rotate_copy(self, image=None, direction=1):
        'Return rotated image.'
        if image is None:
            image = self.image
        angle = -self.angle
        return rotate(image, direction * angle)

    def rotate(self, direction=1):
        'Rotate image.'
        self.image = self.rotate_copy(direction=direction)

    def preprocess(self, perform_rotation=True):
        'Return pre-processed image.'
        self.show()
        image = self.image.copy()
        gray = cv.cvtColor(image, cv.COLOR_BGR2GRAY)
        blur = odd(self.settings['blur'])
        blurred = cv.medianBlur(gray, blur) if blur else gray
        rotated = self.rotate_copy(blurred) if perform_rotation else blurred
        self.show(rotated)
        return rotated

    def select_plants(self):
        'Select plants.'
        params = self.core.settings.get_plant_params()
        hsv_min = [params['hue_min'], params['sat_min'], params['val_min']]
        hsv_max = [params['hue_max'], params['sat_max'], params['val_max']]
        blurred = cv.medianBlur(self.image, params['blur'])
        hsv = cv.cvtColor(blurred, cv.COLOR_BGR2HSV)
        masked = cv.inRange(hsv, np.array(hsv_min), np.array(hsv_max))
        morph = params['morph']
        kernel = cv.getStructuringElement(cv.MORPH_ELLIPSE, (morph, morph))
        self.image = cv.morphologyEx(
            masked, cv.MORPH_CLOSE, kernel, iterations=params['iterations'])

    def normalize(self):
        'Normalize image values.'
        self.image = cv.normalize(self.image, self.image,
                                  0, 255, cv.NORM_MINMAX).astype(np.uint8)

    def reshape(self, input_image):
        'Reshape image to match input.'
        self.image = self.image.reshape(input_image.image.shape[:2])

    def channel3(self):
        'Ensure 3 channels in image.'
        if len(self.image.shape) < 3:
            self.image = np.dstack([self.image] * 3)

    def colorize(self, data, mid_only=False):
        'Colorize data according to reduced data statistics.'
        self.channel3()
        self.show()
        reduced = data.reduced
        idx = -2 if len(reduced['history']) > 1 else -1
        historical_masks = reduced['history'][idx]['masks']
        if not mid_only:
            self.image[historical_masks['low']] = COLORS['light_red']
            self.image[historical_masks['high']] = COLORS['red']
            self.image[reduced['masks']['none']] = COLORS['black']
        mid_values = self.image[reduced['masks']['mid']]
        stats = reduced['stats']
        max_v = stats['max']
        if len(mid_values) < 1:
            lower = 0
            upper = 255
        else:
            lower = min(normalize(stats['low'], max_v, 255), mid_values.min())
            upper = max(normalize(stats['high'], max_v, 255), mid_values.max())
        mid_values_normalized = normalize(mid_values, upper, 155, lower)
        green_values = 100 + mid_values_normalized
        green_values[:, 0] = 0
        green_values[:, 2] = 0
        self.image[reduced['masks']['mid']] = green_values
        self.show()

    def blend_with(self, image_b, factor=1):
        'Blend two images together according to alpha setting.'
        alpha = self.settings['image_blend_percent'] / 100. * factor
        self.image = cv.addWeighted(self.image, alpha, image_b, 1 - alpha, 0)

    def add_soil_z_annotation(self, soil_z):
        'Add the soil z height value to the image center.'
        if self.settings['image_annotate_soil_z']:
            height = shape(self.image)['height']
            width = shape(self.image)['width']
            center_y = int(height / 2 - 0.1 * height)
            center_x = int(width / 2 - 0.1 * width)
            center = (center_y, center_x)

            def _add_text(color, thickness):
                if soil_z is not None:
                    self.image = cv.putText(self.image, str(soil_z),
                                            center, FONT, 5, color, thickness)
            _add_text(COLORS['black'], 10)
            _add_text(COLORS['white'], 3)

    def show(self, image=None):
        'If enabled, open image in viewer.'
        if not self.viewer:
            return
        if image is None:
            image = self.image
        cv.imshow('', image)
        cv.waitKey()

    def create_histogram(self, calc_z=None, **kwargs):
        'Generate histogram.'
        self.core.log.debug(f'Generating {self.info.get("tag")} histogram...')
        self.histogram = Histogram(self.data, calc_z, **kwargs)
        self.show(self.histogram.histogram)

    def save_histogram(self, name):
        'Save histogram.'
        self.save(name, self.histogram.histogram)

    def save(self, name, image=None):
        'Save image to file.'
        if image is None:
            image = self.image
        name = f'{self.info["base_name"]}_{name}'
        self.results.save_image(name, image)
        self.saved = True
