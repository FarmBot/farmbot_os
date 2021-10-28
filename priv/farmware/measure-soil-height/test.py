#!/usr/bin/env python3.8

'Run tests.'

import os
import sys
from time import time
TIMES = {'start': time()}
if TIMES:
    from measure_height import MeasureSoilHeight
    from tests.mocks import MockDevice, MockTools, MockCV
    from tests.runner import TestRunner, print_title
TIMES['imports_done'] = time()


def _result_log(soil_z):
    return {
        'message': f'Soil height saved: {soil_z}',
        'args': (),
        'kwargs': {'message_type': 'success', 'channels': ['toast']},
    }


def _debug_log(message):
    return {
        'message': message,
        'args': (),
        'kwargs': {'message_type': 'debug', 'channels': None},
    }


def _point(soil_z):
    return {
        'pointer_type': 'GenericPointer',
        'name': 'Soil Height',
        'x': 0.0,
        'y': 0.0,
        'z': soil_z,
        'radius': 0,
        'meta': {
            'created_by': 'measure-soil-height',
            'at_soil_level': 'true',
            'color': 'gray',
        }
    }


def test_calibration():
    'Test MeasureSoilHeight calibration.'
    print_title('MeasureSoilHeight calibration', char='|')
    os.environ.clear()
    os.environ['measure_soil_height_measured_distance'] = '100'
    os.environ['measure_soil_height_repeat_capture_delay_s'] = '0'
    os.environ['measure_soil_height_verbose'] = '5'
    measure_soil = MeasureSoilHeight()
    measure_soil.device = MockDevice()
    measure_soil.core.tools.device = MockDevice()
    measure_soil.core.settings.init_device_settings()
    measure_soil.log.device = MockDevice()
    measure_soil.core.results.tools = MockTools()
    measure_soil.cv = MockCV()
    measure_soil.capture_images()
    measure_soil.calculate()
    coords = measure_soil.device.position_history
    assert coords == [
        {'x': 0, 'y': 0, 'z': 0},
        {'x': 0, 'y': 10, 'z': 0},
        {'x': 0, 'y': 10, 'z': -50},
        {'x': 0, 'y': 0, 'z': -50},
        {'x': 0, 'y': 0, 'z': 0},
    ], coords
    logs = measure_soil.log.device.log_history
    assert logs == [_result_log(-99)], logs
    envs = measure_soil.core.results.tools.config_history
    assert envs == [
        ['disparity_search_depth', 2],
        ['calibration_factor', 0.3147],
        ['calibration_disparity_offset', 159.78125],
        ['calibration_image_width', 100],
        ['calibration_image_height', 100],
        ['calibration_measured_at_z', 0.0],
        ['calibration_maximum', 164],
    ], envs
    posts = measure_soil.core.results.tools.post_history
    assert posts == [['points', _point(-99)]], posts
    pins = measure_soil.device.pin_history
    assert pins == [], pins
    count = measure_soil.cv.capture_count
    assert count == 44, count


def test_measure_soil_height():
    'Test MeasureSoilHeight.'
    print_title('MeasureSoilHeight', char='|')
    os.environ.clear()
    os.environ['measure_soil_height_measured_distance'] = '100'
    os.environ['measure_soil_height_calibration_factor'] = '1'
    os.environ['measure_soil_height_calibration_disparity_offset'] = '160'
    os.environ['measure_soil_height_repeat_capture_delay_s'] = '0'
    os.environ['measure_soil_height_verbose'] = '5'
    os.environ['measure_soil_height_log_verbosity'] = '2'
    measure_soil = MeasureSoilHeight()
    measure_soil.device = MockDevice()
    measure_soil.core.tools.device = MockDevice()
    measure_soil.core.settings.init_device_settings()
    measure_soil.log.device = MockDevice()
    measure_soil.core.results.tools = MockTools()
    measure_soil.cv = MockCV()
    measure_soil.capture_images()
    measure_soil.calculate()
    coords = measure_soil.device.position_history
    assert coords == [
        {'x': 0, 'y': 0, 'z': 0},
        {'x': 0, 'y': 10, 'z': 0},
        {'x': 0, 'y': 0, 'z': 0},
    ], coords
    logs = measure_soil.log.device.log_history
    assert logs == [
        _debug_log('[Measure Soil Height] Capturing left image...'),
        _debug_log('[Measure Soil Height] Capturing right image...'),
        _debug_log('[Measure Soil Height] Returning to starting position...'),
        _debug_log('[Measure Soil Height] Checking images...'),
        _debug_log('[Measure Soil Height] Checking image angle...'),
        _debug_log('[Measure Soil Height] Calculating disparity...'),
        _debug_log('[Measure Soil Height] Soil z range: -102 to -98'),
        _result_log(-100),
        _debug_log('[Measure Soil Height] Saving output images...'),
    ], logs
    envs = measure_soil.core.results.tools.config_history
    assert envs == [['disparity_search_depth', 2]], envs
    posts = measure_soil.core.results.tools.post_history
    assert posts == [['points', _point(-100)]], posts
    pins = measure_soil.device.pin_history
    assert pins == [], pins
    count = measure_soil.cv.capture_count
    assert count == 22, count
    params = measure_soil.cv.parameter_history
    assert params == {'width': 640, 'height': 480}, params


def test_measure_soil_height_serial(distance):
    'Test MeasureSoilHeight over serial.'
    print_title('MeasureSoilHeight serial', char='|')
    os.environ.clear()
    os.environ['measure_soil_height_measured_distance'] = distance
    os.environ['measure_soil_height_repeat_capture_delay_s'] = '0'
    os.environ['measure_soil_height_verbose'] = '5'
    os.environ['measure_soil_height_log_verbosity'] = '9'
    os.environ['measure_soil_height_use_serial'] = '1'
    os.environ['measure_soil_height_use_lights'] = '1'
    os.environ['measure_soil_height_save_reports'] = '1'
    measure_soil = MeasureSoilHeight()
    measure_soil.capture_images()
    measure_soil.calculate()
    input('Calibration complete. Ready for measurement?')
    measure_soil.images = []
    measure_soil.capture_images()
    measure_soil.calculate()


def test_calculate_multiple():
    'Test CalculateMultiple.'
    print_title('CalculateMultiple', char='_')
    os.environ.clear()
    runner = TestRunner()
    runner.pre_times = TIMES
    runner.verbosity = 5
    runner.test_data_sets()
    return not runner.status_ok


if __name__ == '__main__':
    if 'clear' in sys.argv:
        for filename in os.listdir('results'):
            os.remove(f'results/{filename}')
    if 'serial' in sys.argv:
        index = sys.argv.index('serial') + 1
        measured_distance = sys.argv[index] if len(sys.argv) > index else '100'
        test_measure_soil_height_serial(measured_distance)
        sys.exit(0)
    test_calibration()
    test_measure_soil_height()
    failure = test_calculate_multiple()
    sys.exit(bool(failure))
