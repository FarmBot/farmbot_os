#!/usr/bin/env python

"""Custom log message wrapper for Plant Detection."""

try:
    from farmware_tools import device
    USE_FARMWARE_TOOLS = True
except ImportError:
    from plant_detection import CeleryPy
    USE_FARMWARE_TOOLS = False


def log(message, message_type='info', title='plant-detection', channels=None,
        no_prefix=False):
    """Send a log message with a title prefix."""
    log_message = '[{title}] {message}'.format(title=title, message=message)
    if no_prefix:
        log_message = message
    if USE_FARMWARE_TOOLS:
        device.log(log_message, message_type, channels)
    else:
        print(CeleryPy.send_message(log_message, message_type, channels))
