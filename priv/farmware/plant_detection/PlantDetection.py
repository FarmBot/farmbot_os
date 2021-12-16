#!/usr/bin/env python
"""Plant Detection.

Detects green plants on a dirt background
 and marks them with red circles.
"""
import sys
import os
from plant_detection.P2C import Pixel2coord
from plant_detection.Image import Image
from plant_detection.Parameters import Parameters
from plant_detection.DB import DB
from plant_detection.Capture import Capture
from plant_detection.Log import log


class PlantDetection(object):
    """Detect plants in image and output an image with plants marked.

    Kwargs:
       image (str): filename of image to process (default = None)
           None -> take photo instead
       coordinates (boolean): use coordinate conversion (default = False)
       calibration_img (filename): calibration image filename used to
           output coordinates instead of pixel locations (default = None)
       calibration_data (dict): calibration data inputs,
           overwrites other calibration data inputs (default = None)
       known_plants (list): {'x': x, 'y': y, 'radius': radius}
                            of known (intentional) plants
                            (default = None)
       debug (boolean): output debug images (default = False)
       blur (int): blur kernel size (must be odd, default = 5)
       morph (int): amount of filtering (default = 5)
       iterations (int): number of morphological iterations (default = 1)
       array (list): list of morphs to run
           [morph kernel size, morph kernel type, morph type, iterations]
           example:
           [{"size": 5, "kernel": 'ellipse', "type": 'erode',  "iters": 2},
            {"size": 3, "kernel": 'ellipse', "type": 'dilate', "iters": 8}]
                  (default = None)
       save (boolean): save images (default = True)
       clump_buster (boolean): attempt to break
                               plant clusters (default = False)
       HSV_min (list): green lower bound Hue(0-179), Saturation(0-255),
                       and Value(0-255) (default = [30, 20, 20])
       HSV_max (list): green upper bound Hue(0-179), Saturation(0-255),
                       and Value(0-255) (default = [90, 255, 255])
       from_file (boolean): load data from file
            plant-detection_inputs.json
            plant-detection_p2c_calibration_parameters.json
            plant-detection_plants.json
            (default = False)
       from_env_var (boolean): load data from environment variable,
            overriding other parameter inputs
            (default = False)
       text_output (boolean): print text to STDOUT (default = True)
       verbose (boolean): print verbose text to STDOUT.
            otherwise, print condensed text output (default = True)
       print_all_json (boolean): print all JSON data used to STDOUT
            (default = False)
       grey_out (boolean): grey out regions in image that have
            not been selected (default = False)
       draw_contours (boolean): draw an outline around the boundary of
            detected plants (default = True)
       circle_plants (boolean): draw an enclosing circle around
            detected plants (default = True)
       GUI (boolean): settings for the local GUI (default = False)
       app (boolean): connect to the FarmBot web app (default = False)
       app_image_id (string): use image from the FarmBot API (default = None)

    Examples:
       PD = PlantDetection()
       PD.detect_plants()

       PD = PlantDetection(
          image='plant_detection/soil_image.jpg', morph=3, iterations=10,
          debug=True)
       PD.detect_plants()

       PD = PlantDetection(
          image='plant_detection/soil_image.jpg',
          blur=9, morph=7, iterations=4,
          calibration_img="plant_detection/p2c_test_calibration.jpg")
       PD.calibrate()
       PD.detect_plants()

       PD = PlantDetection(
         image='plant_detection/soil_image.jpg', blur=15, grey_out=True,
         array=[
            {"size": 5, "kernel": 'ellipse', "type": 'erode',  "iters": 2},
            {"size": 3, "kernel": 'ellipse', "type": 'dilate', "iters": 8}],
         debug=True, clump_buster=False,
         HSV_min=[30, 15, 15], HSV_max=[85, 245, 245])
       PD.detect_plants()
    """

    def __init__(self, **kwargs):
        """Read arguments (and change settings) and initialize modules."""
        # Default Data Inputs
        self.image = None
        self.plant_db = DB()

        # Default Parameter Inputs
        self.params = Parameters()
        self.params.add_missing_params('detect')

        # Load keyword argument inputs
        self._data_inputs(kwargs)
        self._parameter_inputs(kwargs)
        self.args = kwargs

        # Set remaining arguments to defaults
        self._set_defaults()

        # Changes based on inputs
        if self.args['calibration_img'] is not None:
            # self.coordinates = True
            self.args['coordinates'] = True
        if self.args['GUI']:
            self.args['save'] = False
            self.args['text_output'] = False
        if self.args['app']:
            self.args['verbose'] = False
            self.args['from_env_var'] = True
            self.plant_db.app = True

        # Remaining initialization
        self.p2c = None
        self.capture = Capture().capture
        self.final_marked_image = None
        self.plant_db.tmp_dir = None

    def _set_defaults(self):
        default_args = {
            # Default Data Inputs
            'image': None, 'calibration_img': None, 'known_plants': None,
            'app_image_id': None, 'calibration_data': None,
            # Default Program Options
            'coordinates': False, 'from_file': False, 'from_env_var': False,
            'clump_buster': False, 'GUI': False, 'app': False,
            # Default Output Options
            'debug': False, 'save': True,
            'text_output': True, 'verbose': True, 'print_all_json': False,
            'output_celeryscript_points': False,
            # Default Graphic Options
            'grey_out': False, 'draw_contours': True, 'circle_plants': True,
            # Default processing options
            'array': None,
            'blur': self.params.parameters['blur'],
            'morph': self.params.parameters['morph'],
            'iterations': self.params.parameters['iterations'],
            'HSV_min': [self.params.parameters['H'][0],
                        self.params.parameters['S'][0],
                        self.params.parameters['V'][0]],
            'HSV_max': [self.params.parameters['H'][1],
                        self.params.parameters['S'][1],
                        self.params.parameters['V'][1]],
        }
        for key, value in default_args.items():
            if key not in self.args:
                self.args[key] = value

    def _data_inputs(self, kwargs):
        """Load data inputs from keyword arguments."""
        for key in kwargs:
            if key == 'known_plants':
                self.plant_db.plants['known'] = kwargs[key]

    def _parameter_inputs(self, kwargs):
        """Load parameter inputs from keyword arguments."""
        for key in kwargs:
            if key == 'blur':
                self.params.parameters['blur'] = kwargs[key]
            if key == 'morph':
                self.params.parameters['morph'] = kwargs[key]
            if key == 'iterations':
                self.params.parameters['iterations'] = kwargs[key]
            if key == 'array':
                self.params.array = kwargs[key]
            if key == 'HSV_min':
                hsv_min = kwargs[key]
                self.params.parameters['H'][0] = hsv_min[0]
                self.params.parameters['S'][0] = hsv_min[1]
                self.params.parameters['V'][0] = hsv_min[2]
            if key == 'HSV_max':
                hsv_max = kwargs[key]
                self.params.parameters['H'][1] = hsv_max[0]
                self.params.parameters['S'][1] = hsv_max[1]
                self.params.parameters['V'][1] = hsv_max[2]

    def _calibration_input(self):  # provide inputs to calibration
        if self.args['app_image_id'] is not None:
            self.args['calibration_img'] = int(self.args['app_image_id'])
        if self.args['calibration_img'] is None and self.args['coordinates']:
            # Calibration requested, but no image provided.
            # Take a calibration image.
            self.args['calibration_img'] = self.capture()

        # Set calibration input parameters
        if self.args['from_env_var']:
            calibration_input = 'env_var'
        elif self.args['from_file']:  # try to load from file
            calibration_input = 'file'
        else:  # Use default calibration inputs
            calibration_input = None

        # Call coordinate conversion module
        self.p2c = Pixel2coord(self.plant_db,
                               calibration_image=self.args['calibration_img'],
                               calibration_data=self.args['calibration_data'],
                               load_data_from=calibration_input)
        self.p2c.debug = self.args['debug']

    def calibrate(self):
        """Calibrate the camera for plant detection.

        Initialize the coordinate conversion module using a calibration image,
        perform calibration, and save calibration data.
        """
        self._calibration_input()  # initialize coordinate conversion module
        exit_flag = self.p2c.calibration()  # perform calibration
        if exit_flag:
            sys.exit(0)
        self._calibration_output()  # save calibration data

    def _calibration_output(self):  # save calibration data
        if self.args['save'] or self.args['debug']:
            self.p2c.image.images['current'] = self.p2c.image.images['marked']
            self.p2c.image.save('calibration_result')

        # Print verbose results
        if self.args['verbose'] and self.args['text_output']:
            if self.p2c.calibration_params['total_rotation_angle'] != 0:
                print(" Note: required rotation of "
                      "{:.2f} degrees executed.".format(
                          self.p2c.calibration_params['total_rotation_angle']))
            if self.args['debug']:
                # print number of objects detected
                self.plant_db.print_count(calibration=True)
                # print coordinate locations of calibration objects
                self.p2c.p2c(self.plant_db)
                self.plant_db.print_coordinates()
                print('')

        # Print condensed output if verbose output is not chosen
        if self.args['text_output'] and not self.args['verbose']:
            print("Calibration complete. (rotation:{}, scale:{})".format(
                self.p2c.calibration_params['total_rotation_angle'],
                self.p2c.calibration_params['coord_scale']))

        # Send calibration result log toast
        if self.args['app']:
            log('Camera calibration complete; setting pixel coordinate scale'
                ' to {} and camera rotation to {} degrees.'.format(
                    self.p2c.calibration_params['coord_scale'],
                    self.p2c.calibration_params['total_rotation_angle']),
                'success', 'Success', ['toast'], True)

        # Save calibration data
        if self.args['from_env_var']:
            # to environment variable
            self.p2c.save_calibration_data_to_env()
        elif self.args['from_file']:  # to file
            self.p2c.save_calibration_parameters()
        else:  # to Parameters() instance
            self.params.calibration_data = self.p2c.calibration_params

    def _detection_input(self):  # provide input to detect_plants
        # Load input parameters
        if self.args['from_file']:
            # Requested to load detection parameters from file
            try:
                self.params.load('detect')
            except IOError:
                print("Warning: Input parameter file load failed. "
                      "Using defaults.")
            self.plant_db.load_plants_from_file()
        if self.args['app']:
            self.plant_db.load_plants_from_web_app()
        if self.args['from_env_var']:
            # Requested to load detection parameters from json ENV variable
            self.params.load_env_var('detect')

        # Print input parameters and filename of image to process
        if self.args['verbose'] and self.args['text_output']:
            self.params.print_input()
            print("\nProcessing image: {}".format(self.args['image']))

    def _detection_image(self):  # get image to process
        self.image = Image(self.params, self.plant_db)
        # Get image to process
        try:  # check for API image ID
            image_id = self.args['app_image_id']
        except KeyError:
            image_id = None
        if image_id is not None:  # download image
            try:
                self.image.download(image_id)
            except IOError:
                print("Image download failed for image ID {}.".format(
                    str(image_id)))
                sys.exit(0)
        elif self.args['image'] is None:  # No image provided. Capture one.
            self.image.capture()
            if self.args['debug']:
                self.image.save('photo')
        else:  # Image provided. Load it.
            filename = self.args['image']
            self.image.load(filename)
        self.image.debug = self.args['debug']

    def _coordinate_conversion(self):  # determine detected object coordinates
        # Load calibration data
        load_data_from = None
        calibration_data = None
        if self.args['from_env_var']:
            load_data_from = 'env_var'
        elif self.args['from_file']:
            load_data_from = 'file'
        else:  # use data saved in self.params
            calibration_data = self.params.calibration_data
        # Initialize coordinate conversion module
        self.p2c = Pixel2coord(
            self.plant_db,
            load_data_from=load_data_from, calibration_data=calibration_data)
        self.p2c.debug = self.args['debug']
        # Check for coordinate conversion calibration results
        present = {'coord_scale': False,
                   'camera_z': False,
                   'center_pixel_location': False,
                   'total_rotation_angle': False}
        try:
            for key in present:
                present[key] = self.p2c.calibration_params[key]
        except KeyError:
            log("ERROR: Coordinate conversion calibration values "
                "not found. Run calibration first.",
                message_type='error', title='plant-detection')
            sys.exit(0)
        # Validate coordinate conversion calibration data for image
        calibration_data_valid = self.p2c.validate_calibration_data(
            self.image.images['current'])
        if not calibration_data_valid:
            log("ERROR: Coordinate conversion calibration values "
                "invalid for provided image.",
                message_type='error', title='plant-detection')
            sys.exit(0)
        # Determine object coordinates
        self.image.coordinates(self.p2c,
                               draw_contours=self.args['draw_contours'])
        # Organize objects into plants and weeds
        self.plant_db.identify(self.params.parameters)
        if self.plant_db.plants['safe_remove']:
            self.image.safe_remove(self.p2c)

    def _coordinate_conversion_output(self):  # output detected object data
        # Print and output results
        if self.args['text_output']:
            self.plant_db.print_count()  # print number of objects detected
        if self.args['verbose'] and self.args['text_output']:
            self.plant_db.print_identified()  # print organized plant data
        if self.args['output_celeryscript_points']:
            self.plant_db.output_celery_script()  # print points JSON to stdout
        if self.args['app']:
            save_detected_plants = self.params.parameters['save_detected_plants']
            # add detected weeds and points to FarmBot Web App
            self.plant_db.upload_plants(save_detected_plants)
        if self.args['debug']:
            self.image.save_annotated('contours')
            self.image.images['current'] = self.image.images['marked']
            self.image.save_annotated('coordinates_found')
        if self.args['circle_plants']:
            self.image.label(self.p2c)  # mark objects with colored circles
        self.image.grid(self.p2c)  # add coordinate grid and features

    def detect_plants(self):
        """Detect the green objects in the image."""
        # Gather inputs
        self._detection_input()
        self._detection_image()

        # Process image in preparation for detecting plants (blur, mask, morph)
        self.image.initial_processing()

        # Optionally break up masses by splitting them into quarters
        if self.args['clump_buster']:
            self.image.clump_buster()

        # Optionally grey out regions not detected as objects
        if self.args['grey_out']:
            self.image.grey()

        # Return coordinates if requested
        if self.args['coordinates']:  # Convert pixel locations to coordinates
            self._coordinate_conversion()
            self._coordinate_conversion_output()
        else:  # No coordinate conversion
            # get pixel locations of objects
            self.image.find(draw_contours=self.args['draw_contours'])
            if self.args['circle_plants']:
                self.image.label()  # Mark plants with red circle
            if self.args['debug']:
                self.image.save_annotated('contours')
            if self.args['text_output']:
                self.plant_db.print_count()  # print number of objects detected
            if self.args['verbose'] and self.args['text_output']:
                self.plant_db.print_pixel()  # print object pixel location text
            self.image.images['current'] = self.image.images['marked']

        self._show_detection_output()  # show output data
        self._save_detection_output()  # save output data

    def _show_detection_output(self):  # show detect_plants output
        # Print raw JSON to STDOUT
        if self.args['print_all_json']:
            print("\nJSON:")
            print(self.params.parameters)
            print(self.plant_db.plants)
            if self.p2c is not None:
                print(self.p2c.calibration_params)

        # Print condensed inputs if verbose output is not chosen
        if self.args['text_output'] and not self.args['verbose']:
            print('{}: {}'.format('known plants input',
                                  self.plant_db.plants['known']))
            print('{}: {}'.format('parameters input',
                                  self.params.parameters))
            print('{}: {}'.format('coordinates input',
                                  self.plant_db.coordinates))

    def _save_detection_output(self):  # save detect_plants output
        # Final marked image
        if self.args['save'] or self.args['debug']:
            self.image.save('marked')
        elif self.args['GUI']:
            self.final_marked_image = self.image.images['marked']

        # Save input parameters
        if self.args['from_env_var']:
            # to environment variable
            self.params.save_to_env_var('detect')
        elif self.args['save']:
            # to file
            self.params.save()
        elif self.args['GUI']:
            # to file for GUI
            self.params.save()

        # Save plants
        if self.args['save']:
            self.plant_db.save_plants()


if __name__ == "__main__":
    DIR = os.path.dirname(os.path.realpath(__file__)) + os.sep
    IMG = DIR + 'soil_image.jpg'
    CALIBRATION_IMG = DIR + "p2c_test_calibration.jpg"
    if len(sys.argv) == 1:
        PD = PlantDetection(
            image=IMG,
            blur=15, morph=6, iterations=4,
            calibration_img=CALIBRATION_IMG,
            known_plants=[{'x': 200, 'y': 600, 'radius': 100},
                          {'x': 900, 'y': 200, 'radius': 120}])
        PD.calibrate()  # use calibration img to get coordinate conversion data
        PD.detect_plants()  # detect coordinates and sizes of weeds and plants
    else:  # command line argument(s)
        if sys.argv[1] == '--GUI':
            from plant_detection.GUI import PlantDetectionGUI
            if len(sys.argv) == 3:  # image filename provided
                GUI = PlantDetectionGUI(image_filename=sys.argv[2],
                                        plant_detection=PlantDetection)
            else:  # Use `soil_image.jpg`
                GUI = PlantDetectionGUI(image_filename=IMG,
                                        plant_detection=PlantDetection)
            GUI.run()
        elif sys.argv[1] == '--cGUI':
            from plant_detection.GUI import CalibrationGUI
            if len(sys.argv) == 3:  # calibration image filename provided
                calibration_gui = CalibrationGUI(
                    cimage_filename=sys.argv[2],
                    image_filename=IMG,
                    plant_detection=PlantDetection)
            elif len(sys.argv) == 4:  # both image filenames provided
                calibration_gui = CalibrationGUI(
                    cimage_filename=sys.argv[2],
                    image_filename=sys.argv[3],
                    plant_detection=PlantDetection)
            else:  # Use `soil_image.jpg`
                calibration_gui = CalibrationGUI(
                    image_filename=IMG,
                    plant_detection=PlantDetection)
            calibration_gui.run()
        else:  # image filename provided
            IMG = sys.argv[1]
            PD = PlantDetection(
                image=IMG, from_file=True, debug=True)
            PD.detect_plants()
