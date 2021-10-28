#!/usr/bin/env python3.8

'Logging.'

import sys
from time import time

PREFIX = '[Measure Soil Height]'


class Log():
    'Log messages.'

    def __init__(self, settings, device):
        self.settings = settings
        self.device = device
        self.start_time = None
        self.sent = []
        self.errors = []

    def add_pre_logs(self, pre_times):
        'Add logs created before init.'
        self.start_time = pre_times.get('start')
        if self.start_time is None:
            self.start_time = time()
        times = pre_times.copy()
        for key, log_time in times.items():
            messages = {
                'start': 'Standard imports complete.',
                'imports_done': 'Imports complete.',
            }
            if key == 'start':
                if 'imports_done' not in pre_times:
                    continue
            else:
                pre_times.pop(key)
            if self.settings['log_verbosity'] > 0:
                self.debug(messages.get(key, key), log_time)

    def log(self, message, log_type=None, channels=None, **kwargs):
        'Log a message.'
        if self.settings['log_verbosity'] > 0 or log_type == 'error':
            message = self._add_elapsed_time(message, kwargs.get('log_time'))
            self.device.log(message, message_type=log_type,
                            channels=channels)
            self.sent.append({
                'message': message,
                'type': log_type,
                'channels': channels,
            })

    def _add_elapsed_time(self, message, log_time=None):
        if self.settings['time']:
            if self.start_time is None:
                self.start_time = time()
            if log_time is None:
                log_time = time()
            elapsed = log_time - self.start_time
            msg = f'[{elapsed:8.2f}] {message}'
            message = '\n'.join([(' ' * 11 + line if i > 0 else line)
                                 for i, line in enumerate(msg.split('\n'))])
        return message

    def debug(self, message, log_time=None, verbosity=3):
        'Send error message.'
        if self.settings['log_verbosity'] >= verbosity:
            self.log(f'{PREFIX} {message}',
                     log_type='debug', log_time=log_time)
        elif self.settings['log_verbosity'] > 0:
            print(message)

    def error(self, message):
        'Send error message.'
        self.log(f'{PREFIX} {message}', 'error')
        if self.settings['exit_on_error']:
            self.errors.append(message)
            sys.exit(1)
