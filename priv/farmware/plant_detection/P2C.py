"""Image Pixel Location to Machine Coordinate Conversion."""

import sys
import os
import json
import numpy as np
from plant_detection.Parameters import Parameters
from plant_detection.Image import Image
from plant_detection.DB import DB
from plant_detection import ENV
from plant_detection.Log import log


class Pixel2coord(object):
    """Image pixel to machine coordinate conversion.

    Calibrates the conversion of pixel locations to machine coordinates
    in images. Finds object coordinates in image.
    """

    def __init__(self, plant_db,
                 calibration_image=None,
                 calibration_data=None, load_data_from=None):
        """Set initial attributes.

        Arguments:
            Database() instance

        Optional Keyword Arguments:
            calibration_image (str): filename (default: None)
            calibration_data: P2C().calibration_params JSON,
                              or 'file' or 'env_var' string
                              (default: None)
        """
        self.dir = os.path.dirname(os.path.realpath(__file__)) + os.sep
        self.parameters_file = "plant-detection_calibration_parameters.json"

        self.calibration_params = {}
        self.debug = False
        self.env_var_name = 'PLANT_DETECTION_calibration'
        self.plant_db = plant_db
        self.defaults = Parameters().cdefaults

        # Data and parameter preparation
        self.cparams = Parameters()
        self._calibration_data_preparation(calibration_data, load_data_from)
        # Image preparation
        self.image = None
        self._calibration_image_preparation(calibration_image)

        self.rotationangle = 0
        self.test_rotation = 5  # for testing, add some image rotation
        self.viewoutputimage = False  # overridden as True if running script
        self.json_calibration_data = None

    def _calibration_data_preparation(self, calibration_data=None,
                                      load_data_from=None):
        for key, value in self.defaults.items():
            if key in self.cparams.defaults:
                self.cparams.defaults[key] = value
        if calibration_data is not None:
            self.calibration_params = calibration_data
        elif load_data_from == 'file':
            # self._load_parameters(self.load_calibration_parameters,
            #                       IOError)
            self._load_inputs(self.cparams.load, IOError)
            self._additional_calibration_inputs(
                self.load_calibration_parameters, IOError)
            self.initialize_data_keys()
        elif load_data_from == 'env_var':
            # Method 1
            # self._load_parameters(self.load_calibration_data_from_env,
            #                       ValueError)
            # Method 2
            # self._load_inputs(
            #     self.cparams.load_env_var, ValueError)
            # self._additional_calibration_inputs(
            #     self.load_calibration_data_from_env, ValueError)
            # self.initialize_data_keys()
            # Method 3
            self.cparams.load_env_var('calibration')
            self.calibration_params = self.cparams.parameters.copy()
        else:  # load defaults
            self.calibration_params = self.defaults

        if not self.calibration_params['easy_calibration']:
            self.set_calibration_input_params()

    def _load_inputs(self, get_inputs, error):
        # load only image processing input parameters
        try:
            message = get_inputs()  # Parameters object
            if message != "":
                raise error("Load Failed.")
        except error:
            print("Warning: Input parameter load failed. "
                  "Using Defaults.")
            self.calibration_params = self.cparams.defaults.copy()
        else:
            self.calibration_params = self.cparams.parameters.copy()

    def _load_parameters(self, get_parameters, error):
        # load all parameters necessary for calibration / coordinate conversion
        try:
            get_parameters()
        except error:
            print("Warning: Calibration data load failed. "
                  "Using defaults.")
            self.calibration_params = self.defaults

    def _additional_calibration_inputs(self, get_additional, error):
        # load extra inputs needed (when using _load_inputs only)
        temp_inputs = self.calibration_params
        self.calibration_params = {}
        try:
            get_additional()
        except error:  # no additional calibration inputs to add
            self.calibration_params = temp_inputs
        else:  # add additional calibration inputs
            for key, value in self.calibration_params.items():
                if key not in temp_inputs:
                    temp_inputs[key] = value
            self.calibration_params = temp_inputs

    @staticmethod
    def get_image_center(image):
        """Return the pixel location (X, Y) of the image center."""
        return [int(a / 2) for a in image.shape[:2][::-1]]

    def _calibration_image_preparation(self, calibration_image):
        if calibration_image is not None:
            self.image = Image(self.cparams, self.plant_db)
            if isinstance(calibration_image, int):
                try:
                    self.image.download(calibration_image)
                except IOError:
                    print("Image download failed for image ID {}.".format(
                        str(calibration_image)))
                    sys.exit(0)
            else:
                self.image.load(calibration_image)
            self.calibration_params[
                'center_pixel_location'] = self.get_image_center(
                    self.image.images['current'])
            self.image.calibration_debug = self.debug

    def save_calibration_parameters(self):
        """Save calibration parameters to file."""
        if self.plant_db.tmp_dir is None:
            directory = self.dir
        else:
            directory = self.plant_db.tmp_dir
        with open(directory + self.parameters_file, 'w') as oututfile:
            json.dump(self.calibration_params, oututfile)

    def save_calibration_data_to_env(self):
        """Save calibration parameters to environment variable."""
        self.json_calibration_data = self.calibration_params
        self.cparams.parameters = self.calibration_params
        self.cparams.save_to_env_var('calibration')

    def load_calibration_data_from_env(self):
        """Load calibration parameters from environment variable."""
        self.calibration_params = ENV.load(self.env_var_name)
        if self.calibration_params is None:
            raise ValueError("ENV load failed.")

    def initialize_data_keys(self):
        """If using JSON with inputs only, create calibration data keys."""
        def _check_for_key(key):
            try:
                self.calibration_params[key]
            except KeyError:
                self.calibration_params[key] = self.defaults[key]
        calibration_keys = ['calibration_circles_xaxis',
                            'easy_calibration',
                            'image_bot_origin_location',
                            'calibration_circle_separation',
                            'camera_offset_coordinates',
                            'calibration_iters']
        for key in calibration_keys:
            _check_for_key(key)

    def set_calibration_input_params(self):
        """Set input parameters from calibration parameters."""
        self.cparams.parameters['blur'] = self.calibration_params['blur']
        self.cparams.parameters['morph'] = self.calibration_params['morph']
        self.cparams.parameters['H'] = self.calibration_params['H']
        self.cparams.parameters['S'] = self.calibration_params['S']
        self.cparams.parameters['V'] = self.calibration_params['V']

    def load_calibration_parameters(self):
        """Load calibration parameters from file or use defaults."""
        def _load(directory):  # Load calibration parameters from file
            with open(directory + self.parameters_file, 'r') as inputfile:
                self.calibration_params = json.load(inputfile)
        try:
            _load(self.dir)
        except IOError:
            self.plant_db.tmp_dir = "/tmp/"
            _load(self.plant_db.tmp_dir)

    def validate_calibration_data(self, check_image):
        """Check that calibration parameters can be applied to the image."""
        # Prepare data
        image_center = self.get_image_center(check_image)
        image_center = self._block_rotations(
            self.calibration_params['total_rotation_angle'], cpl=image_center)
        image_location = self.plant_db.coordinates
        camera_dz = abs(
            self.calibration_params['camera_z'] - image_location[2])
        center_deltas = [abs(calibration - current) for calibration, current in
                         zip(self.calibration_params['center_pixel_location'],
                             image_center)]
        # Check data
        check_status = True
        if camera_dz > 5:
            check_status = False  # set True to try camera height compensation
        for center_delta in center_deltas:
            if center_delta > 5:
                check_status = False
        return check_status

    def _block_rotations(self, angle, cpl=None):
        def _determine_turns(angle):  # number of 90 degree rotations
            turns = -int(angle / 90.)
            remain = abs(angle) % 90
            if angle < 0:
                remain = -remain
            if remain > 45:
                turns -= 1
            if remain < -45:
                turns += 1
            return turns

        def _origin_rot(horiz, vert):  # rotate image origin with image
            if cpl is None:
                # get image origin
                origin = self.calibration_params['image_bot_origin_location']
                # rotate image origin
                if origin[0] == origin[1]:
                    origin[vert] = int(not origin[vert])
                else:
                    origin[horiz] = int(not origin[horiz])
                # set image origin
                self.calibration_params['image_bot_origin_location'] = origin
            # swap image center pixel horiz/vert
            if cpl is None:
                center = self.calibration_params['center_pixel_location']
            else:
                center = cpl
            center = center[::-1]
            self.calibration_params['center_pixel_location'] = center
            return center

        turns = _determine_turns(angle)
        if turns > 0:
            cpl = _origin_rot(0, 1)
        if turns < 0:
            cpl = _origin_rot(1, 0)
        return cpl

    def rotationdetermination(self):
        """Determine angle of rotation if necessary."""
        threshold = 0
        along_x = self.calibration_params['calibration_circles_xaxis']
        [[cdx, cdy]] = np.diff(
            self.plant_db.calibration_pixel_locations[:2, :2], axis=0)
        if cdx == 0:
            trig = None
        else:
            trig = cdy / cdx
        difference = abs(cdy)
        if not along_x:
            if cdy == 0:
                trig = None
            else:
                trig = cdx / cdy
            difference = abs(cdx)
        if difference > threshold:
            if trig is None:
                self.rotationangle = 90
            else:
                rotation_angle_radians = np.arctan(trig)
                self.rotationangle = 180. / np.pi * rotation_angle_radians
                if abs(cdy) > abs(cdx) and along_x:
                    self.rotationangle = -self.rotationangle
                if abs(cdx) > abs(cdy) and not along_x:
                    self.rotationangle = -self.rotationangle
            self._block_rotations(self.rotationangle)
        else:
            self.rotationangle = 0

    def determine_scale(self):
        """Determine coordinate conversion scale."""
        if len(self.plant_db.calibration_pixel_locations) > 1:
            calibration_circle_sep = float(
                self.calibration_params['calibration_circle_separation'])
            object_sep = max(abs(np.diff(
                self.plant_db.calibration_pixel_locations[:2, :2], axis=0)[0]))
            self.calibration_params['coord_scale'] = round(
                calibration_circle_sep / object_sep, 4)

    def c2p(self, plant_db):
        """Convert coordinates to pixel locations using image center."""
        plant_db.pixel_locations = self.convert(
            plant_db.coordinate_locations, to_='pixels')

    def p2c(self, plant_db):
        """Convert pixel locations to machine coordinates from image center."""
        plant_db.coordinate_locations = self.convert(
            plant_db.pixel_locations, to_='coordinates')

    def plant_dict_to_pixel_array(self, plant_dict, extend_radius=0):
        """Convert a plant coordinate dictionary to a pixel array."""
        pixel_array = np.array(self.convert(
            [plant_dict['x'], plant_dict['y'],
             plant_dict['radius'] + extend_radius],
            to_='pixels'))[0]
        return pixel_array

    def convert(self, input_, to_=None):
        """Convert between image pixels and bot coordinates."""
        # Check and manage input
        if to_ is None:
            raise TypeError("Conversion direction not provided.")
        input_ = np.array(input_)
        if len(input_) == 0:
            output_ = []
            return output_
        try:
            input_.shape[1]
        except IndexError:
            input_ = np.vstack([input_])
        # Get conversion parameters
        bot_location = np.array(self.plant_db.coordinates[:2], dtype=float)
        current_z = self.plant_db.coordinates[2]
        camera_offset = np.array(
            self.calibration_params['camera_offset_coordinates'], dtype=float)
        camera_coordinates = bot_location + camera_offset  # img center coord
        center_pixel_location = self.calibration_params[
            'center_pixel_location'][:2]
        sign = [1 if s == 1 else -1 for s
                in self.calibration_params['image_bot_origin_location']]
        coord_scale = np.repeat(self.calibration_params['coord_scale'], 2)
        # Adjust scale factor for camera height
        calibration_z = self.calibration_params['camera_z']
        camera_dz = current_z - calibration_z
        coord_scale = coord_scale + camera_dz / 157.3
        # Convert
        output_ = []
        for obj_num, obj_loc in enumerate(input_[:, :2]):
            if to_ == 'pixels':
                radius = input_[obj_num][2]
                result = (
                    center_pixel_location -
                    ((obj_loc - camera_coordinates) / (sign * coord_scale)))
                output_.append([result[0], result[1], radius / coord_scale[0]])
            if to_ == 'coordinates':
                radius = input_[:][obj_num][2]
                result = (
                    camera_coordinates +
                    sign * coord_scale * (center_pixel_location - obj_loc))
                output_.append([result[0], result[1], coord_scale[0] * radius])
        return output_

    def calibration(self):
        """Determine pixel to coordinate scale and image rotation angle."""
        total_rotation_angle = 0
        warning_issued = False
        if self.debug:
            self.cparams.print_input()
        if self.calibration_params['easy_calibration']:
            from plant_detection.PatternCalibration import PatternCalibration
            pattern_calibration = PatternCalibration(self.calibration_params)
            result_flag = pattern_calibration.move_and_capture()
            if not result_flag:
                fail_flag = True
                return fail_flag
            result_flag = pattern_calibration.calibrate()
            if not result_flag:
                fail_flag = True
                return fail_flag
            self.plant_db.getcoordinates()
            self.image.images['marked'] = pattern_calibration.output_img
            self.image.grid(self)
            fail_flag = False
            return fail_flag
        for i in range(0, self.calibration_params['calibration_iters']):
            self.image.initial_processing()
            self.image.find(calibration=True)  # find objects
            # If not the last iteration, determine camera rotation angle
            if i != (self.calibration_params['calibration_iters'] - 1):
                # Check number of objects detected and notify user if needed.
                if len(self.plant_db.calibration_pixel_locations) == 0:
                    log("ERROR: Calibration failed. No objects detected.",
                        message_type='error', title='camera-calibration')
                    return True
                if self.plant_db.object_count > 2:
                    if not warning_issued:
                        log(" Warning: {} objects detected. "
                            "Exactly 2 recommended. "
                            "Incorrect results possible. Check output.".format(
                                self.plant_db.object_count),
                            message_type='warn', title='camera-calibration')
                        warning_issued = True
                if self.plant_db.object_count < 2:
                    log(" ERROR: {} objects detected. "
                        "At least 2 required. Exactly 2 recommended.".format(
                            self.plant_db.object_count),
                        message_type='error', title='camera-calibration')
                    return True
                # Use detected objects to determine required rotation angle
                self.rotationdetermination()
                if abs(self.rotationangle) > 120:
                    log(" ERROR: Excessive rotation required. "
                        "Check that the calibration objects are "
                        "parallel with the desired axis and that "
                        "they are the only two objects detected.",
                        message_type='error', title='camera-calibration')
                    return True
                self.image.rotate_main_images(self.rotationangle)
                total_rotation_angle += self.rotationangle
        self.determine_scale()
        fail_flag = self._calibration_output(total_rotation_angle)
        return fail_flag

    def _calibration_output(self, total_rotation_angle):
        if self.viewoutputimage:
            self.image.images['current'] = self.image.images['marked']
            self.image.show()
        while abs(total_rotation_angle) > 360:
            if total_rotation_angle < 0:
                total_rotation_angle += 360
            else:
                total_rotation_angle -= 360
        self.calibration_params['total_rotation_angle'] = round(
            total_rotation_angle, 2)
        self.calibration_params['camera_z'] = self.plant_db.coordinates[2]
        try:
            self.calibration_params['coord_scale']  # pylint:disable=W0104
            failure_flag = False
        except KeyError:
            log("ERROR: Calibration failed.",
                message_type='error', title='camera-calibration')
            failure_flag = True
        return failure_flag

    def determine_coordinates(self):
        """Use calibration parameters to determine locations of objects."""
        self.image.rotate_main_images(
            self.calibration_params['total_rotation_angle'])
        if self.debug:
            self.cparams.print_input()
        self.image.initial_processing()
        self.image.find(calibration=True)
        self.plant_db.print_count(calibration=True)  # print detected obj count
        self.p2c(self.plant_db)
        self.plant_db.print_coordinates()
        if self.viewoutputimage:
            self.image.grid(self)
            self.image.images['current'] = self.image.images['marked']
            self.image.show()
        return self.plant_db.get_json_coordinates()


if __name__ == "__main__":
    DIR = os.path.dirname(os.path.realpath(__file__)) + os.sep
    print("Calibration image load...")
    P2C = Pixel2coord(DB(), calibration_image=DIR +
                      "p2c_test_calibration.jpg")
    P2C.viewoutputimage = True
    # Calibration
    P2C.image.rotate_main_images(P2C.test_rotation)
    EXIT = P2C.calibration()
    if EXIT:
        sys.exit(0)
    P2C.plant_db.print_count(calibration=True)  # print detected object count
    if P2C.calibration_params['total_rotation_angle'] != 0:
        print(" Note: required rotation executed = {:.2f} degrees".format(
            P2C.calibration_params['total_rotation_angle']))
    # Tests
    # Object detection
    print("Calibration object test...")
    P2C.image.load(DIR + "p2c_test_objects.jpg")
    P2C.image.rotate_main_images(P2C.test_rotation)
    P2C.determine_coordinates()
    # Color range
    print("Calibration color range...")
    P2C.image.load(DIR + "p2c_test_color.jpg")
    P2C.cparams.print_input()
    P2C.image.initial_processing()
    P2C.image.find()
    if P2C.viewoutputimage:
        P2C.image.images['current'] = P2C.image.images['marked']
        P2C.image.show()
