FROM runpod/pytorch:2.4.0-py3.11-cuda12.4.1-devel-ubuntu22.04

# System deps for pip + git installs
RUN apt-get update && apt-get install -y --no-install-recommends \
    git curl ca-certificates \
 && rm -rf /var/lib/apt/lists/*

# Install micromamba
RUN curl -L https://micro.mamba.pm/api/micromamba/linux-64/latest \
  | tar -xvj bin/micromamba \
 && mv bin/micromamba /usr/local/bin/micromamba \
 && chmod +x /usr/local/bin/micromamba \
 && rm -rf bin

ENV MAMBA_ROOT_PREFIX=/opt/micromamba
ENV PATH=/usr/local/bin:$PATH

# Copy requirements into the image
WORKDIR /opt/build
COPY requirements.docker.txt /opt/build/requirements.docker.txt

# Create env + install deps
# Note: we rely on the base image's torch/cu124 stack; we do NOT reinstall torch here.
RUN micromamba create -y -n spar_env python=3.11 \
 && micromamba run -n spar_env python -m pip install -U pip setuptools wheel \
 && micromamba run -n spar_env pip install -r /opt/build/requirements.docker.txt \
 && micromamba clean -a -y

# Make env default for all shells + processes
ENV PATH=/opt/micromamba/envs/spar_env/bin:$PATH

# Optional: make activation convenient in interactive shells
RUN echo 'export MAMBA_ROOT_PREFIX=/opt/micromamba' >> /root/.bashrc \
 && echo 'export PATH=/opt/micromamba/envs/spar_env/bin:$PATH' >> /root/.bashrc \
 && echo 'eval "$(micromamba shell hook -s bash)"' >> /root/.bashrc
