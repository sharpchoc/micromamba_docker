FROM runpod/pytorch:2.4.0-py3.11-cuda12.4.1-devel-ubuntu22.04

RUN apt-get update && apt-get install -y --no-install-recommends \
    git curl ca-certificates \
 && rm -rf /var/lib/apt/lists/*

# micromamba
RUN curl -L https://micro.mamba.pm/api/micromamba/linux-64/latest \
  | tar -xvj bin/micromamba \
 && mv bin/micromamba /usr/local/bin/micromamba \
 && chmod +x /usr/local/bin/micromamba \
 && rm -rf bin

ENV MAMBA_ROOT_PREFIX=/opt/micromamba
ENV PATH=/usr/local/bin:$PATH

WORKDIR /opt/build
COPY requirements.core.txt /opt/build/requirements.core.txt
COPY requirements.extra.txt /opt/build/requirements.extra.txt

# Create env
RUN micromamba create -y -n spar_env python=3.11

# Upgrade pip tooling
RUN micromamba run -n spar_env python -m pip install -U pip setuptools wheel

# Install core deps (should succeed)
RUN micromamba run -n spar_env pip install -r /opt/build/requirements.core.txt

# Install optional deps (comment out if you want a guaranteed build)
# RUN micromamba run -n spar_env pip install -r /opt/build/requirements.extra.txt

# Cleanup
RUN micromamba clean -a -y

# Default to env python
ENV PATH=/opt/micromamba/envs/spar_env/bin:$PATH

RUN echo 'export MAMBA_ROOT_PREFIX=/opt/micromamba' >> /root/.bashrc \
 && echo 'export PATH=/opt/micromamba/envs/spar_env/bin:$PATH' >> /root/.bashrc \
 && echo 'eval "$(micromamba shell hook -s bash)"' >> /root/.bashrc
