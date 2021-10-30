#!/usr/bin/env python3.8

'Reduce data.'

import json
from copy import deepcopy
import numpy as np


class ReduceData():
    'Reduce data.'

    def __init__(self, core, data, info, **kwargs):
        self.data = data
        self.info = info
        self.core = core
        self.settings = core.settings.settings
        self.log = core.log
        self.reduced = {'masks': {}, 'stats': {}, 'history': []}
        self.report = None
        self.reduce_data(**kwargs)
        self.data_content_report()

    def _add_calculated(self, mean, sigma):
        masks = self.reduced['masks']
        masks['low'] = self.data < mean - sigma
        masks['high'] = self.data > mean + sigma
        mid = (self.data > mean - sigma) * (self.data < mean + sigma)
        masks['mid'] = masks['threshold'] * mid
        stats = self.reduced['stats']
        if stats['threshold'] is None:
            stats['mu'] = mean
        else:
            stats['mu'] = max(stats['threshold'] + 1, mean)
        stats['sigma'] = sigma
        stats['low'] = round(stats['mu'] - sigma, 4)
        stats['low_size_p'] = self._percent(self.data, masks['threshold'])
        stats['mid'] = stats['mu']
        stats['mid_size_p'] = self._percent(self.data, masks['mid'])
        stats['high'] = round(stats['mu'] + sigma, 4)
        stats['high_size_p'] = self._percent(self.data, masks['high'])

        record = deepcopy(self.reduced)
        record.pop('history')
        self.reduced['history'].append(record)

    def _find_highest_bin(self, mean, sigma):
        data = self.data[np.invert(np.isnan(self.data))]
        counts, bins = np.histogram(data, bins=256)
        bins = bins[:-1]
        mid_mask = (bins > mean - sigma) * (bins < mean + sigma)
        threshold = self.reduced['stats']['threshold']
        if threshold is not None:
            mid_mask *= bins > threshold
        if not any(mid_mask):
            msg = 'No data remaining. '
            msg += f'({bins.min() = }, {bins.max() = }, mu = {mean}, {sigma = }).'
            self.log.debug(msg)
            return mean, sigma, []
        mid_bins = bins[mid_mask]
        mid_counts = counts[mid_mask]
        sorted_indexes = np.argsort(mid_counts)[::-1]
        if len(sorted_indexes) < 2:
            sorted_indexes = np.tile(sorted_indexes, 2)
        first, second = sorted_indexes[:2]
        top = [
            {'bin': mid_bins[first], 'count': mid_counts[first]},
            {'bin': mid_bins[second], 'count': mid_counts[second]},
        ]
        bin_width = bins[1] - bins[0]
        mean = round(top[0]['bin'] + bin_width / 2, 4)
        mean = top[0]['bin']
        selection_width = self.settings['selection_width']
        sigma = round(bin_width * selection_width, 4)
        return mean, sigma, top

    def _mask_stats(self, mask):
        data = self.data[mask]
        if len(data) < 1:
            return np.nan, np.nan
        mean = round(data.mean(), 4)
        sigma = round(data.std(), 4)
        return mean, sigma

    def reduce_data(self, **kwargs):
        'Calculate masks and stats for data.'
        masks = self.reduced['masks']
        masks['all'] = np.full(self.data.shape, True)
        masks['none'] = self.data < 0
        no_threshold = kwargs.get('no_threshold', False)
        threshold = None if no_threshold else self.settings['pixel_value_threshold']
        masks['threshold'] = masks['all'] if threshold is None else (
            self.data > threshold)
        stats = self.reduced['stats']
        stats['threshold'] = threshold
        stats['thresh_size_p'] = self._percent(self.data, masks['threshold'])
        if self.data[np.invert(np.isnan(self.data))].size < 1:
            stats['max'] = np.nan
            masks['max'] = masks['all']
        else:
            stats['max'] = int(self.data[np.invert(np.isnan(self.data))].max())
            masks['max'] = self.data < stats['max']
        if self.info.get('tag') in ['angles', 'dx', 'dy']:
            mean, sigma, _ = self._find_highest_bin(mean=0, sigma=89)
            self._add_calculated(round(float(mean), 2), round(float(sigma), 2))
            return

        mean, sigma = self._mask_stats(masks['threshold'] * masks['max'])
        self._add_calculated(mean, sigma)

        calc_tags = ['disparity']
        if all([not self.info.get('tag', '').startswith(s) for s in calc_tags]):
            return

        self.log.debug('Checking bins...')
        new_mean, new_sigma, top = self._find_highest_bin(mean, sigma)
        if len(top) < 2:
            return
        if top[0]['bin'] > threshold and top[0]['count'] > 2 * top[1]['count']:
            self.log.debug(f'narrowing range: prominent bin count {top}')
            mean, sigma = new_mean, new_sigma
            self._add_calculated(mean, sigma)

        if sigma > self.settings['wide_sigma_threshold']:
            self.log.debug('narrowing range: wide deviation')
            mean, sigma = self._mask_stats(self.reduced['masks']['mid'])
            self._add_calculated(mean, sigma)
            mean, sigma, top = self._find_highest_bin(mean, sigma)
            self._add_calculated(mean, sigma)

    @staticmethod
    def _percent(data, mask):
        return round(data[mask].size / float(data.size) * 100, 2)

    def data_content_report(self):
        'Return report, percent pixels above threshold, and average pixel value.'
        stats = self.reduced['stats']
        report = f'{self.info.get("tag")}: '
        report += f'{stats["thresh_size_p"]}% > {stats["threshold"]}, '
        report += f'average value: {stats["mid"]:.0f}, '
        report += f'{stats["low"]:.0f} < {stats["mid_size_p"]}% < {stats["high"]:.0f}'
        self.report = {
            'report': report,
            'coverage': stats['thresh_size_p'],
            'low': stats['low'],
            'mid': stats['mid'],
            'high': stats['high'],
        }
        if self.settings['log_verbosity'] > 2 or self.core.settings.reports_enabled():
            data = self.data[np.invert(np.isnan(self.data))]
            low = data.min() if len(data) > 0 else np.nan
            counts = np.bincount(np.int32(data.flatten() - low))
            top_5 = np.argsort(counts)[::-1][:5]
            top_values = {'name': self.info.get('tag'), 'top_values': {}}
            for pixel_value in top_5:
                val_percent = f'{counts[pixel_value] / self.data.size * 100:.1f}%'
                top_values['top_values'][int(pixel_value + low)] = val_percent
            self.log.debug(json.dumps(top_values, indent=2))
            self.report['top_values'] = top_values
            self.report['report'] += f' top values: {top_values["top_values"]}'
