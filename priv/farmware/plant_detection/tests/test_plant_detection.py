#!/usr/bin/env python
"""Plant Detection Tests

For Plant Detection.
"""
import os
import sys
import json
import unittest
import numpy as np
from plant_detection.PlantDetection import PlantDetection
try:
    import farmware_tools
    USING_FT = True
except ImportError:
    USING_FT = False


def assert_dict_values_almost_equal(assertE, assertAE, object1, object2):
    def shape(objects):
        if isinstance(objects, dict):
            formatted_objects = objects
        else:
            formatted_objects = {}
            formatted_objects['remove'] = objects
        return formatted_objects
    f_object1 = shape(object1)
    f_object2 = shape(object2)
    keys1 = f_object1.keys()
    keys2 = f_object2.keys()
    assertE(keys1, keys2)
    for key in keys1:
        dicts1 = f_object1[key]
        dicts2 = f_object2[key]
        assertE(len(dicts1), len(dicts2),
                msg='\n{}\nlength not equal to\n{}'.format(
                    json.dumps(dicts1), json.dumps(dicts2)))
        for dict1, dict2 in zip(dicts1, dicts2):
            assertAE(dict1['x'], dict2['x'], delta=5)
            assertAE(dict1['y'], dict2['y'], delta=5)
            assertAE(dict1['radius'], dict2['radius'], delta=5)


def subset(dictionary, keylist):
    dict_excerpt = {key: dictionary[key] for key in keylist}
    return dict_excerpt


def compare_calibration_results(self):
    self.assertAlmostEqual(self.calibration['total_rotation_angle'],
                           self.pd.p2c.calibration_params[
                               'total_rotation_angle'], places=1)
    self.assertAlmostEqual(self.calibration['coord_scale'],
                           self.pd.p2c.calibration_params[
                               'coord_scale'], places=3)
    self.assertEqual(self.calibration['center_pixel_location'],
                     self.pd.p2c.calibration_params['center_pixel_location'])


def check_file_length(self, expected_length):
    self.outfile.close()
    self.outfile = open('text_output_test.txt', 'r')
    self.assertEqual(sum(1 for line in self.outfile), expected_length)


def get_average_pixel_value(image):
    pixel_mean = round(np.mean(image), 1)
    return pixel_mean


class PDTestJSONinput(unittest.TestCase):
    """Test ENV VAR inputs"""

    def setUp(self):
        os.environ.clear()
        self.data = {
            'WEED_DETECTOR_blur': 15,
            'WEED_DETECTOR_morph': 6,
            'WEED_DETECTOR_iteration': 4,
            'WEED_DETECTOR_H_HI': 90,
            'WEED_DETECTOR_H_LO': 30,
            'WEED_DETECTOR_S_HI': 255,
            'WEED_DETECTOR_S_LO': 20,
            'WEED_DETECTOR_V_HI': 255,
            'WEED_DETECTOR_V_LO': 20,
            'WEED_DETECTOR_save_detected_plants': '"TRUE"',
        }
        for key, value in self.data.items():
            os.environ[key] = str(value)
        self.input_params = {
            'blur': self.data['WEED_DETECTOR_blur'],
            'morph': self.data['WEED_DETECTOR_morph'],
            'iterations': self.data['WEED_DETECTOR_iteration'],
            'H': [self.data['WEED_DETECTOR_H_LO'], self.data['WEED_DETECTOR_H_HI']],
            'S': [self.data['WEED_DETECTOR_S_LO'], self.data['WEED_DETECTOR_S_HI']],
            'V': [self.data['WEED_DETECTOR_V_LO'], self.data['WEED_DETECTOR_V_HI']],
            'save_detected_plants': True}
        self.pd = PlantDetection(image='plant_detection/soil_image.jpg',
                                 from_env_var=True,
                                 text_output=False, save=False)
        # os.environ["PLANT_DETECTION_options"] = json.dumps(self.input_params)
        self.pd.detect_plants()

    def test_json_parameters_input(self):
        """Load JSON input parameters from ENV VAR"""
        self.assertEqual(self.pd.params.parameters, self.input_params)

    def tearDown(self):
        os.environ.clear()


class PDTestNoJSONinput(unittest.TestCase):
    """Test defaults"""

    def setUp(self):
        self.parameters = {'blur': 5, 'morph': 5, 'iterations': 1,
                           'H': [30, 90], 'S': [20, 255], 'V': [20, 255]}
        self.pd = PlantDetection(
            image='plant_detection/soil_image.jpg', text_output=False, save=False)
        self.pd.detect_plants()

    def test_json_parameters_input(self):
        """Do not load JSON input parameters from ENV VAR"""
        self.assertEqual(self.pd.plant_db.plants['known'], [])
        self.assertEqual(self.pd.params.parameters, self.parameters)


class PDTestCalibration(unittest.TestCase):
    """Test calibration process"""

    def setUp(self):
        self.calibration_json = {"blur": 5, "morph": 15, "calibration_iters": 3,
                                 "H": [160, 20], "S": [100, 255], "V": [100, 255],
                                 "easy_calibration": False,
                                 "calibration_circles_xaxis": True,
                                 "camera_offset_coordinates": [200, 100],
                                 "image_bot_origin_location": [0, 1],
                                 "calibration_circle_separation": 1000,
                                 "invert_hue_selection": True}
        self.pd = PlantDetection(image="plant_detection/p2c_test_objects.jpg",
                                 calibration_img="plant_detection/p2c_test_calibration.jpg",
                                 calibration_data=self.calibration_json,
                                 HSV_min=[160, 100, 100], HSV_max=[20, 255, 255],
                                 morph=15, blur=5, text_output=False, save=False)
        self.pd.calibrate()
        self.calibration_json.update({
            "total_rotation_angle": 0.0,
            "coord_scale": 1.7182,
            "center_pixel_location": [465, 290]})
        self.objects = [{'y': 300.69, 'x': 300.0, 'radius': 46.86},
                        {'y': 599.66, 'x': 897.94, 'radius': 46.86},
                        {'y': 800.68, 'x': 98.97, 'radius': 47.53}]

    def test_calibration_inputs(self):
        """Check calibration input parameters"""
        calibration_input_keys = ["blur", "morph", "calibration_iters",
                                  "H", "S", "V",
                                  "easy_calibration",
                                  "calibration_circles_xaxis",
                                  "camera_offset_coordinates",
                                  "image_bot_origin_location",
                                  "calibration_circle_separation"]
        self.assertEqual(
            subset(self.calibration_json, calibration_input_keys),
            subset(self.pd.p2c.calibration_params, calibration_input_keys))

    def test_calibration_results(self):
        """Check calibration results"""
        calibration_results_keys = ["total_rotation_angle",
                                    "coord_scale",
                                    "center_pixel_location"]
        static_results = subset(self.calibration_json,
                                calibration_results_keys)
        test_results = subset(self.pd.p2c.calibration_params,
                              calibration_results_keys)
        self.assertAlmostEqual(static_results['total_rotation_angle'],
                               test_results['total_rotation_angle'], places=1)
        self.assertAlmostEqual(static_results['coord_scale'],
                               test_results['coord_scale'], places=3)
        self.assertEqual(static_results['center_pixel_location'],
                         test_results['center_pixel_location'])

    def test_object_coordinate_detection(self):
        """Determine coordinates of test objects"""
        self.pd.detect_plants()
        assert_dict_values_almost_equal(
            self.assertEqual,
            self.assertAlmostEqual,
            self.pd.plant_db.plants['remove'],
            self.objects)


class PDTestArgs(unittest.TestCase):
    """Test plant detection input arguments"""

    def setUp(self):
        self.default_input_params = {'blur': 5, 'morph': 5, 'iterations': 1,
                                     'H': [30, 90], 'S': [20, 255], 'V': [20, 255]}
        self.set_input_params = {'blur': 9, 'morph': 7, 'iterations': 3,
                                 'H': [15, 85], 'S': [15, 245], 'V': [15, 245]}
        self.default_func_args = {
            'image': None,
            'coordinates': False,
            'calibration_img': None,
            'calibration_data': None,
            'known_plants': None,
            'blur': self.default_input_params['blur'],
            'morph': self.default_input_params['morph'],
            'iterations': self.default_input_params['iterations'],
            'array': None,
            'debug': False, 'save': True, 'clump_buster': False,
            'HSV_min': [self.default_input_params['H'][0],
                        self.default_input_params['S'][0],
                        self.default_input_params['V'][0]],
            'HSV_max': [self.default_input_params['H'][1],
                        self.default_input_params['S'][1],
                        self.default_input_params['V'][1]],
            'from_file': False, 'from_env_var': False,
            'text_output': True, 'verbose': True,
            'print_all_json': False,
            'output_celeryscript_points': False,
            'grey_out': False,
            'draw_contours': True, 'circle_plants': True,
            'GUI': False, 'app': False, 'app_image_id': None
        }
        self.func_args = {}
        for key, value in self.default_func_args.items():
            if isinstance(value, bool):
                self.func_args[key] = not value
            if any(key == _key for _key in ['blur', 'morph', 'iterations']):
                self.func_args[key] = self.set_input_params[key]
        self.func_args['image'] = 'plant_detection/soil_image.jpg'
        self.func_args[
            'calibration_img'] = 'plant_detection/p2c_test_calibration.jpg'
        self.func_args['calibration_data'] = {}
        self.func_args['app_image_id'] = 1
        self.func_args['known_plants'] = [
            {'x': 200, 'y': 600, 'radius': 100},
            {'x': 900, 'y': 200, 'radius': 120}]
        self.func_args['array'] = [
            {"size": 5, "kernel": 'ellipse', "type": 'erode', "iters": 2},
            {"size": 3, "kernel": 'ellipse', "type": 'dilate', "iters": 8}]
        self.func_args['HSV_min'] = [
            self.set_input_params['H'][0],
            self.set_input_params['S'][0],
            self.set_input_params['V'][0]]
        self.func_args['HSV_max'] = [
            self.set_input_params['H'][1],
            self.set_input_params['S'][1],
            self.set_input_params['V'][1]]

    def test_input_args(self):
        """Set all arguments"""
        self.maxDiff = None
        pd = PlantDetection(**self.func_args)
        self.assertEqual(pd.args, self.func_args)
        self.assertEqual(pd.plant_db.plants['known'],
                         self.func_args['known_plants'])
        self.assertEqual(pd.params.parameters, self.set_input_params)
        self.assertEqual(pd.params.array, self.func_args['array'])

    def test_input_defaults(self):
        """Use defaults"""
        pd = PlantDetection()
        self.assertEqual(pd.args, self.default_func_args)
        self.assertEqual(pd.plant_db.plants['known'], [])
        self.assertEqual(pd.params.parameters, self.default_input_params)
        self.assertEqual(pd.params.array, None)


class PDTestOutput(unittest.TestCase):
    """Test plant detection results"""

    def setUp(self):
        # self.maxDiff = None
        self.calibration = {'blur': 5, 'morph': 15, 'calibration_iters': 3,
                            'H': [160, 20], 'S': [100, 255], 'V': [100, 255],
                            'easy_calibration': False,
                            'calibration_circles_xaxis': True,
                            'camera_offset_coordinates': [200, 100],
                            'image_bot_origin_location': [0, 1],
                            'calibration_circle_separation': 1000}
        self.pd = PlantDetection(image="plant_detection/soil_image.jpg",
                                 calibration_img="plant_detection/p2c_test_calibration.jpg",
                                 calibration_data=self.calibration,
                                 known_plants=[{'x': 200, 'y': 600, 'radius': 100},
                                               {'x': 900, 'y': 200, 'radius': 120}],
                                 blur=15, morph=6, iterations=4,
                                 text_output=False, save=False)
        self.pd.calibrate()
        self.pd.detect_plants()
        self.input_params = {'blur': 15, 'morph': 6, 'iterations': 4,
                             'H': [30, 90], 'S': [20, 255], 'V': [20, 255]}
        self.calibration.update({'total_rotation_angle': 0.0,
                                 'coord_scale': 1.7182,
                                 'center_pixel_location': [465, 290]})
        self.object_count = 16
        self.plants = {
            'known': [{'y': 600, 'x': 200, 'radius': 100},
                      {'y': 200, 'x': 900, 'radius': 120}],
            'save': [{'y': 189.01, 'x': 901.37, 'radius': 65.32},
                     {'y': 579.04, 'x': 236.43, 'radius': 91.23}],
            'safe_remove': [{'y': 85.91, 'x': 837.8, 'radius': 80.52}],
            'remove': [{'y': 41.24, 'x': 1428.86, 'radius': 73.59},
                       {'y': 42.96, 'x': 607.56, 'radius': 82.26},
                       {'y': 103.1, 'x': 1260.48, 'radius': 3.44},
                       {'y': 152.92, 'x': 1214.09, 'radius': 62.0},
                       {'y': 216.5, 'x': 1373.88, 'radius': 13.82},
                       {'y': 231.96, 'x': 1286.25, 'radius': 61.8},
                       {'y': 285.23, 'x': 1368.72, 'radius': 14.4},
                       {'y': 412.37, 'x': 1038.83, 'radius': 73.97},
                       {'y': 479.38, 'x': 1531.95, 'radius': 80.96},
                       {'y': 500.0, 'x': 765.64, 'radius': 80.02},
                       {'y': 608.25, 'x': 1308.59, 'radius': 148.73},
                       {'y': 676.97, 'x': 59.46, 'radius': 60.95},
                       {'y': 914.09, 'x': 62.89, 'radius': 82.37},
                       {'y': 84.2, 'x': 772.51, 'radius': 20.06}]
        }

    def test_output(self):
        """Check detect plants results"""
        # self.maxDiff = None
        # self.assertEqual(self.pd.plant_db.plants, self.plants)
        assert_dict_values_almost_equal(
            self.assertEqual,
            self.assertAlmostEqual,
            self.pd.plant_db.plants,
            self.plants)
        self.assertEqual(self.pd.params.parameters, self.input_params)
        compare_calibration_results(self)

    def test_object_count(self):
        """Check for correct object count"""
        self.assertEqual(self.pd.plant_db.object_count, self.object_count)


class ENV_VAR(unittest.TestCase):
    """Test environment variable use"""

    def setUp(self):
        os.environ.clear()
        self.data = {
            'WEED_DETECTOR_blur': 15,
            'WEED_DETECTOR_morph': 6,
            'WEED_DETECTOR_iteration': 4,
            'WEED_DETECTOR_H_HI': 90,
            'WEED_DETECTOR_H_LO': 30,
            'WEED_DETECTOR_S_HI': 255,
            'WEED_DETECTOR_S_LO': 20,
            'WEED_DETECTOR_V_HI': 255,
            'WEED_DETECTOR_V_LO': 20,
            'WEED_DETECTOR_save_detected_plants': '"TRUE"',
            'CAMERA_CALIBRATION_blur': 5,
            'CAMERA_CALIBRATION_morph': 15,
            'CAMERA_CALIBRATION_iteration': 4,
            'CAMERA_CALIBRATION_H_HI': 20,
            'CAMERA_CALIBRATION_H_LO': 160,
            'CAMERA_CALIBRATION_S_HI': 255,
            'CAMERA_CALIBRATION_S_LO': 100,
            'CAMERA_CALIBRATION_V_HI': 255,
            'CAMERA_CALIBRATION_V_LO': 100,
            'CAMERA_CALIBRATION_invert_hue_selection': 'TRUE',
            'CAMERA_CALIBRATION_image_bot_origin_location': 'TOP_LEFT',
            'CAMERA_CALIBRATION_camera_offset_y': 0,
            'CAMERA_CALIBRATION_camera_offset_x': 0,
            'CAMERA_CALIBRATION_calibration_object_separation': 1000,
            'CAMERA_CALIBRATION_calibration_along_axis': 'X',
            # 'CAMERA_CALIBRATION_total_rotation_angle': 0,
            # 'CAMERA_CALIBRATION_coord_scale': 0,
            # 'CAMERA_CALIBRATION_camera_z': 0,
            # 'CAMERA_CALIBRATION_center_pixel_location_x': 0,
            # 'CAMERA_CALIBRATION_center_pixel_location_y': 0
        }
        for key, value in self.data.items():
            os.environ[key] = str(value)
        self.input_params = {
            'blur': self.data['WEED_DETECTOR_blur'],
            'morph': self.data['WEED_DETECTOR_morph'],
            'iterations': self.data['WEED_DETECTOR_iteration'],
            'H': [self.data['WEED_DETECTOR_H_LO'], self.data['WEED_DETECTOR_H_HI']],
            'S': [self.data['WEED_DETECTOR_S_LO'], self.data['WEED_DETECTOR_S_HI']],
            'V': [self.data['WEED_DETECTOR_V_LO'], self.data['WEED_DETECTOR_V_HI']],
            'save_detected_plants': True}
        self.input_plants = {'plants': [{'y': 600, 'x': 200, 'radius': 100},
                                        {'y': 200, 'x': 900, 'radius': 120}]}
        self.calibration_input_params = {
            'blur': self.data['CAMERA_CALIBRATION_blur'],
            'morph': self.data['CAMERA_CALIBRATION_morph'],
            'iterations': self.data['CAMERA_CALIBRATION_iteration'],
            'H': [self.data['CAMERA_CALIBRATION_H_LO'], self.data['CAMERA_CALIBRATION_H_HI']],
            'S': [self.data['CAMERA_CALIBRATION_S_LO'], self.data['CAMERA_CALIBRATION_S_HI']],
            'V': [self.data['CAMERA_CALIBRATION_V_LO'], self.data['CAMERA_CALIBRATION_V_HI']]}
        self.calibration = {'total_rotation_angle': 0.0,
                            'coord_scale': 1.7182,
                            'center_pixel_location': [465, 290]}

    def test_set_inputs(self):
        """Set input environment variable"""
        pd = PlantDetection(image="plant_detection/soil_image.jpg",
                            from_env_var=True,
                            text_output=False, save=False)
        pd.detect_plants()
        self.assertEqual(pd.params.parameters,
                         self.input_params)

    def test_calibration_ENV_VAR(self):
        """Use calibration data environment variable"""
        self.pd = PlantDetection(calibration_img="plant_detection/p2c_test_calibration.jpg",
                                 from_env_var=True,
                                 text_output=False, save=False)
        self.pd.calibrate()
        compare_calibration_results(self)

        pd = PlantDetection(image="plant_detection/soil_image.jpg",
                            from_env_var=True, coordinates=True,
                            text_output=False, save=False)
        pd.detect_plants()

    def tearDown(self):
        os.environ.clear()


class TestFromFile(unittest.TestCase):
    """Test file use"""

    def setUp(self):
        self.outfile = open('text_output_test.txt', 'w')
        sys.stdout = self.outfile
        # Generate and save calibration data
        self.pd = PlantDetection(
            calibration_img="plant_detection/p2c_test_calibration.jpg",
            text_output=False, save=False)
        self.pd.calibrate()
        self.pd.p2c.save_calibration_parameters()
        # Expected number of objects detected
        self.object_count = 16

    def test_detect_coordinates(self):
        """Detect coordinates, getting calibration parameters from file"""
        # Set input parameters for detection
        pdx = PlantDetection()
        pdx.params.parameters = {'blur': 15, 'morph': 6, 'iterations': 4,
                                 'H': [30, 90], 'S': [20, 255], 'V': [20, 255]}
        pdx.params.save()
        # Load the set parameters
        pd = PlantDetection(image="plant_detection/soil_image.jpg",
                            from_file=True, coordinates=True,
                            text_output=False, save=False)
        pd.detect_plants()
        self.assertEqual(pd.plant_db.object_count, self.object_count)

    def test_calibration(self):
        """Load calibration input from file"""
        # Set input parameters for calibration
        pdx = PlantDetection()
        pdx.params.parameters['H'] = [160, 20]
        pdx.params.save()
        # Load the set parameters
        pd = PlantDetection(calibration_img="plant_detection/p2c_test_calibration.jpg",
                            from_file=True,
                            text_output=False, save=False, debug=True)
        pd.calibrate()
        self.assertEqual(pd.plant_db.object_count, 2)

    def tearDown(self):
        self.outfile.close()
        sys.stdout = sys.__stdout__
        os.remove('text_output_test.txt')


class PDTestArray(unittest.TestCase):
    """Test input parameter array use"""

    def test_array_detect_simple(self):
        """Detect plants using simple array input"""
        pd = PlantDetection(
            image="plant_detection/soil_image.jpg",
            array=[{"size": 5, "kernel": 'ellipse', "type": 'erode', "iters": 2},
                   {"size": 3, "kernel": 'ellipse', "type": 'dilate', "iters": 8}],
            text_output=False, save=False)
        pd.detect_plants()
        object_count = 29
        self.assertEqual(pd.plant_db.object_count, object_count)

    def test_array_detect_debug(self):
        """Detect plants using array input and debug"""
        pd = PlantDetection(
            image="plant_detection/soil_image.jpg",
            array=[{"size": 5, "kernel": 'ellipse', "type": 'close', "iters": 2},
                   {"size": 3, "kernel": 'ellipse', "type": 'open', "iters": 8}],
            text_output=False, save=False, debug=True)
        pd.detect_plants()
        object_count = 25
        self.assertEqual(pd.plant_db.object_count, object_count)


class PDTestClumpBuster(unittest.TestCase):
    """Test other options"""

    def setUp(self):
        """Test clump buster"""
        self.pd = PlantDetection(
            image="plant_detection/soil_image.jpg",
            morph=10,
            text_output=False, save=False, clump_buster=True)
        self.pd.detect_plants()
        self.object_count = 39

    def test_clump_buster(self):
        """Test clump buster"""
        self.assertEqual(self.pd.plant_db.object_count, self.object_count)


class PDTestGreyOut(unittest.TestCase):
    """Test grey out option"""

    def setUp(self):
        pd = PlantDetection(image="plant_detection/soil_image.jpg",
                            text_output=False, save=False,
                            grey_out=True)
        pd.detect_plants()
        self.pixel_mean = get_average_pixel_value(pd.image.images['current'])
        self.expected_pixel_mean = 138.7

    def test_grey_out(self):
        """Test grey out option"""
        self.assertAlmostEqual(self.pixel_mean,
                               self.expected_pixel_mean,
                               delta=0.25)


class PDTestCirclePlants(unittest.TestCase):
    """Test circle plants option"""

    def setUp(self):
        pd = PlantDetection(image="plant_detection/soil_image.jpg",
                            text_output=False, save=False,
                            draw_contours=False,
                            circle_plants=True)
        pd.detect_plants()
        self.pixel_mean = get_average_pixel_value(pd.image.images['current'])
        self.expected_pixel_mean = 69.9

    def test_circle_plants(self):
        """Test circle plants option"""
        self.assertAlmostEqual(self.pixel_mean,
                               self.expected_pixel_mean,
                               delta=0.25)


class PDTestDrawContours(unittest.TestCase):
    """Test draw contours option"""

    def setUp(self):
        pd = PlantDetection(image="plant_detection/soil_image.jpg",
                            text_output=False, save=False,
                            draw_contours=True,
                            circle_plants=False)
        pd.detect_plants()
        self.pixel_mean = get_average_pixel_value(pd.image.images['current'])
        self.expected_pixel_mean = 72.9

    def test_draw_contours(self):
        """Test draw contours option"""
        self.assertAlmostEqual(self.pixel_mean,
                               self.expected_pixel_mean,
                               delta=0.25)


class PDTestTextOutput(unittest.TestCase):
    """Test all text output"""

    def setUp(self):
        self.outfile = open('text_output_test.txt', 'w')
        sys.stdout = self.outfile

    def test_verbose_text_output_no_coordinates(self):
        """Test verbose text output without coordinate conversion"""
        pd = PlantDetection(
            image="plant_detection/soil_image.jpg",
            save=False, print_all_json=True)
        pd.detect_plants()
        check_file_length(self, 71 if USING_FT else 69)

    def test_condensed_text_output_no_coordinates(self):
        """Test condensed text output without coordinate conversion"""
        pd = PlantDetection(
            image="plant_detection/soil_image.jpg",
            verbose=False,
            save=False, print_all_json=True)
        pd.detect_plants()
        check_file_length(self, 10 if USING_FT else 8)

    def test_verbose_text_output(self):
        """Test verbose text output"""
        pd = PlantDetection(
            image="plant_detection/soil_image.jpg",
            calibration_img="plant_detection/p2c_test_calibration.jpg",
            save=False, print_all_json=True)
        pd.calibrate()
        pd.detect_plants()
        check_file_length(self, 80 if USING_FT else 78)

    def test_condensed_text_output(self):
        """Test condensed text output"""
        pd = PlantDetection(
            image="plant_detection/soil_image.jpg",
            calibration_img="plant_detection/p2c_test_calibration.jpg",
            verbose=False,
            save=False, print_all_json=True)
        pd.calibrate()
        pd.detect_plants()
        check_file_length(self, 12 if USING_FT else 10)

    def tearDown(self):
        self.outfile.close()
        sys.stdout = sys.__stdout__
        os.remove('text_output_test.txt')


class PDTestDebugMode(unittest.TestCase):
    """Test debug option"""

    def setUp(self):
        self.outfile = open('text_output_test.txt', 'w')
        sys.stdout = self.outfile

    def test_debug_no_coordinates(self):
        """Test debug mode without coordinate conversion"""
        pd = PlantDetection(image="plant_detection/soil_image.jpg",
                            text_output=False, save=False,
                            debug=True)
        pd.detect_plants()
        self.assertTrue(os.path.exists('soil_image_masked_original.jpg'))

    def test_debug_with_coordinates(self):
        """Test debug mode with coordinate conversion"""
        pd = PlantDetection(
            image="plant_detection/soil_image.jpg",
            calibration_img="plant_detection/p2c_test_calibration.jpg",
            text_output=False, save=False,
            debug=True)
        pd.calibrate()
        pd.detect_plants()
        self.assertTrue(os.path.exists('soil_image_coordinates_found.jpg'))
        os.remove('soil_image_masked_original.jpg')

    def tearDown(self):
        self.outfile.close()
        sys.stdout = sys.__stdout__
        os.remove('text_output_test.txt')


class PDTestSafeRemove(unittest.TestCase):
    """Check output using safe remove feature"""

    def setUp(self):
        self.calibration = {'blur': 5, 'morph': 15, 'calibration_iters': 3,
                            'H': [160, 20], 'S': [100, 255], 'V': [100, 255],
                            'easy_calibration': False,
                            'calibration_circles_xaxis': True,
                            'camera_offset_coordinates': [200, 100],
                            'image_bot_origin_location': [0, 1],
                            'calibration_circle_separation': 1000}
        self.pd = PlantDetection(
            image="plant_detection/soil_image.jpg",
            calibration_img="plant_detection/p2c_test_calibration.jpg",
            calibration_data=self.calibration,
            text_output=False, save=False)
        self.pd.calibrate()
        self.input_params = {"blur": 15, "morph": 6, "iterations": 4,
                             "H": [30, 90], "S": [20, 255], "V": [20, 255]}

    def test_no_plants(self):
        """Check no plants in output"""
        self.input_params['H'] = [0, 0]  # None
        self.pd.params.parameters = self.input_params
        self.pd.detect_plants()
        self.assertEqual(len(self.pd.plant_db.plants['known']), 0)
        self.assertEqual(len(self.pd.plant_db.plants['save']), 0)
        self.assertEqual(len(self.pd.plant_db.plants['remove']), 0)
        self.assertEqual(len(self.pd.plant_db.plants['safe_remove']), 0)

    def test_one_remove_plants(self):
        """Check one remove plants in output"""
        self.input_params['H'] = [1, 0]  # One Large
        self.pd.params.parameters = self.input_params
        self.pd.detect_plants()
        self.assertEqual(len(self.pd.plant_db.plants['known']), 0)
        self.assertEqual(len(self.pd.plant_db.plants['save']), 0)
        self.assertEqual(len(self.pd.plant_db.plants['remove']), 1)
        self.assertEqual(len(self.pd.plant_db.plants['safe_remove']), 0)

    def test_one_saved_plant(self):
        """Check none removed but one known/saved plant in output"""
        self.input_params['H'] = [1, 0]  # One Large
        self.pd.plant_db.plants['known'] = [
            {'y': 500, 'x': 800, 'radius': 100}]
        self.pd.params.parameters = self.input_params
        self.pd.detect_plants()
        self.assertEqual(len(self.pd.plant_db.plants['known']), 1)
        self.assertEqual(len(self.pd.plant_db.plants['save']), 1)
        self.assertEqual(len(self.pd.plant_db.plants['remove']), 0)
        self.assertEqual(len(self.pd.plant_db.plants['safe_remove']), 0)

    def test_one_large_safe_remove_plant(self):
        """Check one safe remove plant not removed: center still in safe zone"""
        self.input_params['H'] = [1, 0]  # One Large
        self.pd.plant_db.plants['known'] = [{'y': 500, 'x': 800, 'radius': 1}]
        self.pd.params.parameters = self.input_params
        self.pd.detect_plants()
        self.assertEqual(len(self.pd.plant_db.plants['known']), 1)
        self.assertEqual(len(self.pd.plant_db.plants['save']), 0)
        self.assertEqual(len(self.pd.plant_db.plants['remove']), 0)
        self.assertEqual(len(self.pd.plant_db.plants['safe_remove']), 1)

    def test_one_small_safe_remove_plant(self):
        """Check one safe remove plant not removed: too close to known"""
        self.pd.plant_db.plants['known'] = [{'y': 300, 'x': 1400, 'radius': 1}]
        self.pd.params.parameters = self.input_params
        self.pd.detect_plants()
        self.assertEqual(len(self.pd.plant_db.plants['known']), 1)
        self.assertEqual(len(self.pd.plant_db.plants['save']), 0)
        self.assertEqual(len(self.pd.plant_db.plants['remove']), 15)
        self.assertEqual(len(self.pd.plant_db.plants['safe_remove']), 1)
