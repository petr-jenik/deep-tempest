#
# Copyright 2008,2009 Free Software Foundation, Inc.
#
# SPDX-License-Identifier: GPL-3.0-or-later
#

# The presence of this file turns this directory into a Python package

'''
This is the GNU Radio TEMPEST module. Place your Python package
description here (python/__init__.py).
'''
import os

# import pybind11 generated symbols into the tempest namespace
try:
    # this might fail if the module is python-only
    from .tempest_python import *
except ModuleNotFoundError:
    pass

# import any pure python here
try:
    from .image_source import image_source
except ModuleNotFoundError:
    pass

try:
    from .message_to_var import message_to_var
except ModuleNotFoundError:
    pass

try:
    from .tempest_msgbtn import tempest_msgbtn
except ModuleNotFoundError:
    pass

try:
    from .TMDS_image_source import TMDS_image_source
except ModuleNotFoundError:
    pass

try:
    from .TMDS_decoder import TMDS_decoder
except ModuleNotFoundError:
    pass

try:
    from .buttonToFileSink import buttonToFileSink
except ModuleNotFoundError as exc:
    _btn_missing_dep = getattr(exc, 'name', 'unknown')
    _btn_import_exc = exc

    class buttonToFileSink:  # type: ignore[no-redef]
        def __init__(self, *args, **kwargs):
            raise ImportError(
                "gnuradio.tempest.buttonToFileSink could not be loaded because "
                f"dependency '{_btn_missing_dep}' is missing. "
                "Install project Python dependencies (e.g. pip install -r tempest_pyenv.txt) "
                "and run with the same Python environment used for gr-tempest."
            ) from _btn_import_exc

try:
    from .DTutils import apply_blanking_shift, remove_outliers, adjust_dynamic_range
except ModuleNotFoundError:
    pass

try:
    from . import utils_option as option
    from . import utils_image as util
    from .utils_dist import get_dist_info, init_dist
    from .select_model import define_Model
    from . import basicblock as B
    from .network_unet import UNetRes as net
except ModuleNotFoundError:
    pass
