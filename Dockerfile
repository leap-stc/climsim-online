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

FROM nvcr.io/nvidia/pytorch:24.05-py3 as pytf

COPY . /climsim

RUN cd /climsim/pytorch-fortran && ../build_gnu_cuda12.4.sh

ENV PATH=/opt/pytorch-fortran/bin:${PATH}
ENV LD_LIBRARY_PATH=/opt/pytorch-fortran/lib:${LD_LIBRARY_PATH}

FROM pytf as e3sm

ARG PNETCDF_VERSION=1.12.3
ENV PNETCDF_VERSION=${PNETCDF_VERSION}

ARG LIBNETCDF_VERSION=4.9.1
ENV LIBNETCDF_VERSION=${LIBNETCDF_VERSION}

ARG NETCDF_FORTRAN_VERSION=*
ENV NETCDF_FORTRAN_VERSION=${NETCDF_FORTRAN_VERSION}

ENV USER=root
ENV LOGNAME=root

COPY ./E3SM /climsim/E3SM

RUN pip install pytest pytest-cov netcdf4 h5py xarray

# Build pnetcdf
RUN cd /climsim/ && \
            curl -L -k -o "${PWD}/pnetcdf.tar.gz" \
            https://parallel-netcdf.github.io/Release/pnetcdf-${PNETCDF_VERSION}.tar.gz && \
            mkdir "${PWD}/pnetcdf" && \
            tar -xvf "${PWD}/pnetcdf.tar.gz" -C "${PWD}/pnetcdf" --strip-components=1 && \
            rm -rf "${PWD}/pnetcdf.tar.gz" && \
            cd "${PWD}/pnetcdf" && \
            ./configure --prefix /opt/pnetcdf --disable-cxx --enable-shared \
            MPICC=/usr/local/mpi/bin/mpicc \
            MPICXX=/usr/local/mpi/bin/mpicxx \
            MPIF77=/usr/local/mpi/bin/mpif77 \
            MPIF90=/usr/local/mpi/bin/mpif90 && \
            make -j4 && \
            make install && \
            rm -rf "${PWD}/pnetcdf"

ENV PATH=/opt/netcdf/bin:${PATH}
ENV LD_LIBRARY_PATH=/opt/pnetcdf/lib:${LD_LIBRARY_PATH}

## Install NETCDF C Library
RUN cd /climsim/ && \
    wget -c https://github.com/Unidata/netcdf-c/archive/refs/tags/v4.9.0.tar.gz && \
    tar xzvf v4.9.0.tar.gz && \
    cd netcdf-c-4.9.0/ && \
    mkdir build && cd build && \
    cmake .. -DCMAKE_INSTALL_PREFIX=/opt/netcdf && \
    make -j && \
    make install

ENV PATH=/opt/pnetcdf/bin:${PATH}
ENV LD_LIBRARY_PATH=/opt/netcdf/lib:${LD_LIBRARY_PATH}

## NetCDF fortran library
RUN cd /climsim && \
    wget -c https://github.com/Unidata/netcdf-fortran/archive/refs/tags/v4.6.1.tar.gz && \
    tar -xvzf v4.6.1.tar.gz && \
    cd netcdf-fortran-4.6.1/ && \
    export CPPFLAGS=-I/opt/netcdf/include && \
    export LDFLAGS=-L/opt/netcdf/lib && \
    export LIBS="-lnetcdf -lhdf5_serial_hl -lhdf5_serial -lz" && \
    ./configure --prefix=/opt/netcdf && \
    make -j && \
    make install

RUN apt-get update && apt-get install -y libxml2 libxml2-utils libxml-libxml-perl subversion
#RUN cpan install XML::LibXML Switch

RUN mkdir /root/.cime && \
    mkdir -p /scratch && \
    mkdir -p /storage/timings && \
    mkdir -p /storage/cases && \
    mkdir -p /storage/inputdata && \
    mkdir -p /storage/inputdata-clmforc && \
    mkdir -p /storage/archive && \
    mkdir -p /storage/baselines && \
    mkdir -p /storage/tools/cprnc

WORKDIR /climsim
