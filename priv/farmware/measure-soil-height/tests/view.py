#!/usr/bin/env python3.8

'''View garden depth measurement results in 3D.

This process is resource intensive. For a full garden scan it requires:
 * ~200MB disk space for Python packages
 * ~8GB RAM
 * ~2GB disk space for data files
'''

import os
import sys
import json
from time import time
START = time()
print('loading imports...')
if START:
    try:
        import numpy as np
        import cv2 as cv
        import open3d as o3d
        from tests.account import bold_text
    except ModuleNotFoundError:
        print('Open3D package and dependencies required.')
        print('Try `python3.8 -m pip install -r tests/requirements.txt`')
        sys.exit(1)
IMPORT_LOAD_TIME = time() - START

DEBUG_LOGS = False
if DEBUG_LOGS:
    CM = o3d.utility.VerbosityContextManager(o3d.utility.VerbosityLevel.Debug)
else:
    CM = open('/dev/null')


def _read_responses_file():
    with open('responses.json', 'r') as responses_file:
        return json.load(responses_file)


def _write_responses_file(responses):
    with open('responses.json', 'w') as responses_file:
        responses_file.write(json.dumps(responses, indent=2))


def load_response(key):
    'Load input prompt responses.'
    if os.path.exists('responses.json'):
        responses = _read_responses_file()
        return responses.get(key, '')
    _write_responses_file({})
    return ''


def update_response(key, value):
    'Save input prompt responses.'
    responses = _read_responses_file()
    responses[key] = value
    _write_responses_file(responses)


def confirm_once():
    'Require review of warning to proceed.'
    if load_response('proceed'):
        return
    msg = 'Depending on the amount of data, these next steps may'
    msg += ' take several minutes and gigabyes of memory and disk space.'
    msg += ' Proceed? (y/N) '
    response = input(bold_text(msg))
    if 'y' not in response.lower():
        print('exiting...')
        sys.exit(0)
    update_response('proceed', True)


def get_input(key):
    'Prompt for input.'
    previous = load_response(key)
    if 'use_previous_response' in sys.argv:
        return previous
    input_selection_raw = input(bold_text(f'{key} ({previous}): '))
    input_selection = input_selection_raw.strip() or previous
    if input_selection != previous:
        update_response(key, input_selection)
    return input_selection


EXTENSIONS = {
    'state': 'json',
    'settings': 'json',
    'depth': 'png',
    'color': 'png',
    'points': 'xyzrgb',
    'chosen_points': 'xyzrgb',
    'points_simplified': 'xyzrgb',
    'mesh': 'ply',
}

DEFAULT_SETTINGS = {
    'every_sqrt_n_points': 4,
    'flip': {'lr': False, 'ud': True},
    'rotate90': True,
    'mm_per_pixel': 1,
    'blend': False,
    'normals': True,
    'downsample': False,
    'crop_low_values': True,
    'remove_outliers': True,
    'mesh_simplification': 1024,
    'top_n_mesh_clusters': 10,
    'color': False,
    'calculate_plane': False,
    'crop_to_plane': False,
    'subdivisions': 0,
    'z_exaggeration': 1,
    'blend_alpha': 0.65,
    'chosen_downsample': 10,
    'chosen_plate_height': 5,
    'value_minimum': 50,
}

INITIAL_STATE = {
    'steps': {
        'import': {'label': 'Load packages', 'time': None},
        'load': {'label': 'Load data', 'time': None},
        'stitch': {'label': 'Stitch photos', 'time': None},
        'points': {'label': 'Generate point file', 'time': None},
        'simplify': {'label': 'Simplify point cloud', 'time': None},
        'view point cloud': {'label': 'View point cloud', 'time': None},
        'mesh': {'label': 'Generate mesh', 'time': None},
        'view mesh': {'label': 'View mesh', 'time': None},
    },
    'stitch_ok': False,
}


def folder_path(title):
    'Add folder to path.'
    return os.path.join('tests', 'view', title)


class View():
    'Combine and view results.'

    def __init__(self, load_time, data_files=None):
        self.state = INITIAL_STATE
        self.state['steps']['import']['time'] = load_time
        self.print_status('load')
        self.title = ''
        self.data_files = data_files or []
        self.load_data_files()
        folder = folder_path(self.title)
        if not os.path.exists(folder):
            os.makedirs(folder)
        self.filenames = {name: f'{self.filepath(name)}.{ext}'
                          for name, ext in EXTENSIONS.items()}
        self.filenames['points'] = f'{folder}/points'
        self.filenames['points_simplified'] = (
            f'{folder}/points_simplified')
        self.load_state()
        self.settings = {}
        self.load_settings()
        self.data = []
        start = time()
        self.angle = 0
        self.prepare_data()
        self.update_status('load', time() - start)
        self.pcd = None

    def filepath(self, filename):
        'Create file path from name.'
        return os.path.join(folder_path(self.title), filename)

    def load_data_files(self):
        'Load data files.'
        results_dir = 'results'
        data_directory = os.path.join(results_dir, '../tests/output')

        def _get_data_filenames(results_file):
            with open(os.path.join(data_directory, results_file), 'r') as f:
                results = json.load(f)
            if len(results) < 1:
                return []
            return [f.get('data_file', '') for f in np.hstack(results)]

        if len(self.data_files) > 0:
            filename = self.data_files[0].split('/')[-1].split('output_')[1]
            self.title = filename.split('.')[0]
            files = _get_data_filenames(self.data_files[0])
            self.data_files = [os.path.join(results_dir, f) for f in files]
            self.maybe_clear_combined_result_data(True)
            return

        data_file_list = []
        files = [f for f in os.listdir(results_dir) if f.endswith('.npz')]
        data_file_list.append({'name': 'results/', 'count': len(files)})
        data_file_list.append({'name': '[specify file]', 'count': len(files)})
        for f_name in sorted(os.listdir(data_directory)):
            data_files = _get_data_filenames(f_name)
            matches = set(data_files) & set(files)
            if len(matches) < 1:
                continue
            data_file_list.append({'name': f_name, 'count': len(matches)})
        for i, file_info in enumerate(data_file_list):
            name = file_info['name']
            count = file_info['count']
            print(f' {i:>3}  {name}  ({count} data files)')
        data_selection = int(get_input('select data'))
        results_filename = data_file_list[data_selection]['name']
        if data_selection == 0:
            self.title = 'results'
            files = [f for f in os.listdir(results_dir) if f.endswith('.npz')]
        elif data_selection == 1:
            self.title = get_input('run name')
            files = [f for f in os.listdir(results_dir)
                     if f.endswith('.npz') and f.startswith(self.title)]
        else:
            self.title = results_filename.split('output_')[1].split('.')[0]
            files = _get_data_filenames(results_filename)
        self.data_files = [os.path.join(results_dir, f) for f in files]

        self.maybe_clear_combined_result_data()

    def load_state(self):
        'Load project state.'
        if not os.path.exists(self.filenames['state']):
            self.save_state()
            return
        with open(self.filenames['state'], 'r') as f:
            self.state = json.load(f)
        for key in ['view point cloud', 'view mesh']:
            self.state['steps'][key]['time'] = None

    def save_state(self):
        'Save project state.'
        with open(self.filenames['state'], 'w') as f:
            f.write(json.dumps(self.state, indent=2))

    def maybe_clear_combined_result_data(self, force=False):
        'Delete all generated data.'
        folder = folder_path(self.title)
        if (force or 'clear' in sys.argv) and os.path.exists(folder):
            for filename in os.listdir(folder):
                filepath = f'{folder}/{filename}'
                if os.path.isdir(filepath):
                    for f_name in os.listdir(filepath):
                        os.remove(f'{folder}/{filename}/{f_name}')
                    os.removedirs(filepath)
                elif filename != 'settings.json':
                    os.remove(filepath)

    def load_settings(self):
        'Load settings.'
        if not os.path.exists(self.filenames['settings']):
            self.settings = DEFAULT_SETTINGS
        else:
            with open(self.filenames['settings'], 'r') as settings_file:
                self.settings = json.load(settings_file)
            for key, value in DEFAULT_SETTINGS.items():
                if self.settings.get(key) is None:
                    self.settings[key] = value
        with open(self.filenames['settings'], 'w') as settings_file:
            settings_file.write(json.dumps(self.settings, indent=2))
        mesh_setting = str(self.settings['mesh_simplification'])
        if mesh_setting not in self.filenames['mesh']:
            self.filenames['mesh'] = self.filenames['mesh'].replace(
                '.', f'_{mesh_setting}.')

    def print_status(self, next_step=None):
        'Print steps completed.'
        print('-' * 100)
        for step, step_data in self.state['steps'].items():
            duration = ''
            if step_data['time'] is not None:
                if step_data['time'] < 0:
                    duration = 'DONE'
                    if step == 'stitch' and not self.state['stitch_ok']:
                        duration = ''
                else:
                    duration = f'{step_data["time"]:>.1f}s'
            count = ''
            if step_data.get('count') is not None and step_data['count'] > 1:
                count = f'x{step_data["count"]}'
            active = '' if step != next_step else '>'
            label = step_data['label']
            print(f' {duration:>8} {count:<3} {active:>1} {label}')
        print('-' * 100)

    def update_status(self, key, duration, count=1):
        'Update steps completed.'
        steps = self.state['steps']
        if steps[key]['time'] is None or steps[key]['time'] < 0:
            steps[key]['time'] = duration
        if count > 1:
            steps[key]['count'] = count
        self.save_state()
        completed = [s for s in steps.values() if s['time'] is not None]
        keys = list(steps.keys())
        next_key_index = keys.index(key) + 1
        last_step = next_key_index >= len(keys)
        all_done = last_step or len(completed) == len(keys)
        next_key = None if last_step else keys[next_key_index]
        most_recently_done = last_step or steps[next_key]['time'] is None
        if key == 'load' or (most_recently_done and not (all_done and key != 'mesh')):
            self.print_status(None if all_done else next_key)

    def prepare_data(self):
        'Prepare input data.'
        self.data = []
        for data_filename in self.data_files:
            if not os.path.exists(data_filename):
                continue
            with open(data_filename, 'rb') as data_file:
                data = np.load(data_file, allow_pickle=True)
                loaded = {key: data[key] for key in data.files}
                loaded['location'] = loaded['location'].tolist()
                loaded['calibration'] = loaded['calibration'].tolist()
                loaded['filename'] = data_filename.split('/')[-1]
                self.data.append(loaded)

        self.angle = np.median([d['angle'] for d in self.data])

        mm_per_pixel = self.data[0]['mm_per_pixel']
        if mm_per_pixel == 0 or self.settings['mm_per_pixel'] != 1:
            mm_per_pixel = self.settings['mm_per_pixel']

        matrix = cv.getRotationMatrix2D((0, 0), -self.angle, 1)[:, :2]
        xys = np.array([[d['location']['x'], d['location']['y']]
                        for d in self.data])
        starting_coordinate = np.array([np.dot(matrix, xy)
                                        for xy in xys]).min(0)

        for data in self.data:
            adjusted = {'depth': np.array([]), 'color': np.array([])}
            for key in adjusted.keys():
                img = data[key].copy()
                if self.settings['rotate90']:
                    img = np.rot90(img)
                if self.settings['flip']['lr']:
                    img = np.fliplr(img)
                if self.settings['flip']['ud']:
                    img = np.flipud(img)
                adjusted[key] = img
            data['adjusted'] = adjusted

        for data in self.data:
            height, width = data['adjusted']['depth'].shape[:2]
            data['height'] = height
            data['width'] = width
            xy = np.array([data['location']['x'], data['location']['y']])
            xy = (np.dot(matrix, xy) - starting_coordinate) / mm_per_pixel
            data['xy'] = xy
            data['calculate_z'] = self.calculate_z(data['calibration'],
                                                   data['location']['z'])
            data['chosen_z'] = data['calculate_z'](data['chosen_depth'])

    def calculate_z(self, calibration, z_location):
        'Calculate z coordinate from depth data.'
        def _calc_z(depth):
            disparity_offset = calibration['calibration_disparity_offset']
            calibration_factor = calibration['calibration_factor']
            measured_distance = calibration['measured_distance']

            def _c(_depth):
                disparity_delta = _depth - disparity_offset
                distance = measured_distance - disparity_delta * calibration_factor
                return z_location - distance
            return abs(_c(-16)) + _c(depth)
        return _calc_z

    def stitch(self):
        'Stitch together input images.'
        side = max(self.data[0]['depth'].shape[:2])
        end = np.array([d['xy'] for d in self.data]).max(0)
        canvas_width = int(end[0] + side)
        canvas_height = int(end[1] + side)

        def new_canvas(color=False):
            shape = [canvas_height, canvas_width]
            if color:
                shape += [3]
            return np.zeros(shape)

        canvas = {
            'depth': new_canvas(),
            'color': new_canvas(color=True),
        }

        if self.settings['blend']:
            print('_' * len(self.data))

        for data in self.data:
            if self.settings['blend']:
                print('|', end='', flush=True)
            x, y = data['xy'].astype(int)
            y_end = y + data['height']
            x_end = x + data['width']
            for key in data['adjusted'].keys():
                image = data['adjusted'][key]
                if self.settings['blend']:
                    color = key == 'color'
                    img = new_canvas(color)
                    img[y:y_end, x:x_end] = image
                    alpha = self.settings['blend_alpha']
                    img = cv.addWeighted(img, alpha, canvas[key], 1 - alpha, 0)
                    add = img[y:y_end, x:x_end]
                else:
                    add = image
                canvas[key][y:y_end, x:x_end] = add
        print()

        for key in self.data[0]['adjusted'].keys():
            center = canvas_width // 2, canvas_height // 2
            matrix = cv.getRotationMatrix2D(center, self.angle, 1)
            shape = (canvas_width, canvas_height)
            image = cv.warpAffine(canvas[key], matrix, shape)
            cv.imwrite(self.filenames[key], image)

    def maybe_combine_images(self):
        'Stitch images.'
        if not self.state['stitch_ok']:
            count = 0
            while True:
                count += 1
                print('combining images...')
                start = time()
                self.stitch()
                duration = time() - start
                filename = self.filenames['color']
                print(f'{filename} created in {duration:.1f} seconds.')
                if 'use_previous_response' not in sys.argv:
                    settings_filename = self.filenames['settings']
                    print(f'Review and edit {settings_filename} as necessary.')
                    response = input(bold_text('Does it look ok? (y/N) '))
                if 'use_previous_response' in sys.argv or 'y' in response.lower():
                    self.state['stitch_ok'] = True
                    break
                self.load_settings()
                self.prepare_data()
            self.update_status('stitch', duration, count)
        else:
            self.update_status('stitch', -1)

    def get_point_file_name(self, data, simplified=False):
        'Return point data filepath.'
        point_dir = self.filenames['points']
        if simplified:
            point_dir += '_simplified'
        name = data['filename'].split('_data.npz')[0]
        extension = EXTENSIONS['points']
        return f'{point_dir}/{name}.{extension}'

    def generate_point_data(self):
        'Generate xyzrgb point data.'
        print('_' * len(self.data))
        for data in self.data:
            print('|', end='', flush=True)
            with open(self.get_point_file_name(data), 'w') as f:
                f.write(self.add_points(data))
        print()

    def add_points(self, data, point_file_data='', **kwargs):
        'Add xyzrgb points to file data string.'
        depth = data['adjusted']['depth']
        if kwargs.get('rgb') is None:
            rgb = data['adjusted']['color'][:, :, ::-1] / 255
        step = kwargs.get('step', self.settings['every_sqrt_n_points'])
        for k in range(0, len(depth), step):
            z_s = depth[k]
            if kwargs.get('rgb') is None:
                c_s = rgb[k]
            for j in range(0, len(z_s), step):
                x = data['xy'][0] + j
                y = data['xy'][1] + k
                z = z_s[j] if kwargs.get('z') is None else kwargs.get('z')
                z = data['calculate_z'](z) * self.settings['z_exaggeration']
                c = c_s[j] if kwargs.get('rgb') is None else kwargs.get('rgb')
                r, g, b = c
                point_file_data += f'{x} {y} {z} {r:.10f} {g:.10f} {b:.10f}\n'
        return point_file_data

    def run(self):
        'Process data and view the result.'
        self.maybe_combine_images()

        if not os.path.exists(self.filenames['points']):
            start = time()
            os.mkdir(self.filenames['points'])
            self.generate_point_data()
            self.update_status('points', time() - start)
        else:
            self.update_status('points', -1)

        self.maybe_simplify_cloud()
        chosen_pcd, chosen_mesh = self.create_chosen_surface()

        capture_dir = f'{folder_path(self.title)}/captures'
        if not os.path.exists(capture_dir):
            os.mkdir(capture_dir)
            self.capture_visualization([self.pcd], 'captures/point_cloud_')
            self.capture_visualization([chosen_mesh], 'captures/chosen_')

        self.interactive_visualization({'pcd': self.pcd,
                                        'chosen_pcd': chosen_pcd,
                                        'chosen_mesh': chosen_mesh})
        self.update_status('view point cloud', -1)

        self.maybe_create_mesh()
        mesh = o3d.io.read_triangle_mesh(self.filenames['mesh'])
        print('loaded', mesh)
        if self.settings['normals']:
            mesh.compute_vertex_normals()

        self.interactive_visualization({'mesh': mesh,
                                        'chosen_pcd': chosen_pcd,
                                        'chosen_mesh': chosen_mesh})
        self.update_status('view mesh', -1)

    def create_chosen_surface(self):
        'Generate chosen surface point cloud and mesh.'
        if not os.path.exists(self.filenames['chosen_points']):
            chosen_point_file_data = ''
            for data in self.data:
                kwargs = {'step': self.settings['chosen_downsample'],
                          'rgb': [0, 1, 0],
                          'z': data['chosen_depth']}
                chosen_point_file_data = self.add_points(
                    data, chosen_point_file_data, **kwargs)

            with open(self.filenames['chosen_points'], 'w') as f:
                f.write(chosen_point_file_data)

        chosen_pcd = o3d.io.read_point_cloud(self.filenames['chosen_points'])
        print('chosen', chosen_pcd)
        self.rotate(chosen_pcd)

        chosen_mesh = None
        for data in self.data:
            chosen = o3d.geometry.TriangleMesh.create_box(
                width=data['width'],
                height=data['height'],
                depth=self.settings['chosen_plate_height'])
            chosen_x = data['xy'][0] + data['width'] / 2
            chosen_y = data['xy'][1] + data['height'] / 2
            chosen_z = data['chosen_z'] * self.settings['z_exaggeration']
            chosen.translate((chosen_x, chosen_y, chosen_z), relative=False)
            if chosen_mesh is None:
                chosen_mesh = chosen
            else:
                chosen_mesh += chosen
        self.rotate(chosen_mesh)
        print('chosen', chosen_mesh)

        if self.settings['subdivisions']:
            chosen_mesh.compute_vertex_normals()
            chosen_mesh = chosen_mesh.subdivide_midpoint(
                self.settings['subdivisions'])
            print('chosen', chosen_mesh)

        return chosen_pcd, chosen_mesh

    def interactive_visualization(self, geometries):
        'Open a visualization window.'
        if 'non-interactive' in sys.argv:
            return
        InteractiveVisualization(geometries).run()

    def set_color_option(self, vis, color):
        'Set geometry color option.'
        color_opt = {
            'point': {
                'color': o3d.visualization.PointColorOption.Color,
                'depth': o3d.visualization.PointColorOption.ZCoordinate,
            },
            'mesh': {
                'color': o3d.visualization.MeshColorOption.Color,
                'depth': o3d.visualization.MeshColorOption.ZCoordinate,
            }
        }
        opt = vis.get_render_option()
        opt.point_color_option = color_opt['point'][color]
        opt.mesh_color_option = color_opt['mesh'][color]

    def capture_visualization(self, geometries, name):
        'Save image capture of geometry visualization.'
        filename = self.filepath(name)
        vis = o3d.visualization.Visualizer()
        vis.create_window(visible=False)
        for geometry in geometries:
            vis.add_geometry(geometry)
        opt = vis.get_render_option()
        opt.mesh_show_back_face = True
        opt.background_color = [0, 0, 0]
        ctr = vis.get_view_control()
        ctr.change_field_of_view(step=-100)
        ctr.set_zoom(0.5)
        for i in range(3):
            front = [0] * 3
            front[i] = -1 if i == 1 else 1
            ctr.set_front(front)
            up = [0, 1, 0] if i == 2 else [0, 0, 1]
            ctr.set_up(up)
            for color in ['color', 'depth']:
                self.set_color_option(vis, color)
                for geometry in geometries:
                    vis.update_geometry(geometry)
                vis.poll_events()
                vis.update_renderer()
                vis.capture_screen_image(f'{filename}{i}_{color}.png')
        vis.destroy_window()

    def rotate(self, geometry):
        'Rotate geometry.'
        rotation_matrix = geometry.get_rotation_matrix_from_xyz(
            (0, 0, -self.angle * (np.pi / 180)))
        geometry.rotate(rotation_matrix, center=(0, 0, 0))

    def maybe_simplify_cloud(self):
        'Crop and remove outliers from point cloud.'
        if not os.path.exists(self.filenames['points_simplified']):
            confirm_once()
            print('simplifying point cloud...')
            start = time()
            os.mkdir(self.filenames['points_simplified'])
            for data in self.data:
                filename = self.get_point_file_name(data)
                pcd = o3d.io.read_point_cloud(filename)

                if self.settings['downsample']:
                    pcd = pcd.uniform_down_sample(
                        every_k_points=self.settings['downsample'])

                if self.settings['crop_low_values']:
                    pts = np.asarray(pcd.points)
                    index = np.arange(len(pts))
                    ind = index[pts[:, 2] > self.settings['value_minimum']]
                    pcd = pcd.select_by_index(ind)

                if self.settings['remove_outliers']:
                    _, ind = pcd.remove_statistical_outlier(
                        nb_neighbors=30, std_ratio=0.8)
                    pcd = pcd.select_by_index(ind)

                if self.settings['calculate_plane'] or self.settings['crop_to_plane']:
                    plane_model, inliers = pcd.segment_plane(
                        distance_threshold=30, ransac_n=3, num_iterations=100)
                    a, b, c, d = plane_model
                    plane_x, plane_y = data['xy']
                    plane_z = -(d + a * plane_x + b * plane_y) / c
                    chosen_z = data['chosen_depth']
                    plane_mid = f'({plane_x:.1f}, {plane_y:.1f}, {plane_z:.1f})'
                    z_diff = plane_z - chosen_z
                    compare_z = f'chosen z = {chosen_z:.1f}, diff = {z_diff:.1f}'
                    print(f'{plane_mid:>30}, {compare_z})')
                    if self.settings['crop_to_plane']:
                        pcd = pcd.select_by_index(inliers)

                self.rotate(pcd)

                filename = self.get_point_file_name(data, simplified=True)
                o3d.io.write_point_cloud(filename, pcd)
            duration = time() - start
            folder = self.filenames['points_simplified']
            print(f'{folder} generated in {duration:.1f} seconds.')
            self.update_status('simplify', duration)
        else:
            self.update_status('simplify', -1)

        for data in self.data:
            filename = self.get_point_file_name(data, simplified=True)
            pcd = o3d.io.read_point_cloud(filename)
            if self.pcd is None:
                self.pcd = pcd
            self.pcd += pcd
        print('loaded', self.pcd)

    def maybe_create_mesh(self):
        'Create mesh from point cloud.'
        if not os.path.exists(self.filenames['mesh']):
            print('generating mesh...')
            start = time()
            self.pcd.normals = o3d.utility.Vector3dVector(np.zeros((1, 3)))
            self.pcd.estimate_normals()
            with CM:
                create_mesh = o3d.geometry.TriangleMesh.create_from_point_cloud_poisson
                mesh, densities = create_mesh(self.pcd, depth=11)
                remove = densities < np.quantile(densities, 0.1)
                mesh.remove_vertices_by_mask(remove)
            print('generated', mesh)

            if self.settings['mesh_simplification']:
                mesh_resolution = self.settings['mesh_simplification']
                voxel_size = max(
                    mesh.get_max_bound() -
                    mesh.get_min_bound()) / mesh_resolution
                method = o3d.geometry.SimplificationContraction.Average
                mesh = mesh.simplify_vertex_clustering(
                    voxel_size=voxel_size, contraction=method)
                print('after simplification:', mesh)

            top_n = self.settings['top_n_mesh_clusters']
            if top_n:
                cluster_idx, cluster_size, _area = mesh.cluster_connected_triangles()
                small_cluster_ind = np.asarray(cluster_size).argsort()[:-top_n]
                remove = np.isin(np.asarray(cluster_idx), small_cluster_ind)
                mesh.remove_triangles_by_mask(remove)
                print('after main mesh selection:', mesh)

            filename = self.filenames['mesh']
            o3d.io.write_triangle_mesh(filename, mesh)
            duration = time() - start
            print(f'{filename} generated in {duration:.1f} seconds.')
            self.update_status('mesh', duration)
        else:
            self.update_status('mesh', -1)


class InteractiveVisualization():
    'Visualization window.'

    def __init__(self, geometries):
        self.geometries = geometries
        self.view = 'top'
        self.included = list(geometries.keys())[:1]
        self.section = {
            'enabled': False,
            'other_axis': False,
            'value': round(list(geometries.values())[0].get_max_bound()[1] / 2),
            'width': 50,
        }

    def set_view(self, key):
        'Change to top or front view.'
        def _view(vis):
            ctr = vis.get_view_control()
            front = {'front': [0, -1, 0], 'side': [1, 0, 0], 'top': [0, 0, 1]}
            up = [0, 1, 0] if key == 'top' else [0, 0, 1]
            ctr.set_front(front[key])
            ctr.set_up(up)
            self.view = key
        return _view

    def set_field_of_view(self, vis, fov):
        'Set field of view.'
        ctr = vis.get_view_control()
        current = ctr.get_field_of_view()
        ctr.change_field_of_view(fov - current)

    def toggle_geometry(self, key):
        'Show/hide geometries.'
        def _toggle(vis):
            ctr = vis.get_view_control()
            fov = ctr.get_field_of_view()
            if key in self.included:
                if len(self.included) < 2:
                    print('View must include at least one geometry.')
                    return
                vis.remove_geometry(self.geometries[key])
                self.included.remove(key)
            else:
                vis.add_geometry(self.geometries[key])
                self.included.append(key)
            self.set_field_of_view(vis, fov)
        return _toggle

    def get_crop_box(self, geometry):
        'Get cross section crop volume from geometry.'
        min_bound = geometry.get_min_bound()
        max_bound = geometry.get_max_bound()
        pts = np.array([min_bound, min_bound, max_bound])
        width_index = 0 if self.section['other_axis'] else 1
        pts[:, width_index] = self.section['value']
        pts[1, width_index] = self.section['value'] + self.section['width']
        pts = o3d.utility.Vector3dVector(pts)
        crop = o3d.geometry.AxisAlignedBoundingBox.create_from_points(pts)
        crop.color = [1, 1, 1]
        return crop

    def crop_to_section(self):
        'Crop geometries to cross section.'
        def _crop(vis):
            ctr = vis.get_view_control()
            fov = ctr.get_field_of_view()
            vis.clear_geometries()
            crop_box = self.get_crop_box(list(self.geometries.values())[0])
            vis.add_geometry(crop_box)
            for key in self.included:
                geometry = self.geometries[key]
                cropped = geometry.crop(self.get_crop_box(geometry))
                self.section['enabled'] = True
                vis.add_geometry(cropped)
            self.set_view(self.view)(vis)
            self.set_field_of_view(vis, fov)
        return _crop

    def toggle_section(self):
        'Toggle cross section view.'
        def _toggle(vis):
            if self.section['enabled']:
                ctr = vis.get_view_control()
                fov = ctr.get_field_of_view()
                vis.clear_geometries()
                for key in self.included:
                    vis.add_geometry(self.geometries[key])
                self.section['enabled'] = False
                self.set_field_of_view(vis, fov)
            else:
                self.crop_to_section()(vis)
        return _toggle

    def step_section(self, direction):
        'Step cross section forward or backward.'
        def _step(vis):
            self.section['value'] += direction * self.section['width']
            self.section['value'] = round(self.section['value'])
            print(self.section['value'])
            self.crop_to_section()(vis)
        return _step

    def switch_section_axis(self):
        'Switch cross section axis.'
        def _switch(vis):
            self.section['other_axis'] = not self.section['other_axis']
            self.crop_to_section()(vis)
        return _switch

    def run(self):
        'Open viewer window.'
        vis = o3d.visualization.VisualizerWithKeyCallback()
        vis.create_window()
        key_callbacks = {
            ord('F'): self.set_view('front'),
            ord('G'): self.set_view('side'),
            ord('U'): self.set_view('top'),
            ord('X'): self.toggle_section(),
            ord('6'): self.toggle_geometry('chosen_pcd'),
            ord('8'): self.toggle_geometry('chosen_mesh'),
            ord('.'): self.step_section(1),
            ord(','): self.step_section(-1),
            ord('Z'): self.switch_section_axis(),
        }
        if 'pcd' in self.geometries.keys():
            key_callbacks[ord('5')] = self.toggle_geometry('pcd')
        if 'mesh' in self.geometries.keys():
            key_callbacks[ord('7')] = self.toggle_geometry('mesh')
        for key, callback in key_callbacks.items():
            vis.register_key_callback(key, callback)
        for key in self.included:
            vis.add_geometry(self.geometries[key])
        opt = vis.get_render_option()
        opt.mesh_show_back_face = True
        opt.background_color = [0, 0, 0]
        vis.run()


if __name__ == '__main__':
    view = View(IMPORT_LOAD_TIME)
    view.run()
