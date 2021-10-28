#!/usr/bin/env python3.8

'Settings initialization.'

import os
import json
from time import sleep

DEFAULTS = {
    'input_coverage_threshold': 5,
    'disparity_coverage_threshold': 2,
    'pixel_value_threshold': 1,
    'camera_port': 0,
    'reverse_image_order': False,
    'repeat_capture_delay_s': 3,
    'read_position_delay': 0.5,
    'frame_discard_count': 10,
    'stereo_y': 10,
    'set_offset_mm': 50,
    'assume_target_reached': False,
    'number_of_stereo_sets': 2,
    'force_sets': False,
    'movement_speed_percent': 100,
    'blur': 0,
    'use_plant_color_mask': True,
    'soil_height_point_radius': 0,
    'edit_fbos_config': False,
    'save_point': True,
    'capture_count_at_each_location': 1,
    'image_blend_percent': 50,
    'wide_sigma_threshold': 10,
    'selection_width': 3,
    'disparity_percent_threshold': 1.1,
    'angle_percent_threshold': 3,
    'delta_value_threshold': 0.25,
    'use_flow': False,
    'adjust_calibration_parameters': False,
    'image_annotate_soil_z': False,
    'capture_only': False,
    'save_reports': False,
    'exit_on_error': True,
    'use_serial': False,
    'serial_port': '/dev/ttyUSB0',
    'serial_baud_rate': 115200,
    'serial_reset_position': False,
    'serial_z_negative': True,
    'use_lights': False,
    'pre_rotation_angle': 0,
    'time': False,
}

STRINGS = [
    'serial_port',
]
FLOATS = [
    'disparity_percent_threshold',
    'delta_value_threshold',
    'read_position_delay',
]

with open('manifest.json', 'r') as manifest_file:
    manifest_configs_list = json.load(manifest_file).get('config', {}).values()
manifest_configs = {config['name']: config for config in manifest_configs_list}

HSV_INIT = {
    'hue_min': {'key': 'WEED_DETECTOR_H_LO', 'default': '30'},
    'hue_max': {'key': 'WEED_DETECTOR_H_HI', 'default': '90'},
    'sat_min': {'key': 'WEED_DETECTOR_S_LO', 'default': '50'},
    'sat_max': {'key': 'WEED_DETECTOR_S_HI', 'default': '255'},
    'val_min': {'key': 'WEED_DETECTOR_V_LO', 'default': '50'},
    'val_max': {'key': 'WEED_DETECTOR_V_HI', 'default': '255'},
    'blur': {'key': 'WEED_DETECTOR_blur', 'default': '15'},
    'morph': {'key': 'WEED_DETECTOR_morph', 'default': '6'},
    'iterations': {'key': 'WEED_DETECTOR_iteration', 'default': '4'},
}


class Settings():
    'Farmware settings.'

    def __init__(self, tools=None, title=None):
        self.farmware_name = 'Measure Soil Height'
        self.settings = {}
        self.tools = tools
        self._init()
        self.title = f'{title}_' if title is not None else ''
        self.save(self.settings['images_dir'])
        self.images = self.get_image_settings()

    def _get_config(self, key, default, type_=int):
        prefix = self.farmware_name.lower().replace(' ', '_')
        return type_(os.getenv(f'{prefix}_{key}', default))

    def _get_manifest_config(self, key):
        'Get config input.'
        return self._get_config(key, manifest_configs[key]['value'], float)

    def _init(self):
        'Load settings from env and state.'
        for key, default in DEFAULTS.items():
            type_ = str if key in STRINGS else int
            type_ = float if key in FLOATS else type_
            self.settings[key] = self._get_config(key, default, type_)

        self.settings['farmware_name'] = self.farmware_name

        for key in manifest_configs.keys():
            self.settings[key] = float(self._get_manifest_config(key))

        width_key = 'take_photo_width'
        height_key = 'take_photo_height'
        self.settings['capture_width'] = int(os.getenv(width_key, '640'))
        self.settings['capture_height'] = int(os.getenv(height_key, '480'))

        rotation_key = 'CAMERA_CALIBRATION_total_rotation_angle'
        rotation_angle = float(os.getenv(rotation_key, '0'))
        self.settings['other_rotation'] = rotation_angle

        pixel_scale_key = 'CAMERA_CALIBRATION_coord_scale'
        pixel_scale = float(os.getenv(pixel_scale_key, '0'))
        self.settings['millimeters_per_pixel'] = pixel_scale

        self.settings['plant_hsv'] = {key: int(os.getenv(d['key'], d['default']))
                                      for key, d in HSV_INIT.items()}

        self.settings['images_dir'] = (
            (self.tools.env.images_dir if self.tools is not None else None)
            or 'results')

    def init_device_settings(self):
        'Load settings from device.'
        device = self.tools.device
        firmware_params = device.get_bot_state().get('mcu_params', {})
        self.settings['negative_z'] = firmware_params.get(
            'movement_home_up_z', 1)
        device.read_status()
        sleep(self.settings['read_position_delay'])
        loc = device.get_current_position()
        position = {axis: float(loc.get(axis)) for axis in ['x', 'y', 'z']
                    if loc is not None and loc.get(axis) is not None}
        self.settings['initial_position'] = position

    def get_plant_params(self):
        'Return plant HSV parameters.'
        return {key: int(self.settings['plant_hsv'].get(key, d['default']))
                for key, d in HSV_INIT.items()}

    def get_image_settings(self):
        'Set image output settings.'
        img_verbosity = self.settings['verbose']
        return {
            'single_input': img_verbosity == 1,
            'output_enabled': img_verbosity > 1,
            'plot': img_verbosity > 1,
            'depth_color': img_verbosity > 4 or img_verbosity == 2,
            'depth_blend': img_verbosity > 5 or img_verbosity == 2,
            'depth_bw': img_verbosity > 5 or img_verbosity == 3,
            'inputs': img_verbosity > 3 and img_verbosity != 5,
            'collage': img_verbosity > 4,
            'multi_depth': img_verbosity > 5,
            'histograms': img_verbosity > 5,
            'extras': img_verbosity > 6,
        }

    def update(self, key, value):
        'Update a setting value.'
        self.settings[key] = value
        self.images = self.get_image_settings()
        self.save(self.settings['images_dir'])

    def load(self, directory):
        'Load settings from file.'
        with open(f'{directory}/settings.json', 'r') as settings_file:
            self.settings = json.loads(settings_file)

    def reports_enabled(self):
        'Check if report files should be saved.'
        directory = self.settings['images_dir']
        enabled = self.settings['save_reports'] and directory == 'results'
        if enabled:
            if not os.path.exists(directory):
                os.mkdir(directory)
        return enabled

    def save(self, directory):
        'Save settings to file.'
        if self.reports_enabled():
            name = self.settings.get('image_base_name')
            name = f'{name}_' if name is not None else ''
            filename = f'{directory}/{self.title}{name}settings.json'
            with open(filename, 'w') as settings_file:
                settings_file.write(json.dumps(self.settings, indent=2))
