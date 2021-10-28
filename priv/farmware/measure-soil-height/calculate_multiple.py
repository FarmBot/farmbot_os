#!/usr/bin/env python3.8

'Perform calculations on multiple stereo image sets.'

import json
from time import time
import numpy as np
import cv2 as cv
from calculate import Calculate
from plot import Plot


def _abridged(histogram):
    low_label_mask = ['low' in h for h in histogram]
    high_label_mask = ['high' in h for h in histogram]
    if not any(low_label_mask) or not any(high_label_mask):
        return histogram
    low = low_label_mask.index(True)
    high = -high_label_mask[::-1].index(True)
    return histogram[low:high]


def _best_fit(disparity, expected):
    coefficients = []
    prev = None
    for param in zip(disparity, expected):
        if prev is None:
            prev = param
            continue
        disparities = [prev[0], param[0]]
        expecteds = [prev[1], param[1]]
        slope, intercept = np.polyfit(disparities, expecteds, 1)
        coefficients.append([round(slope, 4), round(intercept, 4)])
        prev = param
    slopes = [c[0] for c in coefficients]
    intercepts = [c[1] for c in coefficients]
    if len(slopes) % 2 == 0:
        slopes.append(0)
    new_slope = np.median(slopes)
    new_intercept = intercepts[slopes.index(new_slope)]
    return new_slope, new_intercept


class CalculateMultiple():
    'Calculate results for all stereo image sets.'

    def __init__(self, core, image_sets=None):
        self.core = core
        self.settings = core.settings.settings
        self.log = core.log
        self.results = core.results
        self.title = core.settings.title
        self.image_sets = image_sets
        self.set_results = None
        if image_sets is not None:
            self._after_load()

    def _after_load(self):
        self.set_results = [None] * len(self.image_sets)
        image = self.image_sets[0]['left'][0]['data']
        recommended_search_depth = int(2 + image.size / 1000000 * 0.5)
        provided_search_depth = int(self.settings['disparity_search_depth'])
        if provided_search_depth < recommended_search_depth:
            msg = f'Increasing search depth from {provided_search_depth}'
            msg += f' to {recommended_search_depth}'
            self.log.debug(msg)
            self.settings['disparity_search_depth'] = recommended_search_depth
            self.results.save_config('disparity_search_depth')

    def load_images(self, image_set_data):
        'Load image sets.'
        self.image_sets = []
        for i, image_set in enumerate(image_set_data):
            self.image_sets.append({})
            location = image_set.get('location')
            for stereo_id, images in image_set.items():
                if stereo_id not in ['left', 'right']:
                    continue
                self.image_sets[i][stereo_id] = []
                for image in images:
                    image['tag'] = stereo_id
                    image['location'] = image.get('location', location)
                    image['data'] = cv.imread(image['name'])
                    if image['data'] is None:
                        self.log.error(f"'{image['name']}' doesn't exist.")
                    self.image_sets[i][stereo_id].append(image)
        self._after_load()

    def calculate_multiple(self):
        'Run calculations for each image set.'
        if self.image_sets is None:
            self.log.error('No images provided.')
        for i, image_set in enumerate(self.image_sets):
            start = time()
            calculation = Calculate(self.core, image_set)
            details = calculation.calculate()
            if details is not None:
                disparity = calculation.images.output['disparity'].data.reduced
                histogram_data = disparity.get('histogram', [])
                details['histogram'] = _abridged(histogram_data)
                details['duration'] = round(time() - start, 2)
                self.set_results[i] = details

        if len(self.image_sets) > 1 and self.core.settings.images['plot']:
            self.plot()

        self.save_report()

    def plot(self):
        'Plot all set values.'
        set_results = [r for r in self.set_results
                       if r.get('values') is not None]
        if len(set_results) > 0:
            values = set_results[-1]['values']
            measured_distance = values['measured_distance']
            disparity_offset = values['disparity_offset']
            factor = values['calibration_factor']

            plot = Plot(self.core)
            plot.line(-factor, measured_distance + disparity_offset * factor)
            disparity = [r['values']['disparity'] for r in set_results]
            distance = [r['values']['calc_distance'] for r in set_results]
            expected = [r['values']['new_meas_dist'] for r in set_results]

            if len(set_results) > 1:
                self.adjust_calibration(plot, disparity, expected)

            plot.points(disparity, distance, size=10)
            plot.points(disparity, expected, thickness=2)
            plot.save('plot')

    def adjust_calibration(self, plot, disparity, expected):
        'Use expected values to adjust calibration parameters.'
        values = self.set_results[-1]['values']
        measured_distance = values['measured_distance']
        disparity_offset = values['disparity_offset']
        factor = values['calibration_factor']
        if self.settings['adjust_calibration_parameters']:
            slope, intercept = _best_fit(disparity, expected)
            plot.line(slope, intercept, thickness=2)
            new_factor = -slope
            new_offset = round((intercept - measured_distance) / new_factor, 4)
            adjustments_string = f'{disparity_offset = } {new_offset = }'
            adjustments_string += f' {factor = } {new_factor = }'
            if factor != new_factor and disparity_offset != new_offset:
                self.log.debug(adjustments_string)
                self.settings['calibration_factor'] = new_factor
                self.settings['calibration_disparity_offset'] = new_offset
                self.results.save_calibration()

    def save_report(self):
        'Save reduced data to file.'
        if self.core.settings.reports_enabled():
            filename = f'{self.settings["images_dir"]}/{self.title}results.json'
            with open(filename, 'w') as results_file:
                results_file.write(json.dumps(self.set_results, indent=2))
