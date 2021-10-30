#!/usr/bin/env python3.8

'Images.'

import numpy as np
import cv2 as cv
from process_image import ProcessImage, shape

FONT = cv.FONT_HERSHEY_PLAIN


def create_output_collage(all_images, details, location):
    'Save rotated images, depth maps, and histograms to a single image.'
    cell_size = np.max(all_images[0][0].shape[:2])
    collage = _concat_images(all_images, cell_size)
    values = details['values']
    disparity = values['disparity']
    measured = values['measured_distance']
    delta = values.get('disparity_delta')
    offset = values['disparity_offset']
    distance = values.get('calc_distance')
    factor = values['calibration_factor']
    soil_z = values.get('calculated_soil_z')
    low = values.get('soil_z_low')
    high = values.get('soil_z_high')
    text_lines = np.full((5, 2), ' ' * 25)
    text_lines[0][0] = f'{disparity = :.0f}'
    loc = {
        'x': f'{location.get("x"):.0f}' if location.get('x') else '_',
        'y': f'{location.get("y"):.0f}' if location.get('y') else '_',
        'z': location.get('z', values['current_z']),
    }
    text_lines[0][1] = f"     ({loc['x']}, {loc['y']}, {loc['z']:.0f})"
    text_lines[1][1] = f'{measured = }'
    if soil_z is not None:
        text_lines[1][0] = f'   {offset = :.0f}'
        text_lines[2][0] = f'    {delta = :.0f}'
        text_lines[2][1] = f' {distance = :.0f}'
        text_lines[3][0] = f'   {factor = :.3f}'
        text_lines[3][1] = f'    soil z = {soil_z} mm'
    if low is not None:
        text_lines[4][0] = f'      {low = } mm'
        text_lines[4][1] = f'     {high = } mm'
    factor = 4 if cell_size < 200 else 1
    for i, text_line in enumerate(text_lines):
        for j, text in enumerate(text_line):
            collage = cv.putText(
                collage, text,
                (int(shape(collage)['width'] / 2 * 0.1 + j * 600 / factor),
                 int(shape(collage)['height'] / 2 * 1.7 + i * 50 / factor)),
                FONT, 3 / factor, (255, 255, 255), int(2 / factor))
    return collage


def _concat_images(all_images, cell_size):
    height = len(all_images)
    width = len(all_images[0])
    size = np.append(np.multiply((height, width), cell_size), 3)
    collage = np.zeros(size, np.uint8)
    for row_index, row_images in enumerate(all_images):
        for col_index, original in enumerate(row_images):
            aspect = shape(original)['width'] / shape(original)['height']
            new_size = (cell_size, int(cell_size / aspect))
            resized = cv.resize(original, new_size)
            start = {'y': row_index * cell_size,
                     'x': col_index * cell_size}
            end = {'y': start['y'] + shape(resized)['height'],
                   'x': start['x'] + shape(resized)['width']}
            collage[start['y']:end['y'], start['x']:end['x']] = resized
    return collage


class Images():
    'Handle images.'

    def __init__(self, core, input_images, calc_soil_z):
        self.core = core
        self.base_name = self._get_base_name(input_images)
        self.angle = 0
        self.input = self._init_inputs(input_images)
        self.output = {}
        self.settings = core.settings.settings
        self.imgs = core.settings.images
        self.log = core.log
        self.calculate_soil_z = calc_soil_z
        self.rotated = True

    def _init_inputs(self, input_images):
        inputs = {}
        for stereo_id, image_infos in input_images.items():
            inputs[stereo_id] = []
            for info in image_infos:
                image = info.pop('data')
                if image is None:
                    self.log.error('Image missing.')
                img = self.init_img(image, info)
                inputs[stereo_id].append(img)
        return inputs

    @staticmethod
    def _get_base_name(input_images):
        left = input_images['left'][0]
        base_name = left['name'].split('/')[-1]
        if '.' in base_name:
            base_name = '.'.join(base_name.split('.')[:-1])
        if 'left_' in base_name:
            base_name = base_name.split('left_')[1]
        return base_name

    def _get_z_info(self):
        left = self.input['left'][0].info
        image_z = (left.get('location', {}) or {}).get('z')
        initial_z = self.settings['initial_position'].get('z', 0)
        current_z = float(image_z or initial_z)
        return {
            'image': image_z,
            'calibration': self.settings['calibration_measured_at_z'],
            'offset': self.settings['calibration_measured_at_z'] - current_z,
            'direction': -1 if self.settings['negative_z'] else 1,
            'current': current_z,
        }

    def set_angle(self, angle):
        'Set camera angle.'
        self.angle = angle
        for stereo_images in self.input.values():
            for image in stereo_images:
                image.angle = angle
        for image in self.output.values():
            image.angle = angle

    def init_img(self, image, info=None):
        'Initialize image.'
        if info is None:
            info = {}
        info['base_name'] = self.base_name
        return ProcessImage(self.core, image=image, angle=self.angle, info=info)

    def output_init(self, image, tag, reduce=True):
        'Initialize output image.'
        img = self.init_img(image, {'tag': tag})
        if reduce:
            img.reduce_data()
        self.output[tag] = img

    def filter_plants(self, image):
        'Rough removal of plants from an image.'
        if not self.settings['use_plant_color_mask']:
            return image
        left = self.input['left'][0]
        self.output_init(left.image, 'plants', reduce=False)
        plants = self.output['plants']
        plants.select_plants()
        if self.rotated:
            plants.image = left.rotate_copy(plants.image)
        plant_mask = plants.image > 0
        image = image.copy()
        image[plant_mask] = 0
        return image

    def save(self):
        'Save un-rotated depth maps and histograms according to verbosity setting.'
        if not self.imgs['output_enabled']:
            return
        self.log.debug('Saving output images...', verbosity=2)
        images = self.output
        images['depth'] = self.init_img(images['disparity'].image)
        images['depth'].normalize()
        depth_data = images['disparity'].data
        stats = depth_data.reduced['stats']
        soil_z, dts = self.calculate_soil_z(stats['mid'])
        low_soil_z, _ = self.calculate_soil_z(stats['low'])
        high_soil_z, _ = self.calculate_soil_z(stats['high'])
        dts['values']['soil_z_low'] = low_soil_z
        dts['values']['soil_z_high'] = high_soil_z
        z_prefix = f'{soil_z}_' if soil_z is not None else ''
        if self.imgs['depth_bw']:
            images['depth_bw'] = self.init_img(images['depth'].image)
            if self.rotated:
                images['depth_bw'].rotate(-1)
            images['depth_bw'].add_soil_z_annotation(soil_z)
            images['depth_bw'].save(f'{z_prefix}depth_map_bw')
        if self.imgs['depth_color']:
            left = self.input['left'][0]
            images['depth_color'] = self.init_img(images['depth'].image)
            images['depth_color'].colorize(depth_data)
            if self.rotated:
                images['depth_color'].rotate(-1)
            images['depth_blend'] = self.init_img(left.image)
            images['depth_blend'].blend_with(images['depth_color'].image)
        if self.imgs['collage']:
            left = self.input['left'][0]
            right = self.input['right'][0]
            for img in [left, right]:
                img.create_histogram(simple=True)
            images['disparity'].create_histogram(self.calculate_soil_z)
            images['depth'].channel3()
            if not self.rotated:
                images['depth'].rotate()
            images['stereo_blend'] = self.init_img(left.image)
            images['stereo_blend'].blend_with(right.image)
            images['stereo_blend'].rotate()
            all_images = [
                [left.rotate_copy(),
                 right.rotate_copy(),
                 images['stereo_blend'].image],
                [images['depth'].image,
                 images['depth_color'].rotate_copy(),
                 images['depth_blend'].rotate_copy()],
                [left.histogram.histogram,
                 right.histogram.histogram,
                 images['disparity'].histogram.histogram]]
            location = left.info.get('location', {})
            collage = create_output_collage(all_images, dts, location)
            images['collage'] = self.init_img(collage)
            images['collage'].save('all')
        if self.imgs['histograms']:
            images['depth_color'].save('disparity_map')
            images['disparity'].save_histogram('histogram')
            images['img_hists'] = self.init_img(left.histogram.histogram)
            images['img_hists'].blend_with(right.histogram.histogram)
            images['img_hists'].save('image_histogram_blend')
        if self.imgs['extras']:
            if images.get('plants') is not None:
                if self.rotated:
                    images['plants'].rotate(-1)
                plant_mask = images['plants'].image > 0
                images['plants'].channel3()
                images['plants'].image[plant_mask] = left.image[plant_mask]
                images['plants'].blend_with(left.image, 1.5)
                images['plants'].save('plants')
            images['left_gray'] = self.init_img(left.preprocess(False))
            images['left_gray'].save('left_gray')
            images['right_gray'] = self.init_img(right.preprocess(False))
            images['right_gray'].save('right_gray')
            images['gray_blend'] = self.init_img(images['left_gray'].image)
            images['gray_blend'].blend_with(images['right_gray'].image)
            images['gray_blend'].save('gray_blend')
            left.rotate()
            left.save('rotated_left')
            right.rotate()
            right.save('rotated_right')
            images['stereo_blend'].save('stereo_blend')
            images['depth'].save('rotated_depth_map')
            images['disparity'].create_histogram(
                self.calculate_soil_z, color=False)
            images['disparity'].save_histogram('raw_histogram')
            if images.get('angles') is not None:
                for tag in ['angles', 'dx', 'dy']:
                    images[tag].create_histogram(title=tag)
                    images[tag].save_histogram(f'{tag}_histogram')
                    images[tag].normalize()
                    images[tag].reshape(images['left_gray'])
                    images[tag].colorize(images[tag].data, mid_only=True)
                    images[tag].save(tag)
        if self.imgs['depth_blend']:
            images['depth_blend'].add_soil_z_annotation(soil_z)
            images['depth_blend'].save(f'{z_prefix}depth_map')

    def save_data(self):
        'Save depth and color data according to verbosity setting.'
        if not self.core.settings.reports_enabled():
            return
        data = {
            'depth': (self.output['raw_disparity'].rotate_copy(direction=-1)
                      if self.rotated else self.output['raw_disparity'].image),
            'color': self.input['left'][0].image,
            'location': self.input['left'][0].info.get('location'),
            'angle': self.angle,
            'chosen_depth': self.output['disparity'].data.report['mid'],
            'calibration': {k: v for k, v in self.settings.items()
                            if k.startswith('calibration_')
                            or k == 'measured_distance'},
            'mm_per_pixel': self.settings['millimeters_per_pixel'],
        }
        directory = self.settings['images_dir']
        filename = f'{directory}/{self.core.settings.title}data.npz'
        with open(filename, 'wb') as data_file:
            np.savez(data_file, **data)
