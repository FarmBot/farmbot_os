#!/usr/bin/env python3.8

'''Core classes.'''

from farmware_tools import env, app, device, get_config_value, set_config_value
from settings import Settings
from log import Log
from results import Results
from serial_device import SerialDevice


class Core():
    'Core classes.'

    def __init__(self, title=None, quiet=False):
        self.tools = Tools(quiet)
        self.device = self.tools.device
        self.settings = Settings(self.tools, title)
        if self.settings.settings['use_serial']:
            self.device = SerialDevice(self.settings.settings)
        self.settings.init_device_settings()
        self.log = Log(self.settings.settings, self.device)
        self.results = Results(self.settings, self.tools, self.log)


def noop(*_, **__):
    'Do nothing.'


class Tools():
    'Farmware Tools wrapper.'

    def __init__(self, quiet=False):
        self.env = Env(quiet)
        self.device = Device(quiet)
        self.app = App(quiet)
        self.get_config_value = get_config_value
        self.set_config_value = set_config_value
        if quiet:
            self.get_config_value = lambda *_: {}['raise']
            self.set_config_value = lambda _, k, v: print(f'{k:<30} {v}')


class Env():
    'Farmware Tools env wrapper.'

    def __init__(self, quiet=False):
        self.images_dir = env.Env().images_dir
        if quiet:
            self.images_dir = None


class Device():
    'Farmware Tools device wrapper.'

    def __init__(self, quiet=False):
        self.get_bot_state = device.get_bot_state
        self.get_current_position = device.get_current_position
        self.log = device.log
        self.read_status = device.read_status
        self.move_relative = device.move_relative
        self.write_pin = device.write_pin
        if quiet:
            self.get_bot_state = lambda: {}
            self.get_current_position = lambda: {}
            self.log = lambda msg, **_kwargs: print(msg)
            self.read_status = lambda: None
            self.move_relative = lambda **kwargs: print(kwargs)
            self.write_pin = lambda **kwargs: print(kwargs)


class App():
    'Farmware Tools app wrapper.'

    def __init__(self, quiet=False):
        self.post = app.post
        self.patch = app.patch
        if quiet:
            self.post = lambda endpoint, payload: print(payload)
            self.patch = lambda endpoint, payload: print(payload)
