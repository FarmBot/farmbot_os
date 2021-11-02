'Farmware Tools imports.'

import os
from .device import log, get_bot_state, set_user_env
from .app import request
from .auxiliary import snake_case
from .env import Env

with open(os.path.join(os.path.dirname(__file__), 'VERSION')) as version_file:
    VERSION = version_file.read().strip()

__version__ = VERSION


def get_config_value(farmware_name, config_name, value_type=int,
                     _get_state=get_bot_state):
    """Get the value of a Farmware config input.

    If not found, attempt to use the default value.

    Args:
        farmware_name (str): Name of the Farmware.
        config_name (str): Farmware input name.
    """
    namespaced_config = '{}_{}'.format(snake_case(farmware_name), config_name)

    # Try to determine the default value for the config in two steps.
    # If a default value isn't found in either step, assume the config value
    # has been set (will result in a KeyError if it hasn't).

    # Step 1. Search for config data.
    try:  # to retrieve Farmware manifest data
        manifest = _get_state()['process_info']['farmwares'][farmware_name]
    except KeyError:
        log('Farmware manifest for `{}` not found.'.format(farmware_name), 'warn')
        return value_type(os.environ[namespaced_config])
    else:  # Found config data.
        v2 = Env().use_v2() or Env().use_mqtt()
        configs = manifest['config'].values() if v2 else manifest['config']

    # Step 2. Search for the config name.
    try:  # to retrieve default config value
        [default] = [c['value'] for c in configs if c['name'] == config_name]
    except ValueError:
        log('Config name `{}` not found.'.format(config_name), 'warn')
        return value_type(os.environ[namespaced_config])

    # Determined the default value.
    # Search for a set value.
    try:  # to retrieve set config value
        value = value_type(os.environ[namespaced_config])
    except KeyError:
        log('Using the default value for `{}`.'.format(config_name))
        value = default
    return value_type(value)


def set_config_value(farmware_name, config_name, value):
    """Set the value of a Farmware config using the Farmware's namespace.

    Args:
        farmware_name (str): Name of the Farmware.
        config_name (str): Farmware input name.
        value: Value to set.
    """
    namespaced_config = '{}_{}'.format(snake_case(farmware_name), config_name)
    set_user_env(namespaced_config, value)
