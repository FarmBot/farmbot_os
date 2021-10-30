#!/usr/bin/env python3.8

'''Measure soil z height using OpenCV and FarmBot's current position.'''

import traceback
from copy import copy
from time import time, sleep
TIMES = {'start': time()}
if TIMES:
    import cv2 as cv
    TIMES['OpenCV imported.'] = time()
    from core import Core
    from calculate_multiple import CalculateMultiple
TIMES['imports_done'] = time()

f'{"Python3.8+ required"=}'


class MeasureSoilHeight():
    'Measure soil z height.'

    def __init__(self):
        self.core = Core()
        self.settings = self.core.settings.settings
        self.log = self.core.log
        self.log.add_pre_logs(TIMES)
        self.results = self.core.results
        self.device = self.core.device
        self.cv = cv
        self.images = []
        self.expected_position = None

    def capture(self, port, timestamp, stereo_id, k=None):
        'Capture image with camera.'
        camera = self.cv.VideoCapture(port)
        settings = self.settings
        camera.set(self.cv.CAP_PROP_FRAME_WIDTH, settings['capture_width'])
        camera.set(self.cv.CAP_PROP_FRAME_HEIGHT, settings['capture_height'])
        for _ in range(settings['frame_discard_count']):
            camera.grab()
            sleep(0.1)
        ret, image = camera.read()
        if not ret:
            self.log.error('Problem getting image.')
        self.device.read_status()
        sleep(settings['read_position_delay'])
        location = self.device.get_current_position()
        if settings['assume_target_reached']:
            location = copy(self.expected_position)
        self.log.debug(f'Image captured at {timestamp} {location}')
        image_save_option = self.core.settings.images
        single = stereo_id == 'left' and image_save_option['single_input']
        if settings['capture_only'] or single or image_save_option['inputs']:
            if self.settings['capture_count_at_each_location'] == 1:
                k = None
            id_ = f'_{k}' if k is not None else ''
            self.results.save_image(f'{stereo_id}{id_}', image)
        return {'data': image, 'tag': stereo_id,
                'name': timestamp, 'location': location}

    def location_captures(self, i, stereo_id, timestamp):
        'Capture images at position.'
        self.log.debug(f'Capturing {stereo_id} image...', verbosity=2)
        port = int(self.settings['camera_port'])
        for k in range(self.settings['capture_count_at_each_location']):
            sleep(self.settings['repeat_capture_delay_s'])
            capture_data = self.capture(port, timestamp, stereo_id, k)
            self.images[i][stereo_id].append(capture_data)

    def capture_images(self):
        'Capture stereo images, calculate soil height, and save to account.'
        if self.settings['use_lights']:
            self.device.write_pin(pin_number=7, pin_value=1, pin_mode=0)

        needs_calibration = self.settings['calibration_factor'] == 0
        use_sets = needs_calibration or self.settings['force_sets']
        sets = self.settings['number_of_stereo_sets'] if use_sets else 1
        image_order = ['left', 'right']
        if self.settings['reverse_image_order']:
            image_order = image_order[::-1]
        speed = self.settings['movement_speed_percent']
        to_start = {'x': 0, 'y': 0, 'z': 0}
        self.expected_position = copy(self.settings['initial_position'])

        flip = True
        for i in range(sets):
            self.images.append({'left': [], 'right': []})
            timestamp = str(int(time()))
            self.core.settings.title = f'{timestamp}_'

            if i > 0:
                z_direction = -1 if self.settings['negative_z'] else 1
                z_relative = z_direction * self.settings['set_offset_mm']
                if self.expected_position.get('z') is not None:
                    self.expected_position['z'] += z_relative
                to_start['z'] -= z_relative
                self.device.move_relative(x=0, y=0, z=z_relative, speed=speed)
            stereo_id = image_order[int(not flip)]
            self.location_captures(i, stereo_id, timestamp)

            y_relative = self.settings['stereo_y'] * (1 if not flip else -1)
            if self.expected_position.get('y') is not None:
                self.expected_position['y'] -= y_relative
            to_start['y'] += y_relative
            self.device.move_relative(x=0, y=-y_relative, z=0, speed=speed)
            stereo_id = image_order[int(flip)]
            self.location_captures(i, stereo_id, timestamp)
            flip = not flip

        if self.settings['use_lights']:
            self.device.write_pin(pin_number=7, pin_value=0, pin_mode=0)
        self.log.debug('Returning to starting position...', verbosity=2)
        self.device.move_relative(
            x=to_start['x'],
            y=to_start['y'],
            z=to_start['z'], speed=speed)

    def calculate(self):
        'Calculate soil height.'
        if not self.settings['capture_only']:
            calculations = CalculateMultiple(self.core, self.images)
            calculations.calculate_multiple()


if __name__ == '__main__':
    measure_soil = MeasureSoilHeight()
    try:
        measure_soil.capture_images()
        measure_soil.calculate()
    except Exception as error:
        print(traceback.print_exc())
        msg = f'Error: {error}'
        exc = traceback.format_exc()
        exc = exc.replace('<', '')
        exc = exc.replace('\n', '<br>')
        msg += f'<details><pre>{exc}</pre></details>'
        measure_soil.log.error(msg)
