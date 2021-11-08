#!/usr/bin/env python

"""PatternCalibration Detection Tests

use `python -m plant_detection.tests.test_pattern_detection /images/`

For Plant Detection.
"""
import os
import sys
import cv2
import numpy as np
from plant_detection.PatternCalibration import PatternCalibration


def result(found):
    'Generate result text.'
    return '\033[92mOK\033[0m' if found else '\033[91mMISS\033[0m'


def save_output(filepath):
    'Save side-by-side pattern detection image results.'
    def _fn(ret, img, original):
        output_dir = '{}/output/'.format(os.path.dirname(filepath))
        if not os.path.exists(output_dir):
            os.mkdir(output_dir)
        img = cv2.cvtColor(img, cv2.COLOR_GRAY2BGR)
        img = np.concatenate((original, img), axis=1)
        if ret:
            text = 'OK'
            color = (0, 255, 0)
        else:
            text = 'MISS'
            color = (0, 0, 255)
        font = cv2.FONT_HERSHEY_SIMPLEX
        location = (original.shape[1] - 50, 50)
        img = cv2.putText(img, text, location, font, 2, color, 10)
        cv2.imwrite(output_dir + filepath.split('/')[-1], img)
    return _fn


def process_images(directory):
    'Detect pattern in images in directory.'
    pattern_calibration = PatternCalibration({})
    img_files = [f for f in os.listdir(directory) if '.' in f]
    count = 0
    for filename in img_files:
        img_path = directory + filename
        print(img_path)
        if os.path.exists(img_path):
            img = cv2.imread(img_path)
            ret, _centers = pattern_calibration.find_pattern(
                img, save_output=save_output(img_path))
            print('{:<16} {}'.format(result(ret), img_path))
            count += 1
        else:
            print('path not found:', img_path)

    if count > 0:
        print('{} result images saved to {}'.format(
            count, input_dir + 'output/'))


if __name__ == '__main__':
    input_dir = sys.argv[1]
    process_images(input_dir)
