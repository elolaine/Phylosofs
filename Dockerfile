FROM ubuntu:bionic

# to avoid interaction with tzdata during the installation
ARG DEBIAN_FRONTEND=noninteractive

# to avoid the UnicodeEncodeError when running phylosofs -h (default LANG is C)
ENV LANG C.UTF-8

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    git \
    python3 \
    python3-pip \
    # setuptools is needed to install phylosofs
    python3-setuptools \
    # wheel is needed to install networkx
    python3-wheel \
    # ca-certificates is needed to use git clone without SSL CA cert problems
    ca-certificates \
    # PhyloSofS dependencies:
    graphviz \
    # make and cmake are needed to install HH-suite
    cmake \
    make \
    # install cmake compilers
    gcc \
    g++ \
    # to avoid xdd not found in HH-suite compilation
    xxd \
    # install MPI for HH-suite
    libopenmpi2 \
    libblacs-mpi-dev \
    # curl is needed to download MODELLER and Julia
    curl \
    # zlib in needed to use BioAlignments
    zlib1g-dev

WORKDIR /app

RUN git clone https://github.com/PhyloSofS-Team/PhyloSofS.git && \
    python3 -m pip install ./PhyloSofS

RUN git clone https://github.com/AntoineLabeeuw/hh-suite.git && \
   mkdir -p hh-suite/build && cd hh-suite/build && \
   cmake -DCMAKE_INSTALL_PREFIX=. .. && \
   make -j 4 && make install

ENV PATH="/app/hh-suite/build/bin:/app/hh-suite/build/scripts:${PATH}"

COPY Manifest.toml /root/.julia/environments/v1.1/Manifest.toml

COPY Project.toml /root/.julia/environments/v1.1/Project.toml

RUN curl -O https://julialang-s3.julialang.org/bin/linux/x64/1.1/julia-1.1.1-linux-x86_64.tar.gz && \
    tar xvzf julia-1.1.1-linux-x86_64.tar.gz && \
    rm julia-1.1.1-linux-x86_64.tar.gz && \
    /app/julia-1.1.1/bin/julia -e \
    'using Pkg; Pkg.activate("/root/.julia/environments/v1.1/"); Pkg.instantiate();' && \
    /app/julia-1.1.1/bin/julia -e 'using Pkg; pkg"precompile";'

ENV PATH="/app/julia-1.1.1/bin:${PATH}"

RUN curl -O https://salilab.org/modeller/9.22/modeller_9.22-1_amd64.deb && \
    dpkg -i modeller_9.22-1_amd64.deb && \
    rm modeller_9.22-1_amd64.deb

COPY docker_banner.sh docker_banner.sh

RUN cat /app/docker_banner.sh >> ~/.bashrc

WORKDIR /databases

WORKDIR /project

CMD ["/bin/bash"]