#!/usr/bin/env python3.8

'Calculations.'

import numpy as np
import cv2 as cv
from process_image import shape, odd, rotate
from images import Images
from angle import Angle


class Calculate():
    'Calculate results.'

    def __init__(self, core, input_images):
        self.settings = core.settings.settings
        self.imgs = core.settings.images
        self.log = core.log
        self.results = core.results
        self.images = Images(core, input_images, self.calculate_soil_z)
        self.z_info = self.images._get_z_info()
        self.calculated_angle = 0

    def check_images(self):
        'Check capture images.'
        self.log.debug('Checking images...', verbosity=2)
        for images in self.images.input.values():
            for image in images:
                if image.image is None:
                    self.log.error('Image missing.')
                pre_rotation_angle = self.settings['pre_rotation_angle']
                if pre_rotation_angle:
                    image.image = rotate(image.image, pre_rotation_angle)
                image.reduce_data()
                content = image.data.report
                self.log.debug(content['report'])
                if content['coverage'] < self.settings['input_coverage_threshold']:
                    self.log.error('Not enough detail. Check recent images.')

    def _validate_calibration_data(self):
        calibrated = {
            'width': self.settings['calibration_image_width'],
            'height': self.settings['calibration_image_height']}
        current = shape(self.images.input['left'][0].image)
        mismatch = {k: (v and v != current[k]) for k, v in calibrated.items()}
        if any(mismatch.values()):
            self.log.error('Image size must match calibration.')

    def _z_at_dist(self, distance, z_reference=None):
        if z_reference is None:
            z_reference = self.z_info['current']
        z_value = z_reference + self.z_info['direction'] * distance
        return 0 if np.isnan(z_value) else int(z_value)

    def calculate_soil_z(self, disparity_value):
        'Calculate soil z from disparity value.'
        calculated_soil_z = None
        measured_distance = self.settings['measured_distance']
        measured_at_z = self.settings['calibration_measured_at_z']
        measured_soil_z = self._z_at_dist(measured_distance, measured_at_z)
        disparity_offset = self.settings['calibration_disparity_offset']
        calibration_factor = self.settings['calibration_factor']
        current_z = self.z_info['current']
        direction = self.z_info['direction']
        values = {
            'measured_distance': measured_distance,
            'z_offset_from_measured': self.z_info['offset'],
            'new_meas_dist': measured_distance - self.z_info['offset'],
            'measured_at_z': measured_at_z,
            'measured_soil_z': measured_soil_z,
            'disparity_offset': disparity_offset,
            'calibration_factor': calibration_factor,
            'current_z': current_z,
            'direction': direction,
            'disparity': disparity_value,
            'calculated_soil_z': calculated_soil_z,
        }
        calcs = [''] * 4
        calcs[0] += f'({measured_soil_z   = :<7}) = '
        calcs[0] += f'({measured_at_z = :<7})'
        calcs[0] += f' + {direction} * ({measured_distance = })'
        if calibration_factor == 0:
            return calculated_soil_z, {'lines': calcs, 'values': values}
        self._validate_calibration_data()
        disparity_delta = disparity_value - disparity_offset
        distance = measured_distance - disparity_delta * calibration_factor
        calculated_soil_z = self._z_at_dist(distance)
        values['disparity_delta'] = round(disparity_delta, 4)
        values['calc_distance'] = round(distance, 4)
        values['calculated_soil_z'] = calculated_soil_z
        calcs[1] += f'({disparity_delta   = :<7.1f}) = '
        calcs[1] += f'({disparity_value = :<7}) - ({disparity_offset = })'
        calcs[2] += f'({distance          = :<7.1f}) = '
        calcs[2] += f'({measured_distance = :<7})'
        calcs[2] += f' - ({disparity_delta = :.1f}) * ({calibration_factor = })'
        calcs[3] += f'({calculated_soil_z = :<7}) = '
        calcs[3] += f'({current_z = :<7}) + {direction} * ({distance = :.1f})'
        return calculated_soil_z, {'lines': calcs, 'values': values}

    def _from_stereo(self):
        self.log.debug('Calculating disparity...', verbosity=2)
        num_disparities = int(16 * self.settings['disparity_search_depth'])
        block_size_setting = int(self.settings['disparity_block_size'])
        block_size = min(max(5, odd(block_size_setting)), 255)
        if block_size != block_size_setting:
            self.settings['disparity_block_size'] = block_size
            self.results.save_config('disparity_block_size')
        stereo = cv.StereoBM().create(num_disparities, block_size)
        disparities = []
        for j, left_image in enumerate(self.images.input['left']):
            for k, right_image in enumerate(self.images.input['right']):
                left = left_image.preprocess()
                right = right_image.preprocess()
                result = stereo.compute(left, right)
                multiple = len(self.images.input['left']) > 1
                if multiple and self.imgs['multi_depth']:
                    tag = f'disparity_{j}_{k}'
                    self.images.output_init(result, tag, reduce=False)
                    self.images.output[tag].normalize()
                    self.images.output[tag].save(f'depth_map_bw_{j}_{k}')
                disparities.append(result)
        disparity_data = disparities[0]
        for computed in disparities[1:]:
            mask = disparity_data < self.settings['pixel_value_threshold']
            disparity_data[mask] = computed[mask]
        self.images.output_init(disparity_data, 'disparity_from_stereo')

    def _from_flow(self):
        self.log.debug('Calculating flow...')
        flow = Angle(self.settings, self.log, self.images)
        flow.calculate()
        self.images.set_angle(flow.angle)
        self.calculated_angle = flow.angle
        disparity_from_flow = self.images.output['disparity_from_flow']
        _soil_z_ff, details_ff = self.calculate_soil_z(
            disparity_from_flow.data.reduced['stats']['mid'])
        disparity_from_flow.data.report['calculations'] = details_ff

    def calculate_disparity(self):
        'Calculate and reduce disparity data.'
        self._from_flow()
        self._from_stereo()

        output = self.images.output
        output['raw_disparity'] = output.get('disparity_from_stereo')
        if self.settings['use_flow']:
            self.images.rotated = False
            output['raw_disparity'] = output.get('disparity_from_flow')

        if output['raw_disparity'] is None:
            self.log.error('No algorithm chosen.')

        disparity = self.images.filter_plants(output['raw_disparity'].image)
        disparity[-1][-1] = self.settings['calibration_maximum']
        self.images.output_init(disparity, 'disparity')
        self._check_disparity()

    def _check_disparity(self):
        data = self.images.output['disparity'].data
        if data.data.max() < 1:
            msg = 'Zero disparity.'
            self.save_debug_output()
            self.log.error(msg)
        percent_threshold = self.settings['disparity_percent_threshold']
        if data.reduced['stats']['mid_size_p'] < percent_threshold:
            msg = "Couldn't find surface."
            self.save_debug_output()
            self.log.error(msg)

    def calculate(self):
        'Calculate disparity, calibration factor, and soil height.'
        self.check_images()

        missing_measured_distance = self.settings['measured_distance'] == 0
        missing_calibration_factor = self.settings['calibration_factor'] == 0
        if missing_measured_distance and missing_calibration_factor:
            self.log.error('Calibration measured distance input required.')

        self.calculate_disparity()
        self.disparity_debug_logs()

        missing_disparity_offset = self.settings['calibration_disparity_offset'] == 0
        if missing_disparity_offset:
            self.set_disparity_offset()
        elif missing_calibration_factor:
            self.set_calibration_factor()
            self.results.save_calibration()

        details = {}
        if not missing_disparity_offset:
            disparity = self.images.output['disparity'].data.report
            soil_z, details = self.calculate_soil_z(disparity['mid'])
            if len(details['lines']) > 0:
                self.log.debug('\n'.join(details['lines']))
            disparity['calculations'] = details
            low_soil_z, _ = self.calculate_soil_z(disparity['low'])
            high_soil_z, _ = self.calculate_soil_z(disparity['high'])
            soil_z_range_text = f'Soil z range: {low_soil_z} to {high_soil_z}'
            self.log.debug(soil_z_range_text, verbosity=2)
            disparity['calculations']['lines'].append(soil_z_range_text)
            use_flow = self.settings['use_flow']
            alt = 'disparity_from_stereo' if use_flow else 'disparity_from_flow'
            disparity_alt = self.images.output.get(alt)
            if disparity_alt is not None:
                details_alt = disparity_alt.data.report.get('calculations')
                if details_alt is not None:
                    soil_z_alt = details_alt['values']['calculated_soil_z']
                    msg = f'(alternate method would have calculated {soil_z_alt})'
                    self.log.debug(msg)
            if missing_calibration_factor:
                self.check_soil_z(details['values'])
            self.results.save_soil_height(soil_z)

        details['title'] = self.images.core.settings.title
        details['method'] = 'flow' if self.settings['use_flow'] else 'stereo'
        details['angle'] = self.calculated_angle

        self.save_debug_output()

        return details

    def save_debug_output(self):
        'Save debug output.'
        self.images.save()
        self.images.save_data()
        self.results.save_report(self.images)

    def check_soil_z(self, values):
        'Verify soil z height is within expected range.'
        calculated_soil_z = values['calculated_soil_z']
        expected_soil_z = values['measured_soil_z']
        if abs(calculated_soil_z - expected_soil_z) > 2:
            error_message = 'Soil height calculation error: '
            error_message += f'expected {expected_soil_z} got {calculated_soil_z}'
            self.log.error(error_message)

    def disparity_debug_logs(self):
        'Send disparity debug logs.'
        disparity = self.images.output['disparity'].data.report
        value = disparity['mid']
        coverage = disparity['coverage']
        self.log.debug(disparity['report'])
        self.log.debug(f'Average disparity: {value} {coverage}% coverage')
        if coverage < self.settings['disparity_coverage_threshold']:
            self.log.error('Not enough disparity information. Check images.')

    def set_disparity_offset(self):
        'Set disparity offset.'
        self.log.debug('Saving disparity offset...')
        disparity = self.images.output['disparity'].data
        self.settings['calibration_disparity_offset'] = disparity.report['mid']
        self.log.debug(f'z: {self.z_info}')
        self.settings['calibration_measured_at_z'] = self.z_info['current']
        img_size = shape(self.images.input['left'][0].image)
        self.settings['calibration_image_width'] = img_size['width']
        self.settings['calibration_image_height'] = img_size['height']
        self.settings['calibration_maximum'] = int(disparity.data.max())

    def set_calibration_factor(self):
        'Set calibration_factor.'
        self.log.debug('Calculating calibration factor...', verbosity=2)
        disparity = self.images.output['disparity'].data.report['mid']
        disparity_offset = self.settings['calibration_disparity_offset']
        disparity_difference = disparity - disparity_offset
        if disparity_difference == 0:
            self.log.error('Zero disparity difference.')
        if self.z_info['offset'] == 0:
            self.log.debug(f'z: {self.z_info}')
            self.log.error('Zero offset.')
        factor = round(self.z_info['offset'] / disparity_difference, 4)
        self.settings['calibration_factor'] = factor
