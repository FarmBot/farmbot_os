#!/usr/bin/env python
"""CeleryPy Tests

For Plant Detection.
"""
import unittest
import json
from plant_detection import CeleryPy


class CeleryScript(unittest.TestCase):
    """Check celery script"""

    def setUp(self):
        # add_point
        self.add_point = CeleryPy.add_point(
            point_x=1, point_y=2, point_z=3, point_r=4)
        self.add_point_static = {
            "kind": "add_point",
            "args": {
                "radius": 4,
                "location": {
                    "kind": "coordinate",
                    "args": {
                        "x": 1,
                        "y": 2,
                        "z": 3
                    }
                }
            },
            "body": [
                {
                    "kind": "pair",
                    "args": {
                        "label": "created_by",
                        "value": "plant-detection"
                    }
                }
            ]
        }
        # set_user_env
        self.set_env_var = CeleryPy.set_user_env(
            label='PLANT_DETECTION_options', value=json.dumps({"in": "puts"}))
        self.set_env_var_static = {
            "kind": "set_user_env",
            "args": {},
            "body": [
                {
                    "kind": "pair",
                    "args": {
                        "label": "PLANT_DETECTION_options",
                        "value": "{\"in\": \"puts\"}"
                    }
                }
            ]
        }
        # move_absolute: coordinate
        self.move_absolute_coordinate = CeleryPy.move_absolute(
            location=[10, 20, 30],
            offset=[40, 50, 60],
            speed=800)
        self.move_absolute_coordinate_static = {
            "kind": "move_absolute",
            "args": {
                "location": {
                    "kind": "coordinate",
                    "args": {
                        "x": 10,
                        "y": 20,
                        "z": 30
                    }
                },
                "offset": {
                    "kind": "coordinate",
                    "args": {
                        "x": 40,
                        "y": 50,
                        "z": 60
                    }
                },
                "speed": 800
            }
        }
        # move_absolute: tool
        self.move_absolute_tool = CeleryPy.move_absolute(
            location=['tool', 1],
            offset=[40, 50, 60],
            speed=800)
        self.move_absolute_tool_static = {
            "kind": "move_absolute",
            "args": {
                "location": {
                    "kind": "tool",
                    "args": {
                        "tool_id": 1
                    }
                },
                "offset": {
                    "kind": "coordinate",
                    "args": {
                        "x": 40,
                        "y": 50,
                        "z": 60
                    }
                },
                "speed": 800
            }
        }
        # move_absolute: plant
        self.move_absolute_plant = CeleryPy.move_absolute(
            location=['Plant', 1],
            offset=[40, 50, 60],
            speed=800)
        self.move_absolute_plant_static = {
            "kind": "move_absolute",
            "args": {
                "location": {
                    "kind": "point",
                    "args": {
                        "pointer_type": "Plant",
                        "pointer_id": 1
                    }
                },
                "offset": {
                    "kind": "coordinate",
                    "args": {
                        "x": 40,
                        "y": 50,
                        "z": 60
                    }
                },
                "speed": 800
            }
        }
        # move_absolute: point
        self.move_absolute_point = CeleryPy.move_absolute(
            location=['GenericPointer', 1],
            offset=[40, 50, 60],
            speed=800)
        self.move_absolute_point_static = {
            "kind": "move_absolute",
            "args": {
                "location": {
                    "kind": "point",
                    "args": {
                        "pointer_type": "GenericPointer",
                        "pointer_id": 1
                    }
                },
                "offset": {
                    "kind": "coordinate",
                    "args": {
                        "x": 40,
                        "y": 50,
                        "z": 60
                    }
                },
                "speed": 800
            }
        }
        # move_relative
        self.move_relative = CeleryPy.move_relative(
            distance=(100, 200, 300), speed=800)
        self.move_relative_static = {
            "kind": "move_relative",
            "args": {
                "x": 100,
                "y": 200,
                "z": 300,
                "speed": 800
            }
        }
        # data_update: all
        self.data_update = CeleryPy.data_update(endpoint='points')
        self.data_update_static = {
            "kind": "data_update",
            "args": {
                "value": "update"
            },
            "body": [
                {
                    "kind": "pair",
                    "args": {
                        "label": "points",
                        "value": "*"
                    }
                }
            ]
        }
        # data_update: one
        self.data_update_id = CeleryPy.data_update(endpoint='points', ids_=101)
        self.data_update_id_static = {
            "kind": "data_update",
            "args": {
                "value": "update"
            },
            "body": [
                {
                    "kind": "pair",
                    "args": {
                        "label": "points",
                        "value": "101"
                    }
                }
            ]
        }
        # data_update: ids
        self.data_update_list = CeleryPy.data_update(
            endpoint='points', ids_=[123, 456, 789])
        self.data_update_list_static = {
            "kind": "data_update",
            "args": {
                "value": "update"
            },
            "body": [
                {
                    "kind": "pair",
                    "args": {
                        "label": "points",
                        "value": "123"
                    }
                },
                {
                    "kind": "pair",
                    "args": {
                        "label": "points",
                        "value": "456"
                    }
                },
                {
                    "kind": "pair",
                    "args": {
                        "label": "points",
                        "value": "789"
                    }
                }
            ]
        }
        # send_message: logs
        self.send_message = CeleryPy.send_message(
            message='Hello', message_type='fun')
        self.send_message_static = {
            "kind": "send_message",
            "args": {
                "message": "Hello",
                "message_type": "fun"
            }
        }
        # send_message: toast
        self.send_message_toast = CeleryPy.send_message(
            message='Hello', message_type='fun', channel='toast')
        self.send_message_toast_static = {
            "kind": "send_message",
            "args": {
                "message": "Hello",
                "message_type": "fun"
            },
            "body": [
                {
                    "kind": "channel",
                    "args": {
                        "channel_name": "toast"
                    }
                }
            ]
        }
        # send_message: channels
        self.send_message_channels = CeleryPy.send_message(
            message='Hello', message_type='fun', channel=['toast', 'email'])
        self.send_message_channels_static = {
            "kind": "send_message",
            "args": {
                "message": "Hello",
                "message_type": "fun"
            },
            "body": [
                {
                    "kind": "channel",
                    "args": {
                        "channel_name": "toast"
                    }
                },
                {
                    "kind": "channel",
                    "args": {
                        "channel_name": "email"
                    }
                }
            ]
        }
        # find_home
        self.find_home = CeleryPy.find_home(axis='all', speed=100)
        self.find_home_static = {
            "kind": "find_home",
            "args": {
                "axis": "all",
                "speed": 100
            }
        }
        # _if: execute
        self.if_statement = CeleryPy.if_statement(
            lhs='x', op='is', rhs=0, _then=1, _else=2)
        self.if_statement_static = {
            "kind": "_if",
            "args": {
                "lhs": "x",
                "op": "is",
                "rhs": 0,
                "_then": {
                    "kind": "execute",
                    "args": {
                        "sequence_id": 1
                    }
                },
                "_else": {
                    "kind": "execute",
                    "args": {
                        "sequence_id": 2
                    }
                }
            }
        }
        # _if: nothing
        self.if_statement_nothing = CeleryPy.if_statement(
            lhs='x', op='is', rhs=0)
        self.if_statement_nothing_static = {
            "kind": "_if",
            "args": {
                "lhs": "x",
                "op": "is",
                "rhs": 0,
                "_then": {
                    "kind": "nothing",
                    "args": {}
                },
                "_else": {
                    "kind": "nothing",
                    "args": {}
                }
            }
        }
        # write_pin
        self.write_pin = CeleryPy.write_pin(number=0, value=1)
        self.write_pin_static = {
            "kind": "write_pin",
            "args": {
                "pin_number": 0,
                "pin_value": 1,
                "pin_mode": 0
            }
        }
        # read_pin
        self.read_pin = CeleryPy.read_pin(number=0, mode=0, label='pin')
        self.read_pin_static = {
            "kind": "read_pin",
            "args": {
                "pin_number": 0,
                "pin_mode": 0,
                "label": "pin"
            }
        }
        # execute_sequence
        self.execute_sequence = CeleryPy.execute_sequence(sequence_id=1)
        self.execute_sequence_static = {
            "kind": "execute",
            "args": {
                "sequence_id": 1
            }
        }
        # execute_script
        self.execute_script = CeleryPy.execute_script(label='plant-detection')
        self.execute_script_static = {
            "kind": "execute_script",
            "args": {
                "label": "plant-detection"
            }
        }
        # take_photo
        self.take_photo = CeleryPy.take_photo()
        self.take_photo_static = {
            "kind": "take_photo",
            "args": {}
        }
        # wait
        self.wait = CeleryPy.wait(milliseconds=100)
        self.wait_static = {
            "kind": "wait",
            "args": {
                "milliseconds": 100
            }
        }

    def test_add_point(self):
        """Check add_point celery script"""
        self.assertEqual(self.add_point_static, self.add_point)

    def test_set_env_var(self):
        """Check set_env_var celery script"""
        self.assertEqual(self.set_env_var_static, self.set_env_var)

    def test_move_absolute_coordinate(self):
        """Check move_absolute celery script with coordinates"""
        self.assertEqual(self.move_absolute_coordinate_static,
                         self.move_absolute_coordinate)

    def test_move_absolute_tool(self):
        """Check move_absolute celery script with a tool"""
        self.assertEqual(self.move_absolute_tool_static,
                         self.move_absolute_tool)

    def test_move_absolute_plant(self):
        """Check move_absolute celery script with a plant"""
        self.assertEqual(self.move_absolute_plant_static,
                         self.move_absolute_plant)

    def test_move_absolute_point(self):
        """Check move_absolute celery script with a location"""
        self.assertEqual(self.move_absolute_point_static,
                         self.move_absolute_point)

    def test_move_relative(self):
        """Check test_move_relative celery script"""
        self.assertEqual(self.move_relative_static,
                         self.move_relative)

    def test_data_update(self):
        """Check data_update Celery Script"""
        self.assertEqual(self.data_update_static, self.data_update)

    def test_data_update_one(self):
        """Check data_update Celery Script for one ID"""
        self.assertEqual(self.data_update_id_static, self.data_update_id)

    def test_data_update_list(self):
        """Check data_update Celery Script for a list of IDs"""
        self.assertEqual(self.data_update_list_static, self.data_update_list)

    def test_send_message(self):
        """Check send_message Celery Script"""
        self.assertEqual(self.send_message_static, self.send_message)

    def test_send_message_toast(self):
        """Check send_message Celery Script with toast selected"""
        self.assertEqual(self.send_message_toast_static,
                         self.send_message_toast)

    def test_send_message_channels(self):
        """Check send_message Celery Script with multiple channels selected"""
        self.assertEqual(self.send_message_channels_static,
                         self.send_message_channels)

    def test_find_home(self):
        """Check find_home Celery Script"""
        self.assertEqual(self.find_home_static, self.find_home)

    def test_if_statement(self):
        """Check _if Celery Script"""
        self.assertEqual(self.if_statement_static, self.if_statement)

    def test_if_statement_nothing(self):
        """Check _if Celery Script: do nothing"""
        self.assertEqual(self.if_statement_nothing_static,
                         self.if_statement_nothing)

    def test_write_pin(self):
        """Check write_pin Celery Script"""
        self.assertEqual(self.write_pin_static, self.write_pin)

    def test_read_pin(self):
        """Check read_pin Celery Script"""
        self.assertEqual(self.read_pin_static, self.read_pin)

    def test_execute_sequence(self):
        """Check execute_sequence Celery Script"""
        self.assertEqual(self.execute_sequence_static, self.execute_sequence)

    def test_execute_script(self):
        """Check execute_script Celery Script"""
        self.assertEqual(self.execute_script_static, self.execute_script)

    def test_take_photo(self):
        """Check execute_script Celery Script"""
        self.assertEqual(self.take_photo_static, self.take_photo)

    def test_wait(self):
        """Check wait Celery Script"""
        self.assertEqual(self.wait_static, self.wait)
