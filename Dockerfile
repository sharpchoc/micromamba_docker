FROM runpod/pytorch:2.4.0-py3.11-cuda12.4.1-devel-ubuntu22.04

# Force RUN to use sh (this image has no /bin/bash)
SHELL ["/bin/sh", "-c"]

# DEBUG: show shell + user
RUN echo "== DEBUG shell/user ==" && whoami && id && ls -l /bin/sh && ls -l /bin/bash || true

RUN apt-get update && apt-get install -y --no-install-recommends \
    git curl ca-certificates tar \
 && rm -rf /var/lib/apt/lists/*

# micromamba
RUN curl -L https://micro.mamba.pm/api/micromamba/linux-64/latest \
  | tar -xv bin/micromamba \
 && mv bin/micromamba /usr/local/bin/micromamba \
 && chmod +x /usr/local/bin/micromamba \
 && rm -rf bin

ENV MAMBA_ROOT_PREFIX=/opt/micromamba
ENV PATH=/usr/local/bin:$PATH

WORKDIR /opt/build
COPY requirements.core.txt /opt/build/requirements.core.txt
COPY requirements.extra.txt /opt/build/requirements.extra.txt

# DEBUG micromamba
RUN echo "== DEBUG micromamba ==" && which micromamba && micromamba --version && echo "MAMBA_ROOT_PREFIX=$MAMBA_ROOT_PREFIX"

# Create env (no condarc needed since we specify channel)
RUN micromamba create -y -n spar_env -c conda-forge python=3.11

# Upgrade pip tooling
RUN micromamba run -n spar_env python -m pip install -U pip setuptools wheel

# Install core deps
RUN micromamba run -n spar_env pip install -r /opt/build/requirements.core.txt

# Optional extras
# RUN micromamba run -n spar_env pip install -r /opt/build/requirements.extra.txt

# Cleanup
RUN micromamba clean -a -y

# Default to env python
ENV PATH=/opt/micromamba/envs/spar_env/bin:$PATH

# If you want convenience in interactive shells:
RUN echo 'export MAMBA_ROOT_PREFIX=/opt/micromamba' >> /root/.profile \
 && echo 'export PATH=/opt/micromamba/envs/spar_env/bin:$PATH' >> /root/.profile
