#!/usr/bin/env python

'Take Photo Tests.'

import os
import sys
import unittest
os.environ['take_photo_disable_rotation_adjustment'] = '0'
import take_photo
import numpy as np
try:
    import farmware_tools
except ImportError:
    FT_IMPORTED = False
else:
    FT_IMPORTED = True
try:
    import cv2
except ImportError:
    CV2_IMPORTED = False
else:
    CV2_IMPORTED = True
try:
    from unittest import mock
except ImportError:
    import mock

OUTPUT_FILENAME = 'output.txt'


def read_output_file(output_file):
    'Read test output file.'
    output_file.close()
    with open(OUTPUT_FILENAME, 'r') as output_file:
        output = output_file.read().lower()
    sys.stdout = sys.__stdout__
    print('')
    print(os.environ)
    print('>' * 20)
    print(output)
    print('<' * 20)
    return output


os.environ.clear()
ENVS = [
    'take_photo_logging',
    'camera',
    'IMAGES_DIR',
    'take_photo_width',
    'take_photo_height',
    'take_photo_disable_rotation_adjustment',
    'CAMERA_CALIBRATION_total_rotation_angle',
    'FARMBOT_OS_VERSION',
    'FARMWARE_URL',
    'FARMWARE_TOKEN',
    'FARMWARE_API_V2_REQUEST_PIPE',
    'FARMWARE_API_V2_RESPONSE_PIPE',
]


def re_import():
    try:
        reload(take_photo)
    except NameError:
        import importlib
        importlib.reload(take_photo)


def _prepare_fuser_mock(**kwargs):
    def _fuser_mock(*_args):
        if kwargs.get('missing'):
            try:
                MissingError = FileNotFoundError
            except NameError:
                MissingError = OSError
            raise MissingError
        if kwargs.get('busy'):
            return b' 1 2 3'
        else:
            import subprocess
            raise subprocess.CalledProcessError
    return _fuser_mock


def _prepare_mock_capture(**kwargs):
    def mocked_video_capture(*_args):
        'Used by mock.'
        class MockVideoCapture():
            'Mock cv2.VideoCapture'

            @staticmethod
            def isOpened():
                'is camera open?'
                ret = kwargs.get('isOpened')
                return True if ret is None else ret

            @staticmethod
            def getBackendName():
                'get capture backend'
                if kwargs.get('raise_backend'):
                    raise NameError('mock error')
                return 'mock'

            @staticmethod
            def grab():
                'get frame'
                ret = kwargs.get('grab_return')
                return True if ret is None else ret

            @staticmethod
            def read():
                'get image'
                if kwargs.get('raise_read'):
                    raise NameError('mock error')
                default_return = True, np.zeros([10, 10, 3], np.uint8)
                return kwargs.get('read_return') or default_return

            @staticmethod
            def set(*_args):
                'set parameter'
                return

            @staticmethod
            def release():
                'close camera'
                return

        if kwargs.get('raise_open'):
            raise IOError('mock error')
        return MockVideoCapture()
    return mocked_video_capture


def _prepare_mock_socket(**_kwargs):
    def mocked_socket(*_args):
        class MockSocket():
            @staticmethod
            def connect(_): return
            @staticmethod
            def sendall(req): print(req)
            @staticmethod
            def recv(_): return
            @staticmethod
            def close(): return
        return MockSocket()
    return mocked_socket


class TakePhotoTest(unittest.TestCase):
    'Test Take Photo.'

    def setUp(self):
        for env in ENVS:
            try:
                del os.environ[env]
            except KeyError:
                pass
        os.environ['IMAGES_DIR'] = '/tmp'
        os.environ['take_photo_disable_rotation_adjustment'] = '0'
        self.outfile = open(OUTPUT_FILENAME, 'w')
        sys.stdout = self.outfile

    def test_default(self):
        'Test default Take Photo.'
        re_import()
        take_photo.take_photo()
        output = read_output_file(self.outfile)
        self.assertGreater(output.count('[ '), 3)
        self.assertLess(output.count('send_message'), 3)
        self.assertFalse('rotated' in output)

    def test_quiet(self):
        'Test quiet log level.'
        os.environ['take_photo_logging'] = 'quiet'
        re_import()
        take_photo.take_photo()
        output = read_output_file(self.outfile)
        self.assertFalse('[ ' in output)

    def test_verbose(self):
        'Test verbose log level.'
        os.environ['take_photo_logging'] = 'verbose'
        re_import()
        take_photo.take_photo()
        output = read_output_file(self.outfile)
        self.assertFalse('[ ' in output)
        if FT_IMPORTED:
            self.assertGreater(output.count('send_message'), 3)

    def test_timed_verbose(self):
        'Test timed verbose log level.'
        os.environ['take_photo_logging'] = 'verbose_timed'
        re_import()
        take_photo.take_photo()
        output = read_output_file(self.outfile)
        self.assertTrue('[ ' in output)
        if FT_IMPORTED:
            self.assertGreater(output.count('send_message'), 3)

    @unittest.skipIf(FT_IMPORTED, '')
    @mock.patch('requests.post', mock.Mock())
    def test_verbose_legacy(self):
        'Test verbose log level with legacy log.'
        os.environ['take_photo_logging'] = 'verbose'
        os.environ['FARMWARE_URL'] = 'url'
        os.environ['FARMWARE_TOKEN'] = 'token'
        re_import()
        take_photo.take_photo()
        output = read_output_file(self.outfile)
        self.assertFalse('[ ' in output)

    @mock.patch('os.listdir', mock.Mock(side_effect=lambda _: ['video0']))
    @mock.patch('os.path.exists', mock.Mock())
    @mock.patch('cv2.VideoCapture', _prepare_mock_capture())
    def test_capture_success(self):
        'Test image capture.'
        del os.environ['IMAGES_DIR']
        re_import()
        take_photo.take_photo()
        output = read_output_file(self.outfile)
        self.assertTrue('saved' in output)
        self.assertTrue('directory does not exist' in output)

    @mock.patch('os.listdir', mock.Mock(
        side_effect=lambda _: ['video0', 'video1', 'video2']))
    def test_not_at_port(self):
        'Test not at video ports.'
        del os.environ['IMAGES_DIR']
        re_import()
        take_photo.take_photo()
        output = read_output_file(self.outfile)
        self.assertFalse('saved' in output)

    @mock.patch('os.listdir', mock.Mock(side_effect=lambda _: ['video0']))
    @mock.patch('os.path.exists', mock.Mock())
    @mock.patch('cv2.VideoCapture', _prepare_mock_capture(raise_open=True))
    def test_camera_open_error(self):
        'Test error on camera open.'
        re_import()
        take_photo.take_photo()
        output = read_output_file(self.outfile)
        self.assertTrue('mock error' in output)
        self.assertTrue('could not connect' in output)

    @mock.patch('os.listdir', mock.Mock(side_effect=lambda _: ['video0']))
    @mock.patch('os.path.exists', mock.Mock())
    @mock.patch('cv2.VideoCapture', _prepare_mock_capture(raise_backend=True))
    def test_camera_get_backend_error(self):
        'Test error on get backend.'
        re_import()
        take_photo.take_photo()
        output = read_output_file(self.outfile)
        self.assertTrue('not available' in output)

    @mock.patch('os.listdir', mock.Mock(side_effect=lambda _: ['video0']))
    @mock.patch('os.path.exists', mock.Mock())
    @mock.patch('cv2.VideoCapture', _prepare_mock_capture(raise_read=True))
    def test_camera_read_error(self):
        'Test error on camera read.'
        re_import()
        take_photo.take_photo()
        output = read_output_file(self.outfile)
        self.assertTrue('mock error' in output)
        self.assertTrue('image capture error' in output)

    @mock.patch('os.listdir', mock.Mock(side_effect=lambda _: ['video0']))
    @mock.patch('os.path.exists', mock.Mock())
    @mock.patch('subprocess.check_output',
                mock.Mock(side_effect=_prepare_fuser_mock(missing=True)))
    @mock.patch('cv2.VideoCapture', _prepare_mock_capture())
    def test_camera_no_busy_check(self):
        'Test unable to check if camera is busy.'
        re_import()
        take_photo.take_photo()
        output = read_output_file(self.outfile)
        self.assertTrue('unable to check' in output)

    @mock.patch('os.listdir', mock.Mock(side_effect=lambda _: ['video0']))
    @mock.patch('os.path.exists', mock.Mock())
    @mock.patch('subprocess.check_output',
                mock.Mock(side_effect=_prepare_fuser_mock(busy=True)))
    @mock.patch('cv2.VideoCapture', _prepare_mock_capture())
    def test_camera_busy(self):
        'Test camera busy.'
        re_import()
        take_photo.take_photo()
        output = read_output_file(self.outfile)
        self.assertTrue('attempting to close' in output)

    @mock.patch('os.listdir', mock.Mock(side_effect=lambda _: ['video0']))
    @mock.patch('os.path.exists', mock.Mock())
    @mock.patch('cv2.VideoCapture', _prepare_mock_capture(isOpened=False))
    def test_camera_not_open(self):
        'Test camera not open.'
        re_import()
        take_photo.take_photo()
        output = read_output_file(self.outfile)
        self.assertTrue('could not connect' in output)

    @mock.patch('os.listdir', mock.Mock(side_effect=lambda _: ['video0']))
    @mock.patch('os.path.exists', mock.Mock())
    @mock.patch('cv2.VideoCapture',
                _prepare_mock_capture(read_return=(False, None)))
    def test_no_image(self):
        'Test no image.'
        re_import()
        take_photo.take_photo()
        output = read_output_file(self.outfile)
        self.assertTrue('no image' in output)

    @mock.patch('os.listdir', mock.Mock(side_effect=lambda _: ['video0']))
    @mock.patch('os.path.exists', mock.Mock())
    @mock.patch('cv2.VideoCapture', _prepare_mock_capture(grab_return=False))
    def test_no_grab_image(self):
        'Test no grab return.'
        re_import()
        take_photo.take_photo()
        output = read_output_file(self.outfile)
        self.assertTrue('could not get frame' in output)

    @mock.patch('os.listdir', mock.Mock(side_effect=lambda _: ['video0']))
    @mock.patch('os.path.exists', mock.Mock())
    @mock.patch('os.path.isdir', mock.Mock())
    @mock.patch('cv2.VideoCapture', _prepare_mock_capture())
    def test_rotated(self):
        'Test image rotation.'
        os.environ['CAMERA_CALIBRATION_total_rotation_angle'] = '45'
        re_import()
        take_photo.take_photo()
        output = read_output_file(self.outfile)
        self.assertTrue('rotated' in output)
        self.assertFalse('directory does not exist' in output)

    @mock.patch('os.listdir', mock.Mock(side_effect=lambda _: ['video0']))
    @mock.patch('os.path.exists', mock.Mock())
    @mock.patch('os.path.isdir', mock.Mock())
    @mock.patch('cv2.VideoCapture', _prepare_mock_capture())
    def test_large_rotation(self):
        'Test large image rotation.'
        os.environ['CAMERA_CALIBRATION_total_rotation_angle'] = '75'
        re_import()
        take_photo.take_photo()
        output = read_output_file(self.outfile)
        self.assertTrue('rotated' in output)
        self.assertFalse('directory does not exist' in output)

    def test_none_camera(self):
        'Test none camera selection.'
        os.environ['camera'] = 'none'
        re_import()
        take_photo.take_photo()
        output = read_output_file(self.outfile)
        self.assertTrue('no camera selected' in output)
        self.assertFalse('USB' in output)

    def test_rpi_camera(self):
        'Test rpi camera selection.'
        os.environ['camera'] = 'rpi'
        re_import()
        take_photo.take_photo()
        output = read_output_file(self.outfile)
        self.assertTrue('raspberry pi' in output)
        self.assertTrue('raspistill' in output)
        self.assertTrue('-w 640 -h 480' in output)
        self.assertFalse('-md 3' in output)
        self.assertFalse('USB' in output)

    def test_rpi_camera_small_size(self):
        'Test capture with rpi camera selection and small size inputs.'
        os.environ['camera'] = 'rpi'
        os.environ['take_photo_width'] = '200'
        os.environ['take_photo_height'] = '100'
        re_import()
        take_photo.take_photo()
        output = read_output_file(self.outfile)
        self.assertTrue('raspistill' in output)
        self.assertTrue('-w 200 -h 100' in output)
        self.assertFalse('-md 3' in output)

    def test_rpi_camera_large_size(self):
        'Test capture with rpi camera selection and large size inputs.'
        os.environ['camera'] = 'rpi'
        os.environ['take_photo_width'] = '2000'
        os.environ['take_photo_height'] = '2000'
        re_import()
        take_photo.take_photo()
        output = read_output_file(self.outfile)
        self.assertTrue('raspistill' in output)
        self.assertTrue('-md 3' in output)
        self.assertFalse('-w' in output)

    @mock.patch('cv2.imread', mock.Mock(side_effect=lambda _:
                                        np.zeros([10, 10, 3], np.uint8)))
    @mock.patch('os.remove', mock.Mock())
    @mock.patch('subprocess.call', mock.Mock(side_effect=lambda _: 0))
    def test_rpi_camera_capture(self):
        'Test rpi camera capture success.'
        os.environ['camera'] = 'rpi'
        re_import()
        take_photo.take_photo()
        output = read_output_file(self.outfile)
        self.assertTrue('raspberry pi' in output)
        self.assertTrue('image captured' in output)

    @mock.patch('subprocess.call', mock.Mock(side_effect=lambda _: 1))
    def test_rpi_camera_capture_failure(self):
        'Test rpi camera capture failure.'
        os.environ['camera'] = 'rpi'
        re_import()
        take_photo.take_photo()
        output = read_output_file(self.outfile)
        self.assertTrue('raspberry pi' in output)
        self.assertTrue('not detected' in output)

    @mock.patch('subprocess.call', mock.Mock(side_effect=lambda _: 0))
    def test_quick_rpi_camera(self):
        'Test quick capture with rpi camera selection.'
        os.environ['take_photo_disable_rotation_adjustment'] = '1'
        os.environ['camera'] = 'rpi'
        with self.assertRaises(SystemExit):
            re_import()
        output = read_output_file(self.outfile)
        self.assertTrue('raspistill' in output)
        self.assertFalse('fswebcam' in output)
        self.assertFalse('no camera selected' in output)

    @mock.patch('os.listdir', mock.Mock(side_effect=lambda _: ['video0']))
    @mock.patch('subprocess.call', mock.Mock(side_effect=lambda _: 0))
    def test_quick_usb_camera(self):
        'Test quick capture with usb camera selection.'
        os.environ['take_photo_disable_rotation_adjustment'] = '1'
        os.environ['camera'] = 'usb'
        with self.assertRaises(SystemExit):
            re_import()
        output = read_output_file(self.outfile)
        self.assertFalse('raspistill' in output)
        self.assertTrue('fswebcam' in output)
        self.assertFalse('no camera selected' in output)

    @mock.patch('os.listdir', mock.Mock(side_effect=lambda _: ['video0']))
    @mock.patch('subprocess.call', mock.Mock(side_effect=lambda _: 0))
    def test_quick_usb_camera_image_size(self):
        'Test quick capture with usb camera and image size selection.'
        os.environ['take_photo_disable_rotation_adjustment'] = '1'
        os.environ['take_photo_width'] = '200'
        os.environ['take_photo_height'] = '100'
        os.environ['camera'] = 'usb'
        with self.assertRaises(SystemExit):
            re_import()
        output = read_output_file(self.outfile)
        self.assertFalse('raspistill' in output)
        self.assertTrue('fswebcam' in output)
        self.assertTrue('200x100' in output)
        self.assertFalse('no camera selected' in output)

    @mock.patch('subprocess.call', mock.Mock(side_effect=lambda _: 0))
    def test_quick_usb_camera_missing_port(self):
        'Test quick capture with usb camera selection, video port missing.'
        os.environ['take_photo_disable_rotation_adjustment'] = '1'
        os.environ['camera'] = 'usb'
        with self.assertRaises(SystemExit):
            re_import()
        output = read_output_file(self.outfile)
        self.assertFalse('raspistill' in output)
        self.assertFalse('fswebcam' in output)
        self.assertFalse('no camera selected' in output)
        self.assertTrue('not detected' in output)

    def test_quick_none_camera(self):
        'Test quick capture with none camera selection.'
        os.environ['take_photo_disable_rotation_adjustment'] = '1'
        os.environ['camera'] = 'none'
        with self.assertRaises(SystemExit):
            re_import()
        output = read_output_file(self.outfile)
        self.assertFalse('raspistill' in output)
        self.assertFalse('fswebcam' in output)
        self.assertTrue('no camera selected' in output)

    @unittest.skipIf(sys.version_info[0] < 3, '')
    @mock.patch('socket.socket', _prepare_mock_socket())
    def test_quick_none_camera_with_log(self):
        'Test quick capture with none camera selection and log.'
        os.environ['FARMWARE_API_V2_REQUEST_PIPE'] = ''
        os.environ['FARMWARE_API_V2_RESPONSE_PIPE'] = ''
        os.environ['take_photo_disable_rotation_adjustment'] = '1'
        os.environ['camera'] = 'none'
        with self.assertRaises(SystemExit):
            re_import()
        output = read_output_file(self.outfile)
        self.assertFalse('raspistill' in output)
        self.assertFalse('fswebcam' in output)
        self.assertTrue('no camera selected' in output)

    def test_quick_none_camera_quiet(self):
        'Test quick capture with none camera selection: quiet.'
        os.environ['take_photo_disable_rotation_adjustment'] = '1'
        os.environ['camera'] = 'none'
        os.environ['take_photo_logging'] = 'quiet'
        with self.assertRaises(SystemExit):
            re_import()
        output = read_output_file(self.outfile)
        self.assertFalse('no camera selected' in output)

    @unittest.skipIf(CV2_IMPORTED, '')
    def test_opencv_missing(self):
        'Test for cv2 import error.'
        with self.assertRaises(SystemExit):
            re_import()
        output = read_output_file(self.outfile)
        self.assertTrue('import error' in output)

    def tearDown(self):
        self.outfile.close()
        sys.stdout = sys.__stdout__
        os.remove(OUTPUT_FILENAME)
