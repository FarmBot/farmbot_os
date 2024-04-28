#!/usr/bin/env python

'''Take a photo.

Take a photo using a USB or Raspberry Pi camera.
'''

from __future__ import print_function
import os
import sys
from time import time, sleep
import subprocess
import json


WIDTH = os.getenv('take_photo_width', '640')
HEIGHT = os.getenv('take_photo_height', '480')
ARGS_JSON_STRING = os.getenv('take_photo_args', "[]")
CAMERA_DISABLED_MSG = 'No camera selected. Choose a camera on the device page.'


def _log(text):
    try:
        import json, socket, struct
        s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        r = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        s.connect(os.environ['FARMWARE_API_V2_REQUEST_PIPE'])
        r.connect(os.environ['FARMWARE_API_V2_RESPONSE_PIPE'])
        message = bytes(json.dumps({
            'kind': 'rpc_request', 'args': {'label': ''},
            'body': [{
                'kind': 'send_message',
                'args': {'message': text, 'message_type': 'error'}}]}), 'utf-8')
        s.sendall(struct.pack('!Hii', 0xFBFB, 0, len(message)) + message)
        r.recv(10)
    except (KeyError, TypeError):
        std_print(text)
    finally:
        s.close()
        r.close()


try:
    MissingError = FileNotFoundError
except NameError:
    MissingError = OSError


def get_camera_selection():
    'Fetch camera type selected.'
    return os.getenv('camera', 'USB').upper()


def rotation_disabled():
    'Check if rotation is disabled via environment variable.'
    return '1' in os.getenv('take_photo_disable_rotation_adjustment', '1')


def std_print(text):
    'Print.'
    if not 'quiet' in os.getenv('take_photo_logging', '').lower():
        try:
            print(text, flush=True)
        except TypeError:
            print(text)


def get_video_port_list():
    'Get available video ports from /dev.'
    return [d for d in os.listdir('/dev') if d.startswith('video')]


def usb_camera_call(savepath):
    'Call fswebcam.'
    args = ['fswebcam']
    args += json.loads(ARGS_JSON_STRING)
    size = '{}x{}'.format(WIDTH, HEIGHT)
    args += ['-r', size, '-S', '10', '--no-banner', savepath]
    std_print('Calling `{}`...'.format(' '.join(args)))
    try:
        return subprocess.call(args)
    except MissingError:
        return 1


def rpi_photo_call(savepath):
    'Call raspistill.'
    width = min(int(WIDTH), 4056)
    height = min(int(HEIGHT), 3040)
    size = ['-w', str(width), '-h', str(height)]
    if height > 1500:
        size = ['-md', '3']
    args = ['raspistill'] + size + ['-o', savepath]
    std_print('Calling `{}`...'.format(' '.join(args)))
    try:
        return subprocess.call(args)
    except MissingError:
        return 1


# Takes photo and exits if rotation was disabled via environment variable.
# Without imports, logs, or processing, this is a much quicker path.
if rotation_disabled():
    SAVEPATH = '/tmp/images/{}.jpg'.format(int(time()))
    SELECTED_CAMERA = get_camera_selection()
    return_code = 0
    if 'NONE' in SELECTED_CAMERA:
        _log(CAMERA_DISABLED_MSG)
    elif 'RPI' in SELECTED_CAMERA:
        return_code = rpi_photo_call(SAVEPATH)
    else:
        ports = get_video_port_list()
        if len(ports) < 1:
            _log('USB Camera not detected.')
            sys.exit(0)
        return_code = usb_camera_call(SAVEPATH)
    if return_code == 0:
        sys.exit(0)
    else:
        std_print('command not found. Trying OpenCV...')


# start timer
START_TIME = time()

import requests
import numpy as np

FIRST_IMPORTS_COMPLETE_TIME = time()


def verbose_log(text, time_override=None):
    'Print text with time elapsed since start.'
    now = time_override if time_override is not None else time()
    elapsed = round(now - START_TIME, 4)
    timed_log = '[{:>8}] {}'.format(elapsed, text)
    log_level = os.getenv('take_photo_logging', '').lower()
    if 'quiet' in log_level:
        return
    if 'verbose' not in log_level:
        std_print(timed_log)
        return
    log_content = timed_log if 'timed' in log_level else text
    try:
        log(log_content, 'debug')
    except NameError:
        pass


def _farmware_api_url():
    major_version = int(os.getenv('FARMBOT_OS_VERSION', '0.0.0')[0])
    base_url = os.environ['FARMWARE_URL']
    return base_url + 'api/v1/' if major_version > 5 else base_url


def legacy_log(message, message_type):
    'Send a message to the log.'
    try:
        os.environ['FARMWARE_URL']
    except KeyError:
        print(message)
    else:
        log_message = '[take-photo] ' + str(message)
        headers = {
            'Authorization': 'bearer {}'.format(os.environ['FARMWARE_TOKEN']),
            'content-type': 'application/json'}
        payload = {
            'kind': 'send_message',
            'args': {'message': log_message, 'message_type': message_type}}
        requests.post(_farmware_api_url() + 'celery_script',
                      json=payload, headers=headers)


try:
    ft_import_start_msg = 'Importing Farmware Tools...'
    FT_IMPORT_START_TIME = time()
    from farmware_tools import env, device
except ImportError:
    ft_import_result_msg = 'farmware_tools import error. Using legacy logger.'
    log = legacy_log
    IMAGES_DIR = os.getenv('IMAGES_DIR')
else:
    ft_import_result_msg = 'Farmware Tools import complete.'
    IMAGES_DIR = env.Env().images_dir

    def log(message, message_type):
        'Send a log message.'
        device.log('[take-photo] {}'.format(message), message_type)


verbose_log('First imports complete.', FIRST_IMPORTS_COMPLETE_TIME)
verbose_log(ft_import_start_msg, FT_IMPORT_START_TIME)
verbose_log(ft_import_result_msg)

try:
    verbose_log('Importing OpenCV...')
    os.environ['OPENCV_VIDEOIO_DEBUG'] = '1'
    import cv2
except ImportError:
    log('OpenCV import error.', 'error')
    sys.exit(0)
else:
    verbose_log('OpenCV import complete.')


def rotate(image):
    'Rotate image if calibration data exists.'
    if rotation_disabled():
        raise KeyError('Rotation disabled.')
    angle = float(os.environ['CAMERA_CALIBRATION_total_rotation_angle'])
    sign = -1 if angle < 0 else 1
    turns, remainder = -int(angle / 90.), abs(angle) % 90  # 165 --> -1, 75
    if remainder > 45: turns -= 1 * sign  # 75 --> -1 more turn (-2 turns total)
    angle += 90 * turns                   #        -15 degrees
    image = np.rot90(image, k=turns)
    height, width, _ = image.shape
    matrix = cv2.getRotationMatrix2D((int(width / 2), int(height / 2)), angle, 1)
    return cv2.warpAffine(image, matrix, (width, height))


def image_filename():
    'Prepare filename with timestamp.'
    epoch = int(time())
    filename = '{timestamp}.jpg'.format(timestamp=epoch)
    return filename


def upload_path(filename):
    'Filename with path for uploading an image.'
    images_dir = IMAGES_DIR or '/tmp/images'
    if not os.path.isdir(images_dir):
        log('{} directory does not exist.'.format(images_dir), 'error')
    path = images_dir + os.sep + filename
    return path


def save_image(image):
    'Save an image to file after attempting rotation.'
    filename = image_filename()
    # Try to rotate the image
    try:
        verbose_log('Considering rotation...')
        final_image = rotate(image)
    except:
        verbose_log('Did not rotate image.')
        final_image = image
    else:
        verbose_log('Rotated image.')
        filename = 'rotated_' + filename
    # Save the image to file
    filename_path = upload_path(filename)
    cv2.imwrite(filename_path, final_image)
    verbose_log('Image saved: {}'.format(filename_path))


def _get_usb_device_list():
    try:
        raw_usb_results = subprocess.check_output(['lsusb'])
    except MissingError:
        verbose_log('Unable to check USB devices.')
        device_list_str = ''
    except subprocess.CalledProcessError:
        verbose_log('USB device check error.')
        device_list_str = ''
    else:
        usb_results = raw_usb_results.decode().strip().split('\n')
        usb_devices = [result.strip()[28:] for result in usb_results]
        usb_list_str = '|'.join(usb_devices)
        verbose_log('{} USB device entries detected: {}'.format(
            len(usb_results), usb_list_str))
        device_list_str = ' (Device list: {})'.format(usb_list_str)
    return device_list_str


def _open_camera(port):
    verbose_log('Opening camera...')
    try:
        camera = cv2.VideoCapture(port)
    except Exception as error:
        verbose_log(error)
    try:
        backend = camera.getBackendName()
    except:
        backend = 'not available'
    verbose_log('using backend: ' + backend)
    sleep(0.1)
    try:
        camera_open = camera.isOpened()
    except NameError:
        camera_open = False
    if not camera_open:
        verbose_log('Camera is not open.')
        log('Could not connect to camera.', 'error')
        return
    verbose_log('Camera opened successfully.')
    return camera


def _adjust_settings(camera, image_width, image_height):
    try:
        camera.set(cv2.CAP_PROP_FRAME_WIDTH, image_width)
        camera.set(cv2.CAP_PROP_FRAME_HEIGHT, image_height)
    except AttributeError:
        camera.set(cv2.cv.CV_CAP_PROP_FRAME_WIDTH, image_width)
        camera.set(cv2.cv.CV_CAP_PROP_FRAME_HEIGHT, image_height)


def _check_camera_availability(camera_path):
    try:
        pids = subprocess.check_output(['fuser', camera_path])
    except MissingError:
        verbose_log('Unable to check if busy.')
    except subprocess.CalledProcessError:
        verbose_log('Camera not busy.')
    else:
        verbose_log('{} busy. Attempting to close...'.format(camera_path))
        for pid in pids.strip().split(b' '):
            subprocess.call(['kill', '-9', pid])


def _capture_usb_image(camera):
    try:
        return camera.read()
    except Exception as error:
        verbose_log(error)
        log('Image capture error.', 'error')
        return 0, None


def _log_no_image():
    verbose_log('No image.')
    log('Problem getting image.', 'error')


def usb_camera_photo():
    'Take a photo using a USB camera.'
    # Settings
    camera_port = 0      # default USB camera port
    max_port_num = 1     # highest port to try if not detected on port
    discard_frames = 10  # number of frames to discard for auto-adjust
    max_attempts = 5     # number of failed discard frames before quit
    image_width = int(WIDTH)
    image_height = int(HEIGHT)

    # Check USB devices for camera
    device_list_str = _get_usb_device_list()
    # Check video ports for camera
    video_ports = get_video_port_list()
    verbose_log('{} video ports detected: {}'.format(
        len(video_ports), ','.join(video_ports)))
    if len(video_ports) < 1:
        log('USB Camera not detected.{}'.format(device_list_str), 'error')
        return
    max_port_num = len(video_ports) - 1
    verbose_log('Adjusting max port number to {}.'.format(max_port_num))
    ret = False
    while camera_port <= max_port_num:
        camera_path = '/dev/video' + str(camera_port)
        verbose_log('Trying {}'.format(camera_path))
        if not os.path.exists(camera_path):
            verbose_log('{} missing'.format(camera_path))
            camera_port += 1
            continue

        # Close process using camera (if open)
        _check_camera_availability(camera_path)

        # Open the camera
        camera = _open_camera(camera_port)
        if camera is None:
            return

        verbose_log('Adjusting image with test captures...')
        # Set image size
        _adjust_settings(camera, image_width, image_height)
        # Capture test frame
        ret, _ = _capture_usb_image(camera)
        if not ret:
            camera.release()
            verbose_log('Couldn\'t get frame from {}'.format(camera_path))
            camera_port += 1
            continue
        break
    if not ret:
        _log_no_image()
        return
    verbose_log('First test frame captured.')
    # Let camera adjust
    failed_attempts = 0
    for _ in range(discard_frames):
        if not camera.grab():
            verbose_log('Could not get frame.')
            failed_attempts += 1
        if failed_attempts >= max_attempts:
            break
        sleep(0.1)

    # Take a photo
    verbose_log('Taking photo...')
    ret, image = _capture_usb_image(camera)

    # Close the camera
    camera.release()

    # Output
    if ret:  # an image has been returned by the camera
        verbose_log('Photo captured.')
        save_image(image)
    else:  # no image has been returned by the camera
        _log_no_image()


def rpi_camera_photo():
    'Take a photo using the Raspberry Pi Camera.'
    tempfile = upload_path('temporary')
    verbose_log('Taking photo with Raspberry Pi camera...')
    retcode = rpi_photo_call(tempfile)
    if retcode == 0:
        verbose_log('Image captured.')
        image = cv2.imread(tempfile)
        os.remove(tempfile)
        save_image(image)
    else:
        log('Raspberry Pi Camera not detected.', 'error')


def take_photo():
    'Take a photo.'
    CAMERA = get_camera_selection()

    if 'NONE' in CAMERA:
        log(CAMERA_DISABLED_MSG, 'error')
    elif 'RPI' in CAMERA:
        rpi_camera_photo()
    else:
        usb_camera_photo()


if __name__ == '__main__':
    take_photo()
