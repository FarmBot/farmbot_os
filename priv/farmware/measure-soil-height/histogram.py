#!/usr/bin/env python3.8

'Generate histogram.'

from statistics import NormalDist
import numpy as np
import cv2 as cv

COLORS = {
    'gray': [200] * 3,
    'red': (100, 100, 255),
    'green': (100, 255, 100),
    'purple': (155, 100, 100),
    'light_red': (100, 100, 150),
    'white': (255, 255, 255),
    'black': (0, 0, 0),
}
FONT = cv.FONT_HERSHEY_PLAIN


def normalize(data, range_max, new_width, range_min=0):
    'Normalize data to new width.'
    data_width = (range_max - range_min) or 1
    normalized_data = ((data - range_min) / data_width * new_width)
    if not isinstance(data, (int, float)):
        return normalized_data.astype(int)
    if np.isnan(data):
        return 0
    return int(normalized_data)


class Histogram():
    'Generate histogram.'

    def __init__(self, image_data, calc_soil_z=None, **kwargs):
        self.options = {
            'simple': kwargs.get('simple', False),
            'color': kwargs.get('color', True),
        }
        self.calc_soil_z = calc_soil_z or (lambda _: (None, {}))
        data = image_data.data
        self.reduced = image_data.reduced
        self.data = {
            'data': data,
            'mid': data[self.reduced['masks']['mid']],
        }
        if len(self.reduced['history']) > 1:
            prev_mid = data[self.reduced['history'][-2]['masks']['mid']]
        else:
            prev_mid = self.data['mid']
        self.data['data'] = data[np.invert(np.isnan(data))]
        self.data['mid'] = self.data['mid'][np.invert(
            np.isnan(self.data['mid']))]
        self.data['prev_mid'] = prev_mid[np.invert(np.isnan(prev_mid))]
        self.stats = self.reduced['stats']
        no_data = len(self.data['data']) < 1
        self.params = {
            'title': kwargs.get('title', 'disparity'),
            'min': min(0, 0 if no_data else self.data['data'].min()),
            'max': 0 if no_data else self.data['data'].max(),
            'bin_count': 256,
            'height': 1000,
        }
        self.params['width'] = self.params['bin_count'] * 12
        size = (self.params['height'], self.params['width'], 3)
        background_color = COLORS['black']
        self.histogram = np.full(size, background_color, np.uint8)
        self.generate()

    def bin_color(self, i, bins, counts, color):
        'Get bin color.'
        if self.options['simple']:
            return COLORS['gray']
        x_position = i / float(len(counts))
        gray = [int(x_position * 255)] * 3
        mid = self.data['mid']
        prev_mid = self.data['prev_mid']
        if len(mid) < 1 or not self.options['color']:
            return gray
        if prev_mid.min() < bins[i] < prev_mid.max():
            if mid.min() < bins[i] < mid.max():
                return COLORS['green']
            return gray
        if color is not None:
            return COLORS['light_red'] if bins[i] < mid.min() else COLORS['red']
        return gray

    def plot_bins(self, counts, bins, max_value, color=None, fill=True):
        'Plot bin counts on histogram.'
        width, height = self.params['width'], self.params['height']
        normalized_counts = normalize(counts, max_value, height)
        for i, count in enumerate(normalized_counts):
            bin_width = int(width / (bins.size - 1))
            y_top = height - count
            y_bottom = height if fill else y_top + 2
            x_left = bin_width * i
            x_right = bin_width * (i + 1) - 0
            bin_color = self.bin_color(i, bins, counts, color)
            self.histogram[y_top:y_bottom, x_left:x_right] = bin_color

    def plot_text(self, text, location, thickness=2):
        'Add text to histogram.'
        if abs(location[0] - self.histogram.shape[1]) < 10:
            location = (location[0] - 100, location[1])
        self.histogram = cv.putText(
            self.histogram, text, location, FONT, 1.5, COLORS['white'], thickness)

    def plot_value(self, line):
        'Plot vertical line and label at value on histogram.'
        value_x = line['value']
        if value_x is None:
            return
        params = self.params
        hist_x = normalize(
            value_x, params['max'], params['width'], params['min'])
        length = params['height'] if line.get('t', 1) else 20
        self.histogram[:length, hist_x:(hist_x + 2)] = COLORS[line['color']]
        soil_z, _ = self.calc_soil_z(value_x)
        if self.stats['threshold'] is None:
            within_range = value_x < self.stats['max']
        else:
            within_range = self.stats['threshold'] < value_x < self.stats['max']
        plot_z = not self.options['simple'] and within_range and soil_z is not None
        soil_z_str = f' (z={soil_z})' if plot_z else ''
        label = f'{value_x:.0f}{soil_z_str}'
        align_left = value_x < self.stats['mid']
        label_x = (hist_x - len(label) * 15) if align_left else hist_x
        location = (max(0, label_x), line['y_label'])
        if line.get('t', 1):
            self.plot_text(label, location)

    def plot_lines(self):
        'Plot lines and labels at values of interest.'
        stats = self.stats
        lines = [
            {'value': 0, 'color': 'gray', 'y_label': 180},
            {'value': stats['threshold'], 'color': 'gray', 'y_label': 150},
            {'value': stats['low'], 'color': 'red', 'y_label': 120},
            {'value': stats['mid'], 'color': 'green', 'y_label': 80},
            {'value': stats['high'], 'color': 'red', 'y_label': 120},
            {'value': stats['max'], 'color': 'gray', 'y_label': 180},
        ]
        if not self.options['color']:
            lines = [
                {'value': 0, 'color': 'gray', 'y_label': 180},
                {'value': stats['max'], 'color': 'gray', 'y_label': 180},
            ]
        if self.options['simple']:
            lines = [{'value': stats['threshold'],
                      'color': 'gray', 'y_label': 150}]
        for line in lines:
            self.plot_value(line)

    def add_rgb(self):
        'Add RGB histogram lines.'
        if len(self.data['data'].shape) == 3:
            for channel in range(3):
                data = self.data['data']
                height = self.params['height']
                normalized_data = np.uint8(normalize(data, data.max(), 256))
                counts = np.hstack(cv.calcHist(
                    [normalized_data], [channel], None, [256], [0, 256]))
                norm_counts = normalize(counts, counts.max(), height)
                bins = np.linspace(0, self.params['width'], 256)
                locations = np.int32(np.dstack((bins, height - norm_counts)))
                color = [0] * 3
                color[channel] = 255
                if channel == 0:
                    color = (255, 128, 0)
                cv.polylines(self.histogram, [locations], False, color, 2)

    def calculate_bins(self, data):
        'Generate histogram data.'
        x_range = (self.params['min'], self.params['max'])
        return np.histogram(data, self.params['bin_count'], x_range)

    def generate(self):
        'Make histogram.'
        if self.options['simple']:
            counts, bins = self.calculate_bins(self.data['data'])
            self.generate_text_histogram(counts, bins)
            self.plot_bins(counts, bins, counts.max())
            self.plot_lines()
            self.add_rgb()
            return
        counts, bins = self.calculate_bins(self.data['mid'])
        all_counts, all_bins = self.calculate_bins(self.data['data'])
        self.generate_text_histogram(all_counts, all_bins)
        threshold = self.stats['threshold']
        if threshold is None:
            max_count = all_counts.max()
        else:
            filtered_counts = all_counts[all_bins[:-1] > threshold]
            max_count = filtered_counts.max() if len(filtered_counts) > 0 else 0
        self.plot_bins(all_counts, bins, max_count, COLORS['light_red'])
        self.plot_bins(counts, bins, max_count)
        params = self.params
        if self.options['color']:
            bins = np.linspace(params['min'], params['max'], params['width'])
            norm = NormalDist(mu=self.stats['mu'], sigma=self.stats['sigma'])
            counts = np.array([norm.pdf(b) for b in bins])
            self.plot_bins(counts, bins, counts.max(), fill=False)
        self.plot_lines()
        self.plot_text(self.params['title'], (int(params['width'] / 2), 20), 1)

    def generate_text_histogram(self, counts, bins):
        'Generate histogram text data.'
        hist_data = []
        normalized_counts = normalize(counts, counts.max(), 100)
        for bin_val, count, normalized in zip(bins, counts, normalized_counts):
            bin_end = bin_val + bins[1] - bins[0]
            bin_str = f'{count / self.data["data"].size * 100:>5.1f}% '

            def _bin_label(label, value):
                return f' {label}={value}' if bin_val <= value <= bin_end else ''
            bin_str += '=' * normalized
            for key in ['threshold', 'low', 'mid', 'high', 'max']:
                if self.stats[key] is None:
                    continue
                bin_str += _bin_label(key, self.stats[key])
            for i, record in enumerate(self.reduced['history'][::-1]):
                if i == 0:
                    continue
                for key in ['low', 'mid', 'high']:
                    bin_str += _bin_label(f'{key}_{i}', record['stats'][key])
            hist_data.append(f'{bin_val:6.1f} {bin_end:6.1f}: {bin_str}')
        self.reduced['histogram'] = hist_data
