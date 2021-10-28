#!/usr/bin/env python3.8

'''Perform a full garden scan.

Prerequisites:
 * Bot with camera set up and connected to account
 * Measure soil height calibration complete ("calibrate" button in web app)

Steps (interactive):
 * Login to account
 * Set photo grid step size
 * Capture grid photos via an optimal path
 * Generate input files from captured images
 * Run Measure Soil Height for each input set
 * (optional) View results in 3D
 * (optional) Upload soil points to account
'''

import os
import sys
try:
    import paho.mqtt
except ModuleNotFoundError:
    print('PahoMQTT package required.')
    print('Try `python3.8 -m pip install -r tests/requirements.txt`')
    sys.exit(1)
from tests.account import get_token
get_token()
if os.getenv('API_TOKEN') is not None:
    from time import sleep
    import farmware_tools as farmbot
    import numpy as np
    from tests.runner import TestRunner
    from tests.account import get_input_value, generate_inputs, upload_points, CALIBRATION_KEYS, bold_text
    from settings import HSV_INIT


def prompt(message, default='y'):
    'Request user yes/no input.'
    yes = 'Y' if 'y' in default else 'y'
    no = 'N' if 'n' in default else 'n'
    proceed = input(bold_text(f'{message} ({yes}/{no}) ')) or default
    return 'y' in proceed.lower()


def get_grid_extents():
    'Return axis lengths.'
    firmware_config = farmbot.app.get('firmware_config')
    web_app_config = farmbot.app.get('web_app_config')
    default_length = {'x': web_app_config.get('map_size_x', 2900),
                      'y': web_app_config.get('map_size_y', 1400), 'z': 400}
    axis_length = {}
    for axis in ['x', 'y', 'z']:
        steps = firmware_config.get(f'movement_axis_nr_steps_{axis}', 0)
        spm = firmware_config.get(f'movement_step_per_mm_{axis}', 1)
        axis_length[axis] = (steps / spm) or default_length[axis]
    print(f'axis lengths (mm): {axis_length}')
    if not prompt('Use full axis lengths?'):
        axis_length['x'] = int(get_input_value('x limit'))
        axis_length['y'] = int(get_input_value('y limit'))
    return axis_length


def generate_grid():
    'Return grid based on step size and axis length.'
    step_size = int(get_input_value('step size'))
    axis_length = get_grid_extents()
    x, y = np.mgrid[0:axis_length['x']:step_size, 0:axis_length['y']:step_size]
    grid_locations = None
    for i, stack in enumerate(np.dstack((x, y))):
        row = stack if i % 2 == 0 else stack[::-1]
        if grid_locations is None:
            grid_locations = row
        else:
            grid_locations = np.vstack((grid_locations, row))
    return grid_locations


def scan():
    'Take stereo photos of the entire garden bed.'
    print('Photo grid:')
    grid_locations = generate_grid()
    print(f'current location: {farmbot.device.get_current_position()}')
    print(f'photo grid locations:\n{grid_locations}')
    if prompt('Proceed to each location?'):
        for grid_x, grid_y in grid_locations:
            with farmbot.device.Move() as movement:
                movement.set_position('x', int(grid_x))
                movement.set_position('y', int(grid_y))
                movement.set_position('z', 0)
                request = movement.send()
            wait_for_movement(request, grid_x, grid_y)
            sleep(1)
            farmbot.device.take_photo()
            sleep(2)
            farmbot.device.move_relative(y=10)
            sleep(1)
            farmbot.device.take_photo()
            sleep(2)
        if prompt('Return to home?'):
            zero = farmbot.device.assemble_coordinate(0, 0, 0)
            farmbot.device.move_absolute(zero)


def wait_for_movement(request, grid_x, grid_y):
    'Wait until target position is reached.'
    if request.get('response') == 'no response':
        intervals = 0
        while intervals < 100:
            intervals += 1
            sleep(1)
            position = farmbot.device.get_current_position()
            x_ok = abs(position['x'] - grid_x) < 2
            y_ok = abs(position['y'] - grid_y) < 2
            target = f'target position ({grid_x}, {grid_y})'
            if x_ok and y_ok:
                print(f'arrived at {target}')
                break
            else:
                current = f'({position["x"], position["y"]})'
                print(f'at {current} waiting to arrive at {target}')


def get_latest_image_id():
    'Return the ID of the most recent image.'
    prev_images = farmbot.app.get('images')
    if isinstance(prev_images, str):
        print('Unable to fetch Web App data.')
        sys.exit(1)
    return max([img['id'] for img in prev_images])


def fetch_settings():
    'Return env values.'
    farmware_envs = {env['key']: env['value']
                     for env in farmbot.app.get('farmware_envs')}
    settings = {}
    for prefixed_key, value in farmware_envs.items():
        if prefixed_key.startswith('measure_soil_height_'):
            key = prefixed_key.split('measure_soil_height_')[1]
            settings[key] = float(value)
        if prefixed_key == 'CAMERA_CALIBRATION_coord_scale':
            settings['millimeters_per_pixel'] = float(value)
    settings['plant_hsv'] = {key: int(farmware_envs.get(d['key']))
                             for key, d in HSV_INIT.items()
                             if farmware_envs.get(d['key']) is not None}
    if not all([settings.get(key) is not None for key in CALIBRATION_KEYS]):
        print('Calibration required.')
        sys.exit(1)
    return settings


def run():
    'Interactively run through all garden scanning steps.'
    # Last image ID before scan
    prev_id = get_latest_image_id()

    scan()

    print('generating input data files...')
    env_settings = fetch_settings()
    filename = generate_inputs(prev_id, prev_id, env_settings).split('/')[-1]

    print('measuring soil height...')
    runner = TestRunner()
    runner.verbosity = 5
    runner.include = [filename]
    runner.test_data_sets()

    if prompt('View in 3D?'):
        from tests.view import IMPORT_LOAD_TIME, View
        view = View(IMPORT_LOAD_TIME, [f'output_{filename}'])
        view.run()

    if prompt('Upload points to account?'):
        upload_points(filename)


if __name__ == '__main__':
    run()
