#!/usr/bin/env python3.8

'Serial device.'

from time import time
import serial
from settings import Settings


class SerialDevice():
    'Communicate with a device over serial.'

    def __init__(self, settings):
        self.verbosity = settings['log_verbosity'] - 1
        self.log('Setting up serial connection...', verbosity=1)
        port = settings['serial_port']
        baud = settings['serial_baud_rate']
        self.timeout = 10
        self.serial = serial.Serial(port, baud, timeout=self.timeout)
        self.buffer = b''
        self.get(['ARDUINO STARTUP COMPLETE'])
        self.speed = {}
        self.get_speeds()
        if settings['serial_z_negative']:
            self.send('F22 P53 V1')
        if settings['serial_reset_position']:
            self.send('F84 X1 Y1 Z1')
        self.validate_params()

    def log(self, message, **kwargs):
        'Print a message.'
        error = kwargs.get('message_type') == 'error'
        if self.verbosity >= kwargs.get('verbosity', 2) or error:
            print(message)

    def send(self, command, wait_for_response=True):
        'Send a command'
        self.log(f'Sending {command}...')
        self.serial.write(bytes(command + '\r\n', 'utf-8'))
        self.get([command])
        if wait_for_response:
            code = command.split(' ')[0][1:]
            if code == '22':
                code = '21'
            if code in ['00', '41']:
                self.get(['R02'])
            else:
                self.get([f'R{code}'])

    def get(self, responses, ignore_repeat=False):
        'Fetch a response from serial.'
        self.log(f'Waiting for {responses}...')
        bytes_responses = [bytes(response, 'utf-8') for response in responses]
        found = False
        start = time()
        last_dot = start - 0.11
        while True:
            if self.verbosity > 2:
                since_last = time() - last_dot
                if since_last > 0.1:
                    print('.' * int(since_last * 10), end='', flush=True)
                    last_dot = time()
            if (time() - start) > self.timeout:
                print('timeout')
                return None
            self.buffer += self.serial.read()
            if any(self.buffer.endswith(resp) for resp in bytes_responses):
                found = True
            if found and self.buffer.endswith(b'\r\n'):
                last = self.buffer.split(b'\r\n')[-2]
                if ignore_repeat and b'R08' in last:
                    found = False
                    self.buffer = b''
                    continue
                value = last.split(b' ')[1:-1]
                self.log(f'received {value}')
                self.buffer = b''
                return value

    def validate_params(self):
        'Validate firmware parameters.'
        self.log('Validating firmware parameters...')
        self.send('F83')
        self.get(['R00', 'R88'])
        self.send('F22 P2 V1')

    def get_speeds(self):
        'Get axis speed values.'
        self.log('Fetching firmware parameters...')
        for axis, param in {'x': 71, 'y': 72, 'z': 73}.items():
            self.send(f'F21 P{param}', wait_for_response=False)
            self.speed[axis] = int(self.get(['R21'])[1].strip(b'V'))

    def wait_for_idle(self):
        'Wait for idle response.'
        self.log('Waiting for idle...')
        self.get(['R00'])

    @staticmethod
    def read_status():
        'Read status.'

    def get_current_position(self):
        'Get current device coordinates.'
        self.send('F82', wait_for_response=False)
        position = [float(r[1:]) for r in self.get(['R82'])]
        coordinate = {'x': position[0], 'y': position[1], 'z': position[2]}
        self.log(f'current position: {coordinate}')
        return coordinate

    def move_relative(self, x, y, z, speed):
        'Relative movement.'
        position = self.get_current_position()
        position['x'] += x
        position['y'] += y
        position['z'] += z
        self.log(f'Moving to {position}', verbosity=1)
        x_spd = self.speed['x'] * speed / 100.
        y_spd = self.speed['y'] * speed / 100.
        z_spd = self.speed['z'] * speed / 100.
        command = f"G00 X{position['x']} Y{position['y']} Z{position['z']}"
        command += f' A{x_spd} B{y_spd} C{z_spd}'
        self.send(command)

    def write_pin(self, pin_number, pin_value, pin_mode):
        'Write pin value.'
        self.log(f'Setting pin {pin_number} to {pin_value}')
        self.send(f'F41 P{pin_number} V{pin_value} M{pin_mode}')


if __name__ == '__main__':
    device = SerialDevice(Settings().settings)
    print(device.get_current_position())
    device.move_relative(0, 0, 0, 50)
