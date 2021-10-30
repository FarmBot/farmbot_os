#!/usr/bin/env python
"""Plant Detection Test Suite

For Plant Detection.
"""
import unittest


def test_suite():
    """Return test suite."""
    testsuite = unittest.TestLoader().discover('.')
    return testsuite


if __name__ == '__main__':
    unittest.TextTestRunner(verbosity=2).run(test_suite())
