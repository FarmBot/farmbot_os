#!/usr/bin/env python3.8

'Generate simple plot.'

import numpy as np
import cv2 as cv

WHITE = (255, 255, 255)
FONT = cv.FONT_HERSHEY_PLAIN


class Plot():
    'Generate simple plot.'

    def __init__(self, core):
        self.settings = core.settings.settings
        self.results = core.results
        self.plot = np.zeros((1000, 1000), dtype=np.uint8)
        height, width = self.plot.shape[:2]
        self.shape = {'width': width, 'height': height}
        self.intercept = 0
        self.slope = 0
        self.values = {'x': None, 'y': None}

    def _loc_from_percent(self, percent_x, percent_y):
        return (int(self.shape['width'] * percent_x / 100.),
                int(self.shape['height'] * (100 - percent_y) / 100.))

    def add_text(self, text,
                 percent_x=None, percent_y=None,
                 position_x=None, position_y=None):
        'Add text to plot.'
        from_percent = self._loc_from_percent(percent_x or 0, percent_y or 0)
        height = self.shape['height']
        y_from_top = 0 if position_y is None else (height - position_y)
        loc = (position_x or from_percent[0], y_from_top or from_percent[1])
        self.plot = cv.putText(self.plot, str(text), loc, FONT, 1, WHITE, 1)

    def _add_x_axis_labels(self, label, offset=0, divisor=1, precision=0):
        def _v(value):
            display_value = round(value / divisor, precision)
            if precision == 0:
                display_value = int(display_value)
            return display_value
        x_values = self.values['x']
        add_text = self.add_text
        percent_y = 1 + 2 * offset
        alternate = len(x_values) > 1 and (max(x_values) - min(x_values)) < 33
        add_text(label, 50, 6 + percent_y)
        if alternate:
            add_text(label, 50, 100 - (6 + percent_y))
        add_text(_v(1000), 95, percent_y)
        x_intercept = -int(self.intercept / self.slope)
        for i, x_value in enumerate((x_values + [x_intercept])[::-1]):
            if i > 0:
                percent_y = (99 - percent_y) if alternate else percent_y
            add_text(_v(x_value), position_x=int(x_value), percent_y=percent_y)

    def add_labels(self):
        'Add labels to plot.'
        # Origin
        self.add_text(0, 1, 1)

        # X axis
        self._add_x_axis_labels('disparity')
        self._add_x_axis_labels('pixels', 1, 16, 1)
        mm_per_pixel = self.settings['millimeters_per_pixel']
        if mm_per_pixel:
            self._add_x_axis_labels('mm', 2, 16 / mm_per_pixel, 1)

        # Y axis
        self.add_text('distance (mm)', 1, 50)
        self.add_text(1000, 1, 97)
        for y_value in self.values['y'] + [self.intercept]:
            self.add_text(int(y_value), 1, position_y=int(y_value))

        # Legend
        self.add_text('calculated', 90, 90)
        calculated = self._loc_from_percent(88, 90)
        self.plot = cv.circle(self.plot, calculated, 10, WHITE, 1)
        self.add_text('expected', 90, 85)
        expected = self._loc_from_percent(88, 85)
        self.plot = cv.circle(self.plot, expected, 5, WHITE, 2)

    def line(self, slope, intercept, thickness=1):
        'Add line to plot.'
        self.intercept = intercept
        self.slope = slope
        start = (0, int(intercept))
        width = self.shape['width']
        end = (width, int(width * slope + intercept))
        self.plot = cv.line(self.plot, start, end, WHITE, thickness)

    def points(self, x_values, y_values, size=5, thickness=1):
        'Add points to plot.'
        self.values['x'] = x_values
        self.values['y'] = y_values
        for x_value, y_value in zip(x_values, y_values):
            point = (int(x_value), int(y_value))
            self.plot = cv.circle(self.plot, point, size, WHITE, thickness)

    def save(self, name):
        'Save plot to file.'
        self.plot = np.flipud(self.plot).astype(np.uint8)
        self.add_labels()
        self.results.save_image(name, self.plot)
