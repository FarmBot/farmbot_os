#!/usr/bin/env python

import os
import sys
import traceback

print('\n=================== VERSIONS and IMPORTS ===================\n')

print('FBOS', os.environ.get('FARMBOT_OS_VERSION'))
print('python', sys.version.split(' ')[0])

try:
    import requests
except ImportError:
    class requests():
        pass
    requests.__version__ = None
print('requests', requests.__version__)

try:
    import numpy
except ImportError:
    class numpy():
        pass
    numpy.__version__ = None
print('numpy', numpy.__version__)

try:
    import cv2
except ImportError:
    class cv2():
        pass
    cv2.__version__ = None
else:
    print(cv2.getBuildInformation())
print('cv2', cv2.__version__)

try:
    import farmware_tools
except ImportError:
    class farmware_tools():
        pass
    farmware_tools.__version__ = None
print('farmware_tools', farmware_tools.__version__)

try:
    import serial
except ImportError:
    class serial():
        pass
    serial.__version__ = None
print('serial', serial.__version__)

all_versions = ', '.join([f'{k}: {v}' for k, v in {
    'FBOS': os.environ.get('FARMBOT_OS_VERSION'),
    'farmware_tools': farmware_tools.__version__,
    'python': sys.version.split(' ')[0],
    'requests': requests.__version__,
    'numpy': numpy.__version__,
    'cv2': cv2.__version__,
    'serial': serial.__version__,
}.items()])

print('\n=========================== ENVS ===========================\n')

for env in os.environ.items():
    print(env)

print('\n=========================== PATH ===========================\n')

for path in sys.path:
    print(path)

print('\n======================== ERROR CHECK =======================\n')

if __name__ == '__main__':
    try:
        raise TypeError('message')
    except Exception as error:
        msg = f'Error: {error}'
        exc = traceback.format_exc()
        exc = exc.replace('<', '')
        exc = exc.replace('\n', '<br>')
        msg += f'<details><pre>{exc}</pre></details>'
        print(msg)

print('\n=========================== DONE ===========================\n')

print('OK')
farmware_tools.log(f'runtime ok. {all_versions}')
