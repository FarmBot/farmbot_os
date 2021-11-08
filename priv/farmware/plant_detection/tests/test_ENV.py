#!/usr/bin/env python
"""Capture Tests

For Plant Detection.
"""
import os
import unittest
import json
try:
    import fakeredis
    test_redis = True
except ImportError:
    test_redis = False
from plant_detection import ENV


@unittest.skipUnless(test_redis, "requires fakeredis")
class LoadENVTest(unittest.TestCase):
    """Check data retrieval from redis"""

    def setUp(self):
        self.r = fakeredis.FakeStrictRedis()
        self.testvalue = 'some test data'
        self.testjson = {"label": "testdata", "value": 5}
        self.badjson_string = '{"label": "whoop'

    def test_env_load(self):
        """Get user_env from redis"""
        self.r.set('BOT_STATUS.user_env.testkey', self.testvalue)
        self.assertEqual(
            ENV.redis_load('user_env', name='testkey',
                           get_json=False, other_redis=self.r),
            self.testvalue)

    def test_json_env_load(self):
        """Get json user_env from redis"""
        self.r.set('BOT_STATUS.user_env.testdata', json.dumps(self.testjson))
        self.assertEqual(ENV.redis_load(
            'user_env', name='testdata', other_redis=self.r), self.testjson)

    def test_bad_json_env_load(self):
        """Try to get bad json user_env from redis"""
        self.r.set('BOT_STATUS.user_env.testdata', self.badjson_string)
        self.assertEqual(
            ENV.redis_load('user_env', name='testdata', other_redis=self.r),
            None)

    def test_none_user_env_load(self):
        """Try to get a non-existent user_env from redis"""
        self.assertEqual(
            ENV.redis_load('user_env', name='doesntexist', other_redis=self.r),
            None)

    def test_os_env_load(self):
        """Try to get an env from os"""
        os.environ['oktestenv'] = 'test'
        self.assertEqual(ENV.load_env('oktestenv', get_json=False), 'test')

    def test_none_os_env_load(self):
        """Try to get a non-existent env from os"""
        self.assertEqual(ENV.load_env('doesntexist'), None)

    def test_bad_json_os_env_load(self):
        """Try to get bad json env from os"""
        os.environ['testbadjson'] = '{"label": "whoop'
        self.assertEqual(ENV.load_env('testbadjson'), None)

    def tearDown(self):
        self.r.flushall()
