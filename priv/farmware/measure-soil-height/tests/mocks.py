#!/usr/bin/env python3.8

'Mocks.'

from copy import copy
import numpy as np


class MockDevice():
    'Mock device.'

    def __init__(self, stale=False):
        self.stale = stale
        self.position_history = [{'x': 0, 'y': 0, 'z': 0}]
        self.log_history = []
        self.pin_history = []

    def log(self, message, *args, **kwargs):
        'Log a message.'
        log_args = {'message': message, 'args': args, 'kwargs': kwargs}
        self.log_history.append(log_args)
        print(message)

    @staticmethod
    def read_status():
        'Read status.'

    def get_current_position(self):
        'Get current device coordinates.'
        if self.stale:
            return copy(self.position_history[0])
        return copy(self.position_history[-1])

    @staticmethod
    def get_bot_state():
        'Get bot state.'
        return {}

    def move_relative(self, **kwargs):
        'Relative movement.'
        position = self.get_current_position()
        position['x'] += kwargs['x']
        position['y'] += kwargs['y']
        position['z'] += kwargs['z']
        self.position_history.append(position)

    def write_pin(self, **kwargs):
        'Write pin value.'
        self.pin_history.append(kwargs)


class MockTools():
    'Mock Farmware Tools wrapper.'

    def __init__(self):
        self.config_history = []
        self.post_history = []
        self.patch_history = []

        class MockApp():
            'Mock Farmware Tools app wrapper.'

            @staticmethod
            def post(endpoint, payload):
                'Post.'
                self.post_history.append([endpoint, payload])

            @staticmethod
            def patch(endpoint, _id, payload):
                'Patch.'
                self.patch_history.append([endpoint, payload])
        self.app = MockApp()

    def set_config_value(self, _farmware_name, key, value):
        'Set config value.'
        self.config_history.append([key, value])


class MockCV():
    'Mock OpenCV.'

    def __init__(self):
        self.CAP_PROP_FRAME_WIDTH = 'width'
        self.CAP_PROP_FRAME_HEIGHT = 'height'
        self.capture_count = 0
        self.parameter_history = {}

        class MockVideoCapture():
            'Mock VideoCapture.'

            def __init__(self, port):
                self.port = port

            @staticmethod
            def grab():
                'Get frame.'
                self.capture_count += 1
                return True

            @staticmethod
            def read():
                'Get image.'
                self.capture_count += 1
                img = np.zeros([100, 100, 3], np.uint8)
                if self.capture_count % 4 == 0:
                    col = 50
                elif self.capture_count % 3 == 0:
                    col = 30
                elif self.capture_count % 2 == 0:
                    col = 40
                else:
                    col = 50
                img[:, col:(col + 10)] = 255
                return True, img

            @staticmethod
            def set(key, value):
                'Set parameter.'
                self.parameter_history[key] = value

        self.VideoCapture = MockVideoCapture
