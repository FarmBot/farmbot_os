#!/usr/bin/env python3.8

'Results output.'

import os
import json
import cv2 as cv


class Results():
    'Save results.'

    def __init__(self, settings, tools, log):
        self.settings_class = settings
        self.settings = settings.settings
        self.tools = tools
        self.log = log
        self.saved = {
            'farmware_env': [], 'points': [], 'images': [], 'data': [],
            'logs': self.log.sent, 'fbos_config': [],
        }

    def save_config(self, key):
        'Save config value.'
        farmware_name = self.settings['farmware_name']
        farmware_name_lower = farmware_name.lower().replace(' ', '_')
        value = self.settings[key]
        self.tools.set_config_value(farmware_name, key, value)
        self.saved['farmware_env'].append({
            'key': f'{farmware_name_lower}_{key}',
            'value': value,
        })

    def save_calibration(self):
        'Save calculated calibration results.'
        keys = [k for k in self.settings if k.startswith('calibration_')]
        for key in keys:
            self.save_config(key)

    def save_soil_height(self, soil_z):
        'Save soil height.'
        if self.settings['edit_fbos_config']:
            fbos_config_update = {'soil_height': soil_z}
            self.tools.app.patch('fbos_config', payload=fbos_config_update)
            self.saved['fbos_config'].append(fbos_config_update)
        if self.settings['save_point']:
            soil_height_point = {
                'pointer_type': 'GenericPointer',
                'name': 'Soil Height',
                'x': self.settings['initial_position'].get('x'),
                'y': self.settings['initial_position'].get('y'),
                'z': soil_z,
                'radius': self.settings['soil_height_point_radius'],
                'meta': {
                    'created_by': 'measure-soil-height',
                    'at_soil_level': 'true',
                    'color': 'gray',
                },
            }
            self.tools.app.post('points', soil_height_point)
            self.saved['points'].append(soil_height_point)
        self.log.log(f'Soil height saved: {soil_z}',
                     log_type='success', channels=['toast'])

    def save_image(self, name, image):
        'Save image.'
        images_dir = self.settings['images_dir']
        if not os.path.exists(images_dir):
            os.mkdir(images_dir)
        filepath = f'{images_dir}/{self.settings_class.title}{name}.jpg'
        cv.imwrite(filepath, image)
        filesize = f'{os.path.getsize(filepath) / 1024.:.1f} KiB'
        self.saved['images'].append({'path': filepath, 'size': filesize})

    def save_report(self, all_images):
        'Save reduced data to file.'
        directory = self.settings['images_dir']
        if self.settings_class.reports_enabled():
            self.log.debug('Saving data report...')
            inputs = {i.info['tag']: i.data for d in all_images.input.values()
                      for i in d}
            output_tags = [
                'disparity',
                'disparity_from_stereo',
                'disparity_from_flow',
                'angles',
                'dx', 'dy',
            ]
            outputs = {tag: all_images.output.get(tag).data for tag in output_tags
                       if all_images.output.get(tag) is not None}
            images = {}
            for key, data in {**inputs, **outputs}.items():
                reduced = data.reduced
                images[key] = {
                    'name': data.info.get('name'),
                    'tag': data.info.get('tag'),
                    'coordinates': data.info.get('location'),
                    'calculations': data.report.get('calculations'),
                    'top_values': data.report['top_values']['top_values'],
                    'histogram': reduced.get('histogram'),
                    'stats': reduced['stats'],
                    'stat_history': [d['stats'] for d in reduced['history'][:-1]],
                }
            filepath = f'{directory}/{all_images.base_name}_results.json'
            self.saved['data'].append(filepath)
            self.saved['data'].append(f'{directory}/settings.json')
            report = {
                'output': self.saved,
                'images': images,
            }
            with open(filepath, 'w') as results_file:
                results_file.write(json.dumps(report, indent=2))
