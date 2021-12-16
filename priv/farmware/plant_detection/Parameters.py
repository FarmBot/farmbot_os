#!/usr/bin/env python
"""Parameters for Plant Detection.

For Plant Detection.
"""
import os
import copy
import json
import cv2
from plant_detection import ENV


class Parameters(object):
    """Input parameters for Plant Detection."""

    def __init__(self):
        """Set initial attributes and defaults."""
        self.parameters = {'blur': 5, 'morph': 5, 'iterations': 1,
                           'H': [30, 90], 'S': [20, 255], 'V': [20, 255]}
        self.defaults = {'blur': 15, 'morph': 6, 'iterations': 4,
                         'H': [30, 90], 'S': [50, 255], 'V': [50, 255],
                         'save_detected_plants': False,
                         'use_bounds': False, 'min_radius': 0, 'max_radius': 0,
                         }
        self.cdefaults = {'blur': 5, 'morph': 5, 'iterations': 1,
                          'H': [160, 20], 'S': [100, 255], 'V': [100, 255],
                          'calibration_circles_xaxis': True,
                          'image_bot_origin_location': [0, 1],
                          'calibration_circle_separation': 100,
                          'camera_offset_coordinates': [50, 100],
                          'calibration_iters': 3,
                          'total_rotation_angle': 0,
                          'invert_hue_selection': True,
                          'easy_calibration': False}
        self.array = None  # default
        self.kernel_type = 'ellipse'
        self.morph_type = 'close'
        self.dir = os.path.dirname(os.path.realpath(__file__)) + os.sep
        self.input_parameters_file = "plant-detection_inputs.json"
        self.tmp_dir = None
        self.calibration_data = None
        self.env_var_name = 'PLANT_DETECTION_options'

        # Create dictionaries of morph types
        # morph kernel type
        self.cv2_kt = {
            'ellipse': cv2.MORPH_ELLIPSE,
            'rect': cv2.MORPH_RECT,
            'cross': cv2.MORPH_CROSS
        }
        # morph type
        self.cv2_mt = {
            'close': cv2.MORPH_CLOSE,
            'open': cv2.MORPH_OPEN,
            'erode': 'erode',
            'dilate': 'dilate'}

    def save(self):
        """Save input parameters to file."""
        def _save(directory):
            input_filename = directory + self.input_parameters_file
            with open(input_filename, 'w') as input_file:
                json.dump(self.parameters, input_file)
        try:
            _save(self.dir)
        except IOError:
            self.tmp_dir = "/tmp/"
            _save(self.tmp_dir)

    def save_to_env_var(self, widget):
        """Save input parameters to environment variable."""
        if 'calibration' in widget:
            prefix = 'CAMERA_CALIBRATION_'
        else:
            prefix = 'WEED_DETECTOR_'
        for label, value in self.parameters.items():
            if 'blur' in label:
                ENV.save(prefix + 'blur', value)
            elif 'morph' in label:
                ENV.save(prefix + 'morph', value)
            elif 'iteration' in label:
                ENV.save(prefix + 'iteration', value)
            elif 'H' in label:
                ENV.save(prefix + 'H_LO', value[0])
                ENV.save(prefix + 'H_HI', value[1])
                if value[0] > value[1]:
                    ENV.save(prefix + 'invert_hue_selection', 'TRUE')
                else:
                    ENV.save(prefix + 'invert_hue_selection', 'FALSE')
            elif 'S' in label:
                ENV.save(prefix + 'S_LO', value[0])
                ENV.save(prefix + 'S_HI', value[1])
            elif 'V' in label:
                ENV.save(prefix + 'V_LO', value[0])
                ENV.save(prefix + 'V_HI', value[1])
            elif 'total_rotation_angle' in label:
                ENV.save(prefix + 'total_rotation_angle', value)
            elif 'image_bot_origin_location' in label:
                if value == [0, 1]:
                    ENV.save(prefix + 'image_bot_origin_location',
                             'bottom_left'.upper())
                if value == [0, 0]:
                    ENV.save(prefix + 'image_bot_origin_location',
                             'top_left'.upper())
                if value == [1, 1]:
                    ENV.save(prefix + 'image_bot_origin_location',
                             'bottom_right'.upper())
                if value == [1, 0]:
                    ENV.save(prefix + 'image_bot_origin_location',
                             'top_right'.upper())
            elif 'coord_scale' in label:
                ENV.save(prefix + 'coord_scale', value)
            elif 'camera_offset' in label:
                ENV.save(prefix + 'camera_offset_x', value[0])
                ENV.save(prefix + 'camera_offset_y', value[1])
            elif 'calibration_circle_separation' in label:
                ENV.save(prefix + 'calibration_object_separation', value)
            elif 'calibration_circles_xaxis' in label:
                if value:
                    ENV.save(prefix + 'calibration_along_axis', 'X')
                else:
                    ENV.save(prefix + 'calibration_along_axis', 'Y')
            elif 'easy_calibration' in label:
                if value:
                    ENV.save(prefix + 'easy_calibration', 'TRUE')
                else:
                    ENV.save(prefix + 'easy_calibration', 'FALSE')
            elif 'save_detected_plants' in label:
                if value:
                    ENV.save(prefix + 'save_detected_plants', 'TRUE')
                else:
                    ENV.save(prefix + 'save_detected_plants', 'FALSE')
            elif 'use_bounds' in label:
                if value:
                    ENV.save(prefix + 'use_bounds', 'TRUE')
                else:
                    ENV.save(prefix + 'use_bounds', 'FALSE')
            elif 'min_radius' in label:
                ENV.save(prefix + 'min_radius', value)
            elif 'max_radius' in label:
                ENV.save(prefix + 'max_radius', value)
            elif 'camera_z' in label:
                ENV.save(prefix + 'camera_z', value)
            elif 'center_pixel_location' in label:
                ENV.save(prefix + 'center_pixel_location_x', value[0])
                ENV.save(prefix + 'center_pixel_location_y', value[1])

    def load(self, widget):
        """Load input parameters from file."""
        def _load(directory):
            input_filename = directory + self.input_parameters_file
            with open(input_filename, 'r') as input_file:
                self.parameters = json.load(input_file)
        try:
            _load(self.dir)
        except IOError:
            self.tmp_dir = "/tmp/"
            _load(self.tmp_dir)
        self.add_missing_params(widget)
        return ""

    def env_var_converter(self, widget):
        """Convert environment variable contents to dictionary."""
        common_app_var_names = [
            'blur', 'morph', 'iteration',
            'H_HI', 'H_LO', 'S_HI', 'S_LO', 'V_HI', 'V_LO']
        detection_opt_names = [
            'save_detected_plants', 'use_bounds', 'min_radius', 'max_radius',
        ]
        calibration_names = [
            'total_rotation_angle', 'easy_calibration',
            'invert_hue_selection', 'image_bot_origin_location',
            'coord_scale', 'camera_offset_y', 'camera_offset_x',
            'calibration_object_separation', 'calibration_along_axis',
            'camera_z', 'center_pixel_location_x', 'center_pixel_location_y']
        options_app_var_names = [
            'WEED_DETECTOR_' + n for n in (
                common_app_var_names + detection_opt_names)]
        calibration_app_var_names = [
            'CAMERA_CALIBRATION_' + n for n in (
                common_app_var_names + calibration_names)]
        if 'calibration' in widget:
            app_var_names = calibration_app_var_names
            input_template = copy.deepcopy(self.cdefaults)
        else:
            app_var_names = options_app_var_names
            input_template = copy.deepcopy(self.defaults)
        invert_hue_selection = False
        try:
            if input_template['invert_hue_selection']:
                invert_hue_selection = True
        except KeyError:
            pass
        for name in app_var_names:
            loaded_value = ENV.load(name)
            if loaded_value is not None:
                if 'H_LO' in name:
                    input_template['H'][0] = loaded_value
                elif 'H_HI' in name:
                    input_template['H'][1] = loaded_value
                elif 'S_LO' in name:
                    input_template['S'][0] = loaded_value
                elif 'S_HI' in name:
                    input_template['S'][1] = loaded_value
                elif 'V_LO' in name:
                    input_template['V'][0] = loaded_value
                elif 'V_HI' in name:
                    input_template['V'][1] = loaded_value
                elif 'iteration' in name:
                    input_template['iterations'] = loaded_value
                elif 'calibration_along_axis' in name:
                    input_template['calibration_circles_xaxis'] = bool(
                        'x' in loaded_value.lower())
                elif 'calibration_object_separation' in name:
                    input_template[
                        'calibration_circle_separation'] = loaded_value
                elif 'image_bot_origin_location' in name:
                    if 'bottom_left' in loaded_value.lower():
                        input_template['image_bot_origin_location'] = [0, 1]
                    if 'top_left' in loaded_value.lower():
                        input_template['image_bot_origin_location'] = [0, 0]
                    if 'bottom_right' in loaded_value.lower():
                        input_template['image_bot_origin_location'] = [1, 1]
                    if 'top_right' in loaded_value.lower():
                        input_template['image_bot_origin_location'] = [1, 0]
                elif 'camera_offset_x' in name:
                    input_template[
                        'camera_offset_coordinates'][0] = loaded_value
                elif 'camera_offset_y' in name:
                    input_template[
                        'camera_offset_coordinates'][1] = loaded_value
                elif 'center_pixel_location_x' in name:
                    try:
                        input_template['center_pixel_location'][0]
                    except KeyError:
                        input_template['center_pixel_location'] = [0, 0]
                    input_template['center_pixel_location'][0] = loaded_value
                elif 'center_pixel_location_y' in name:
                    try:
                        input_template['center_pixel_location'][0]
                    except KeyError:
                        input_template['center_pixel_location'] = [0, 0]
                    input_template['center_pixel_location'][1] = loaded_value
                elif 'invert_hue_selection' in name:
                    invert_hue_selection = bool('true' in loaded_value.lower())
                elif 'easy_calibration' in name:
                    input_template['easy_calibration'] = bool(
                        'true' in loaded_value.lower())
                elif 'save_detected_plants' in name:
                    input_template['save_detected_plants'] = bool(
                        'true' in loaded_value.lower())
                elif 'use_bounds' in name:
                    input_template['use_bounds'] = bool(
                        'true' in loaded_value.lower())
                elif 'min_radius' in name:
                    input_template['min_radius'] = loaded_value
                elif 'max_radius' in name:
                    input_template['max_radius'] = loaded_value
                else:
                    for cname in calibration_names + common_app_var_names:
                        if cname in name:
                            input_template[cname] = loaded_value
        if invert_hue_selection:
            if input_template['H'][0] < input_template['H'][1]:
                input_template['H'] = input_template['H'][::-1]
        else:
            if input_template['H'][0] > input_template['H'][1]:
                input_template['H'] = input_template['H'][::-1]
        return input_template

    def load_env_var(self, widget):
        """Read input parameters from JSON in environment variable."""
        self.parameters = self.env_var_converter(widget)

    def add_missing_params(self, widget):
        """Load default input parameters for any missing parameters."""
        defaults = self.cdefaults if 'calibration' in widget else self.defaults
        for key, value in defaults.items():
            if key not in self.parameters:
                self.parameters[key] = value

    def print_input(self):
        """Print input parameters."""
        print('Processing Parameters:')
        print('-' * 25)
        if self.array is None:
            print('Blur kernel size: {}'.format(self.parameters['blur']))
            print('Morph kernel size: {}'.format(self.parameters['morph']))
            print('Iterations: {}'.format(self.parameters['iterations']))
        else:
            print('List of morph operations performed:')
            for number, morph in enumerate(self.array):
                print('{indent}Morph operation {number}'.format(
                    indent=' ' * 2, number=number + 1))
                for key, value in morph.items():
                    print('{indent}{morph_property}: {morph_value}'.format(
                        indent=' ' * 4, morph_property=key, morph_value=value))
        print('Hue:\n\tMIN: {}\n\tMAX: {}'.format(*self.parameters['H']))
        print('Saturation:\n\tMIN: {}\n\tMAX: {}'.format(
            *self.parameters['S']))
        print('Value:\n\tMIN: {}\n\tMAX: {}'.format(*self.parameters['V']))
        print('-' * 25)
