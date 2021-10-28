#!/usr/bin/env python
"""Plant Detection Image Capture.

For Plant Detection.
"""
import sys
import os
from time import time, sleep
from subprocess import call
import cv2
from plant_detection import ENV
from plant_detection.Log import log

CAMERA = (ENV.load('camera', get_json=False) or 'USB').upper()


class Capture(object):
    """Capture image for Plant Detection."""

    def __init__(self, directory=None):
        """Set initial attributes."""
        self.image = None
        self.ret = None
        self.camera_port = None
        self.image_captured = False
        self.silent = False
        self.directory = directory

    def camera_check(self):
        """Check for camera at ports 0 and 1."""
        if not os.path.exists('/dev/video' + str(self.camera_port)):
            if not self.silent:
                print('No camera detected at video{}.'.format(
                    self.camera_port))
            self.camera_port = 1
            if not self.silent:
                print('Trying video{}...'.format(self.camera_port))
            if not os.path.exists('/dev/video' + str(self.camera_port)):
                if not self.silent:
                    print('No camera detected at video{}.'.format(
                        self.camera_port))
                    log('USB Camera not detected.',
                        message_type='error', title='take-photo')

    def save(self, filename_only=False, add_timestamp=True):
        """Save captured image."""
        if self.directory is None:
            directory = os.path.dirname(os.path.realpath(__file__)) + os.sep
            try:
                testfilename = directory + 'test_write.try_to_write'
                testfile = open(testfilename, 'w')
                testfile.close()
                os.remove(testfilename)
            except IOError:
                directory = '/tmp/images/'
        else:
            directory = self.directory
        if add_timestamp:
            image_filename = directory + 'capture_{timestamp}.jpg'.format(
                timestamp=int(time()))
        else:
            image_filename = directory + 'capture.jpg'
        if not filename_only:
            cv2.imwrite(image_filename, self.image)
        return image_filename

    def exit(self):
        'Exit.'
        sys.exit(0)

    def capture(self):
        """Take a photo."""
        WIDTH = os.getenv('take_photo_width', '640')
        HEIGHT = os.getenv('take_photo_height', '480')
        if 'NONE' in CAMERA:
            log('No camera selected. Choose a camera on the device page.',
                message_type='error', title='take-photo')
            self.exit()
        elif 'RPI' in CAMERA:
            # With Raspberry Pi Camera:
            image_filename = self.save(filename_only=True)
            width = min(int(WIDTH), 4056)
            height = min(int(HEIGHT), 3040)
            size = ['-w', str(width), '-h', str(height)]
            if height > 1500:
                size = ['-md', '3']
            try:
                retcode = call(['raspistill'] + size + ['-o', image_filename])
            except OSError:
                log('Raspberry Pi Camera not detected.',
                    message_type='error', title='take-photo')
                self.exit()
            else:
                if retcode == 0:
                    print('Image saved: {}'.format(image_filename))
                    return image_filename
                else:
                    log('Problem getting image.',
                        message_type='error', title='take-photo')
                    self.exit()
        else:  # With USB camera:
            self.camera_port = 0
            image_width = int(WIDTH)
            image_height = int(HEIGHT)
            discard_frames = 20
            self.camera_check()  # check for camera
            camera = cv2.VideoCapture(self.camera_port)
            sleep(0.1)
            try:
                camera.set(cv2.CAP_PROP_FRAME_WIDTH, image_width)
                camera.set(cv2.CAP_PROP_FRAME_HEIGHT, image_height)
            except AttributeError:
                camera.set(cv2.cv.CV_CAP_PROP_FRAME_WIDTH, image_width)
                camera.set(cv2.cv.CV_CAP_PROP_FRAME_HEIGHT, image_height)
            for _ in range(discard_frames):
                camera.grab()
            self.ret, self.image = camera.read()
            camera.release()
            if not self.ret:
                log('Problem getting image.',
                    message_type='error', title='take-photo')
                self.exit()
            self.image_captured = True
            return self.save()


if __name__ == '__main__':
    Capture().capture()
