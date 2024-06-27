#!/bin/bash

# SPDX-FileCopyrightText: Copyright (c) 2023 - 2024 NVIDIA CORPORATION & AFFILIATES.
# SPDX-FileCopyrightText: All rights reserved.
# SPDX-License-Identifier: Apache-2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

export CUDA_PATH=/usr/local/cuda
export PY_SITE_PATH=/usr/local/lib/python3.10/dist-packages
export CMAKE_PREFIX_PATH="${PY_SITE_PATH}/torch/share/cmake;${PY_SITE_PATH}/pybind11/share/cmake"
echo "Trying to use Python libraries from $PY_SITE_PATH"

CONFIG=Release
OPENACC=0

# List CUDA compute capabilities
TORCH_CUDA_ARCH_LIST=""

BUILD_PATH=$(pwd -P)/gnu/
INSTALL_PATH=/opt/pytorch-fortran
mkdir -p $BUILD_PATH/build_proxy $BUILD_PATH/build_fortproxy $BUILD_PATH/build_example
# c++ wrappers 
(
    set -x
    cd $BUILD_PATH/build_proxy 
    cmake -DOPENACC=$OPENACC -DCMAKE_BUILD_TYPE=$CONFIG -DCMAKE_INSTALL_PREFIX=$INSTALL_PATH -DCUDA_TOOLKIT_ROOT_DIR=$CUDA_PATH -DCMAKE_PREFIX_PATH=$CMAKE_PREFIX_PATH -DTORCH_CUDA_ARCH_LIST=$TORCH_CUDA_ARCH_LIST ../../src/proxy_lib
    cmake --build . --parallel
    make install
)

# fortran bindings
(
    cd $BUILD_PATH/build_fortproxy
    cmake -DOPENACC=$OPENACC -DCMAKE_BUILD_TYPE=$CONFIG -DCMAKE_INSTALL_PREFIX=$INSTALL_PATH -DCMAKE_Fortran_COMPILER=gfortran -DCMAKE_PREFIX_PATH=$INSTALL_PATH/lib ../../src/f90_bindings/
    cmake --build . --parallel
    make install
)

# fortran examples
(
    cd $BUILD_PATH/build_example
    cmake -DOPENACC=$OPENACC -DCMAKE_BUILD_TYPE=$CONFIG -DCMAKE_INSTALL_PREFIX=$INSTALL_PATH -DCMAKE_Fortran_COMPILER=gfortran ../../examples/
    cmake --build . --parallel
    make install
)
