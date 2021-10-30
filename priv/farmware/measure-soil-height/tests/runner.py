#!/usr/bin/env python3.8

'Run test cases.'

import os
from glob import glob
import json
from time import time
import urllib.request
import numpy as np
from calculate_multiple import CalculateMultiple
from core import Core
from tests import path
from tests.generate_images import ImageGenerator


def print_title(text='', width=100, char='='):
    'Print section header.'
    print()
    padded_text = f' {text} '
    if text == '':
        padded_text = ''
    print(padded_text.center(width, char))


def print_subtitle(text):
    'Print test case header.'
    print()
    print(text)
    print('=' * len(text))


def status_str(status):
    'Get pass/fail status string.'
    green = '\033[92m'
    red = '\033[91m'
    end = '\033[0m'
    return f'{green}PASS{end}' if status else f'{red}FAIL{end}'


def _test_img(form, z_location=0, factor=1, assertion=True):
    return {
        'generate': {'form': form, 'factor': factor},
        'location': {'x': 0, 'y': 0, 'z': z_location},
        'expected': -250,
        'assert': assertion,
    }


def generate_inputs(tests_path):
    'Generate test inputs.'
    inputs = {}
    inputs['settings'] = {'measured_distance': 250}
    inputs['images'] = [[_test_img('dots_and_line', assertion=False),
                         _test_img('dots_and_line', -50, 1.5)]]
    with open(f'{tests_path("data")}/calibration.json', 'w') as input_file:
        input_file.write(json.dumps(inputs, indent=2))
    inputs['settings']['calibration_factor'] = 0.6173
    inputs['settings']['calibration_disparity_offset'] = 158.0
    inputs['images'][0][0]['assert'] = True
    inputs['images'].append([_test_img('soil_surface')])
    with open(f'{tests_path("data")}/calculation.json', 'w') as input_file:
        input_file.write(json.dumps(inputs, indent=2))
    inputs['settings']['pre_rotation_angle'] = 25
    inputs['images'] = [[_test_img('soil_surface')]]
    inputs['images'][0][0]['location']['y'] = 1000
    with open(f'{tests_path("data")}/rotation.json', 'w') as input_file:
        input_file.write(json.dumps(inputs, indent=2))
    del inputs['settings']['pre_rotation_angle']
    inputs['settings']['verbose'] = 0
    inputs['settings']['log_verbosity'] = 2
    with open(f'{tests_path("data")}/quick_calculation.json', 'w') as input_file:
        input_file.write(json.dumps(inputs, indent=2))


def assemble_results(test_images, set_results):
    'Test result data.'
    locations = [d['left'][0]['location'] for d in test_images]
    for i, location in enumerate(locations):
        results = set_results[i] or {}
        location['z'] = results.get('values', {}).get('calculated_soil_z')
        error = (location['z'] or 0) - test_images[i]['expected']
        location['error'] = None if location['z'] is None else error
        location['assert'] = test_images[i].get('assert')
        location['angle'] = results.get('angle')
        location['duration'] = results.get('duration')
        location['data_file'] = f"{results.get('title', '')}data.npz"
    return locations


def print_result_table_row(soil):
    'Print result record table row.'
    z_str = f"{'' if soil['z'] is None else soil['z']:>9}"
    dur_str = f"{'' if soil['duration'] is None else soil['duration']:^5}"
    angle_str = f"{'' if soil['angle'] is None else soil['angle']:>9}"
    error_str = f"{'' if soil['error'] is None else soil['error']:>8}"
    result_string = f'{z_str}  {dur_str}{angle_str}{error_str}  '
    result_string += status_str(soil['result_ok'])
    result_string += f"{' ' * 3}{soil.get('error_message', '')}"
    print(result_string)


SUMMARY_KEYS = ['z', 'error', 'angle', 'duration']


def average_results(results):
    'Calculate result averages.'
    averages = {}
    for key, data in results.items():
        if key not in SUMMARY_KEYS + ['result_ok', 'error_message']:
            continue
        data = np.array([d for d in data if d is not None])
        precision = 2 if key == 'duration' else 0
        if len(data) < 1:
            average = ''
        elif key == 'result_ok':
            average = all(data)
        elif key == 'error_message':
            average = 'ERROR'
        elif precision == 0:
            average = str(int(data.mean()))
        else:
            average = str(round(data.mean(), precision))
        averages[key] = average
    return averages


def get_flat_results(results_sets):
    'Fetch flattened results.'
    results = [r for s in results_sets for r in s]
    if len(results) < 1:
        return {}
    return {key: [r.get(key) for r in results] for key in results[0].keys()}


def print_ordered_values(results, combined=False):
    'Print a list of ordered values.'
    print()
    if combined:
        print('all ordered values:'.upper())
    else:
        print('ordered values:')
    for key, result in results.items():
        if key not in SUMMARY_KEYS:
            continue
        data = np.array([d for d in result if d is not None])
        if len(data) < 1:
            continue
        avg = ''
        label = key
        if combined:
            if key == 'error':
                avg = f'{np.abs(data).mean():<8.2f}'
                label += ' (abs)'
            else:
                avg = f'{data.mean():<8.2f}'
        print(f'  {label:<12} {avg:^15} {sorted(list(data.round(2)))}')


class TestRunner():
    'Run tests.'

    def __init__(self):
        self.verbosity = 5
        self.pre_times = None or {}
        self.include = []
        self.output = {}
        self.status_ok = True
        init_inputs = not os.path.exists(path('data'))
        for directory in ['data', 'output', 'images', 'images/generated']:
            if not os.path.exists(path(directory)):
                os.makedirs(path(directory))
        if init_inputs:
            generate_inputs(path)

    @staticmethod
    def download(url):
        'Download image at the provided URL.'
        filename = f'{path("images")}/{url.split("/")[-1]}.jpg'
        if not os.path.exists(filename):
            print(f'downloading {filename}...')
            try:
                urllib.request.urlretrieve(url, filename)
            except urllib.error.HTTPError as error:
                print(error)
        else:
            print(f'{filename} already downloaded.')
        return filename

    def convert(self, data_set_images):
        'Convert data set inputs if necessary.'
        for test_images in data_set_images:
            for pair in test_images:
                if 'generate' in pair:
                    gen = ImageGenerator()
                    gen.options = {**gen.options, **pair['generate']}
                    stereo_names = gen.generate()
                    for stereo_id, filename in stereo_names.items():
                        pair[stereo_id] = [{'name': filename}]
                for stereo_id in ['left', 'right']:
                    first = pair[stereo_id][0]
                    name = first.get('name') or first.get('url')
                    if name.lower().startswith('http'):
                        pair[stereo_id][0]['name'] = self.download(name)
        return data_set_images

    @staticmethod
    def _strip_test_dir(filepath):
        return '/'.join(filepath.split('/')[2:])

    def get_input_filepaths(self):
        'Return a list of input data filepaths.'
        def _glob(string):
            return sorted(glob(f'{path("data")}/{string}**', recursive=True))
        filepaths = []
        for name in _glob(''):
            if name.endswith('.json'):
                filepaths.append(name)
        includes = []
        for include in self.include:
            includes += _glob(include)
        filepaths = [filepath for filepath in filepaths
                     if (not self.include or filepath in includes)]
        print('Input files:')
        for filepath in filepaths:
            print(f'  {self._strip_test_dir(filepath)}')
        return filepaths

    def test_data_sets(self):
        'Run data set tests.'
        for filepath in self.get_input_filepaths():
            if not os.path.exists(os.path.dirname(filepath)):
                os.makedirs(os.path.dirname(filepath))
            title = filepath.split('.')[0]
            title = self._strip_test_dir(title)
            title = title.replace('/', '|')
            print_title(title)
            self.pre_times[f'Loading `{title}` test data...'] = time()
            with open(filepath, 'r') as input_file:
                data_set = json.load(input_file)
            self.output[title] = []
            for i, test_images in enumerate(self.convert(data_set['images'])):
                print_title(i, width=50, char='-')
                self.pre_times[f'Starting image set {i}...'] = time()
                core = Core(title=f'{title}_{i}', quiet=True)
                core.settings.update('verbose', self.verbosity)
                core.settings.update('save_reports', True)
                core.settings.update('edit_fbos_config', True)
                core.settings.update('save_point', False)
                core.settings.update('image_annotate_soil_z', True)
                for key, value in data_set['settings'].items():
                    core.settings.update(key, value)
                core.log.add_pre_logs(self.pre_times)
                calcs = CalculateMultiple(core)
                calcs.load_images(test_images)
                try:
                    calcs.calculate_multiple()
                except SystemExit:
                    run_error = True
                else:
                    run_error = False
                results = assemble_results(test_images, calcs.set_results)
                if run_error:
                    for result in results:
                        result['error_message'] = ''.join(core.log.errors)
                self.output[title].append(results)
            output_filename = f'{path("output")}/output_{title}.json'
            with open(output_filename, 'w') as output_file:
                output_file.write(json.dumps(self.output[title], indent=2))
        self.print_results()
        self.print_summary()

    def get_flat_output(self):
        'Fetch flattened output.'
        results_sets = [r for v in self.output.values() for r in v]
        return get_flat_results(results_sets)

    def print_results(self):
        'Print results.'
        print_title('results'.upper())
        for title, results_sets in self.output.items():
            print_subtitle(title)
            if len(results_sets) < 1:
                continue
            ang = '' if len([a for a in get_flat_results(results_sets)['angle']
                             if a is not None]) < 1 else 'angle'
            print(f"{'soil z':>9}  {'time':^5}{ang:>9}{'error':>8}  {'status':<9}")
            print('-' * 41)
            for soil_coordinates in results_sets:
                for soil in soil_coordinates:
                    check = abs(soil.get('error') or 0) < 5
                    soil['result_ok'] = check if soil.get('assert') else True
                    if soil.get('error_message') is not None:
                        soil['result_ok'] = False
                    print_result_table_row(soil)
            print('-' * 41)
            flat_results = get_flat_results(results_sets)
            print_result_table_row(average_results(flat_results))
            print_ordered_values(flat_results)
        print('\n' + '-' * 50)
        print_ordered_values(self.get_flat_output(), combined=True)

    def print_summary(self):
        'Print summary.'
        print_title('summary'.upper())
        print()
        flat_output = self.get_flat_output()
        for title, result_sets in self.output.items():
            if len(result_sets) < 1:
                continue
            flat_results = get_flat_results(result_sets)
            status = status_str(all(flat_results['result_ok']))
            print(f'{title}: {status}')
        print_title()
        self.status_ok = all(flat_output.get('result_ok', []))
