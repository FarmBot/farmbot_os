#!/usr/bin/env python3.8

'Generate test images.'

import os
import json
import hashlib
import numpy as np
import cv2 as cv
import matplotlib.pyplot as plt
from reduce_data import ReduceData
from core import Core
from histogram import Histogram
from tests import path


class ImageGenerator():
    'Handle generation of test images.'

    def __init__(self):
        self.options = {
            'form': 'dots_and_line',
            'highlight_target_region': False,
            'static': 0,
            'noise': 0,
            'factor': 0.2,
            'add_subject_padding': False,
            'dpi': 100,
            'background_color': (0.5, 0.5, 0.5),
            'soil_resolution': 50,
            'soil_grain_size': 16,
            'colormap': 'copper',
        }
        self.markers = '.4+32*1|^v><xodDsHhp'
        self.markers = 'D' * 20
        self.static = None
        self.noise = None

    def random(self, count):
        'Generate random positions.'
        def _r():
            return np.random.random_sample(count) * 100
        return {m: {'x': _r(), 'y': _r()} for m in self.markers}

    def add_static(self):
        'Add static that does not change between images.'
        if self.options['static']:
            for marker, positions in self.static.items():
                plt.plot(positions['x'], positions['y'], marker, color='white')

    def add_noise(self, stereo_label):
        'Add noise that changes between images.'
        if self.options['noise']:
            for marker, positions in self.noise.get(stereo_label, {}).items():
                plt.plot(positions['x'], positions['y'], marker)

    def generate(self):
        'Generate images using the provided form.'
        self.static = self.random(self.options['static'])
        self.noise = {
            'left': self.random(self.options['noise']),
            'right':  self.random(self.options['noise'])}
        forms = {'dots_and_line': DotsAndLine, 'soil_surface': FakeSoil}
        stereo_filenames = forms[self.options['form']](self).create()
        return stereo_filenames


class DotsAndLine():
    'Four dots and a line.'

    def __init__(self, source):
        self.source = source
        self.options = source.options
        self.factor = self.options['factor']

    def create(self):
        'Create stereo test images.'
        left = self.create_stereo_test_image(['left'])
        right = self.create_stereo_test_image(['right'])
        self.create_stereo_test_image(['left', 'right'])
        return {'left': left, 'right': right}

    def create_stereo_test_image(self, stereo_labels):
        'Create a stereo test image.'
        name = f'dots_and_line_{self.factor:.2f}'
        image = TestImage(self.source, stereo_labels, name)
        if image.exists:
            return image.filename
        image.create_figure()
        if self.options['highlight_target_region']:
            plt.fill_between([0, 100], [25, 75], [75, 25], color='lightgray')
        for stereo_label in stereo_labels:
            color = image.stereo_params[stereo_label]['color']
            self.add_dots(stereo_label, color, stereo_label == 'right')
            self.add_lines(stereo_label, color)
        image.save()
        return image.filename

    def add_dots(self, stereo_label, color, add_labels):
        'Add dots to plot.'
        def _calc_x(param):
            offsets = param.get('x_offsets', np.zeros_like(dot_data['x']))
            dot_xs = np.array(dot_data['x']) + np.array(offsets)
            return dot_xs, offsets

        dot_data = {'x': [10, 90, 90, 88],
                    'y': [50, 50, 90, 10]}
        offsets = np.array([1, 1, 0, 2]) * self.factor
        dot_params = {'left': {'x_offsets': offsets}, 'right': {}}
        dot_xs, _ = _calc_x(dot_params[stereo_label])
        if self.options['add_subject_padding']:
            plt.plot(dot_data['x'], dot_data['y'], 'o', ms=120, color='gray')
        for ms, alt in zip([100, 80, 60], [0, -25, 25]):
            alt_color = color.copy()
            alt_color[1] -= alt / 255
            plt.plot(dot_xs, dot_data['y'], 'o', ms=ms, mew=5, color=alt_color)

        if add_labels:
            dot_xs, _ = _calc_x(dot_params['right'])
            _, x_offsets = _calc_x(dot_params['left'])
            for dot_x, dot_y, x_offset in zip(dot_xs, dot_data['y'], x_offsets):
                plt.annotate(f'{x_offset:.1f}', (dot_x, dot_y), (30, 0),
                             fontsize=20, ha='center', va='center',
                             textcoords='offset points',
                             arrowprops={'fill': True, 'color': 'k'})

    def add_lines(self, stereo_label, color):
        'Add lines to plot.'
        line_data = [
            {'x': np.array([50, 50]), 'y': [0, 100]},
        ]
        line_params = {
            'left': {'x_offsets': [[2 * self.factor, 0]]},
            'right': {},
        }
        offsets = line_params[stereo_label].get('x_offsets', [[0, 0]])
        for line, offset in zip(line_data, offsets):
            line_xs = line['x'] + offset
            if self.options['add_subject_padding']:
                plt.plot(line['x'], line['y'], '-', lw=40, color='gray')
            for off, alt in zip([0, 1, 2], [0, -25, 25]):
                alt_color = color.copy()
                alt_color[1] -= alt / 255
                plt.plot(line_xs + off, line['y'], '-', lw=10, color=alt_color)


class FakeSoil():
    'Fake soil surface.'

    def __init__(self, source):
        self.source = source
        self.options = source.options
        self.markers = source.markers
        self.grid = self.init_grid(self.options['soil_resolution'])
        self.sparse_grid = self.init_grid(10)
        rand = np.random.triangular(0.3, 0.5, 0.6, size=len(self.markers))
        colormap = plt.cm.get_cmap(self.options['colormap'])
        self.colors = [colormap(r) for r in rand]

    def init_grid(self, length):
        'Generate soil surface points.'
        points = np.linspace(0, 100, length)
        soil_x, soil_y = np.meshgrid(points, points)
        grid = np.dstack((np.hstack(soil_x), np.hstack(soil_y)))[0]
        np.random.default_rng().shuffle(grid)
        grid = np.array(np.split(grid, len(self.markers)))
        return grid

    def create(self):
        'Create stereo test images.'
        left = self.soil_surface(['left'])
        right = self.soil_surface(['right'])
        self.profile()
        self.depth()
        self.soil_surface(['left', 'right'])
        return {'left': left, 'right': right}

    @staticmethod
    def disparity(x_positions):
        'Pixel movement curve.'
        @np.vectorize
        def _func(x_position):
            if x_position > 60:
                return float(x_position * 0.01 + 40 * 0.01)
            if x_position > 40:
                return float(1)
            return float(x_position * 0.01 + 60 * 0.01)
        return _func(x_positions)

    def profile(self):
        'Plot profile.'
        name = 'soil_profile'
        image = TestImage(self.source, [], name)
        if image.exists:
            return
        image.create_figure()
        soil_x = np.linspace(0, 100, 100)
        soil_y = self.disparity(soil_x) * 50
        plt.fill_between(soil_x, soil_y * 0, soil_y, color='tan')
        fontdict = {'fontweight': 'bold', 'color': 'white', 'ha': 'center'}
        for x_loc, label_offset in [[0, 3], [50, 0], [100, -3]]:
            y_loc = self.disparity(x_loc)
            plt.text(x_loc + label_offset, y_loc * 50 + 4, y_loc * 10,
                     fontdict=fontdict)
        plt.text(50, 97, 'soil profile', fontdict=fontdict)
        image.save()

    def depth(self):
        'Plot expected depth map.'
        image = TestImage(self.source, [], 'soil_surface_expected_histogram')
        if image.exists:
            return
        disparity_x = self.disparity(np.linspace(0, 100, 1000)) * 10 * 16 / 3
        img = np.uint8([disparity_x] * 1000)
        hist_img_data = img.copy()
        hist_img_data[0][0] = 0
        hist_img_data[-1][-1] = 255 * 3
        hist = Histogram(ReduceData(Core(quiet=True), hist_img_data, {}),
                         simple=True).histogram
        cv.imwrite(image.filename, hist)
        image = TestImage(self.source, [], 'exaggerated_soil_expected_depth')
        img = np.array([disparity_x] * 1000)
        img = cv.normalize(img, img, 0, 255, cv.NORM_MINMAX).astype(np.uint8)
        cv.imwrite(image.filename, img)

    def _plot_grid(self, stereo_labels, grid, colors, markers):
        for stereo_label in stereo_labels:
            grid_copy = grid.copy()
            if stereo_label == 'left':
                grid_copy[:, :, 0] += self.disparity(grid[:, :, 0])
            for i, points in enumerate(grid_copy):
                plt.plot(points[:, 0], points[:, 1],
                         markers[i], ms=self.options['soil_grain_size'], mew=4,
                         color=colors[stereo_label][i])

    def soil_surface(self, stereo_labels):
        'Plot soil surface.'
        name = 'soil_surface'
        image = TestImage(self.source, stereo_labels, name)
        if image.exists:
            return image.filename
        image.create_figure()
        colors = {s: self.colors for s in stereo_labels}
        self._plot_grid(stereo_labels, self.grid, colors, self.markers)
        param = image.stereo_params
        colors = {s: [param[s]['color']] *
                  len(self.markers) for s in stereo_labels}
        markers = '|' * len(self.markers)
        self._plot_grid(stereo_labels, self.sparse_grid, colors, markers)
        image.save()
        return image.filename


class TestImage():
    'Generate test image.'

    def __init__(self, source, stereo_labels, name):
        self.source = source
        self.options = source.options
        self.stereo_labels = stereo_labels
        self.name = name
        self.stereo_params = {
            'left': {'title_y': 90,
                     'color': [255 / 255, 179 / 255, 112 / 255]},
            'right': {'title_y': 80,
                      'color': [133 / 255, 213 / 255, 255 / 255]},
        }
        self.filename = self.init_filename()
        self.exists = os.path.exists(self.filename)

    def init_filename(self, name=None):
        'Get filename.'
        options_str = json.dumps(self.options)
        sha = hashlib.sha1(bytes(options_str, 'utf-8')).hexdigest()[:7]
        stereo_id = ''
        if len(self.stereo_labels) == 1:
            stereo_id = f'{self.stereo_labels[0]}_'
        if len(self.stereo_labels) > 1:
            stereo_id = 'both_'
        directory = path("images/generated")
        if name is None:
            name = self.name
        filename = f'{directory}/{sha}_{stereo_id}{name}.png'
        return filename

    def create_figure(self):
        'Create stereo test image base.'
        plt.figure(figsize=(10, 10))
        plt.fill_between([0, 100], [0, 0], [100, 100],
                         color=self.options['background_color'])
        for stereo_label in self.stereo_labels:
            color = self.stereo_params[stereo_label]['color']
            title_y = self.stereo_params[stereo_label]['title_y']
            plt.text(30, title_y, stereo_label.upper(),
                     fontsize=20, ha='center', color=color, fontweight='bold')

    def save(self):
        'Save test image.'
        for stereo_label in self.stereo_labels:
            self.source.add_static()
            self.source.add_noise(stereo_label)
        plt.xlim(0, 100)
        plt.ylim(0, 100)
        plt.axis('off')
        plt.tight_layout(pad=0)
        plt.savefig(self.filename, dpi=self.options['dpi'])
        plt.close()
