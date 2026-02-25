FROM runpod/pytorch:2.4.0-py3.11-cuda12.4.1-devel-ubuntu22.04

# Ensure bash exists (this base image may not include it)
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash git curl ca-certificates tar bzip2 \
 && rm -rf /var/lib/apt/lists/*

# Use bash for RUN (so pipefail works)
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# --- DEBUG: confirm bash + user ---
RUN echo "== DEBUG shell/user ==" && which bash && bash --version | head -n 2 && whoami && id

# Install micromamba (robust: download to file first)
RUN curl -fsSL -o /tmp/micromamba.tar.bz2 https://micro.mamba.pm/api/micromamba/linux-64/latest \
 && ls -lh /tmp/micromamba.tar.bz2 \
 && tar -xvjf /tmp/micromamba.tar.bz2 -C /tmp bin/micromamba \
 && mv /tmp/bin/micromamba /usr/local/bin/micromamba \
 && chmod +x /usr/local/bin/micromamba \
 && micromamba --version \
 && rm -rf /tmp/micromamba.tar.bz2 /tmp/bin

ENV MAMBA_ROOT_PREFIX=/opt/micromamba
ENV PATH=/usr/local/bin:$PATH

WORKDIR /opt/build
COPY requirements.core.txt /opt/build/requirements.core.txt
COPY requirements.extra.txt /opt/build/requirements.extra.txt

# --- DEBUG: micromamba availability ---
RUN echo "== DEBUG micromamba ==" && which micromamba && micromamba --version && echo "MAMBA_ROOT_PREFIX=$MAMBA_ROOT_PREFIX"

# Create env (explicit channel; no condarc needed)
RUN micromamba create -y -n spar_env -c conda-forge python=3.11

# Upgrade pip tooling inside env
RUN micromamba run -n spar_env python -m pip install -U pip setuptools wheel

# Install core deps
RUN micromamba run -n spar_env pip install -r /opt/build/requirements.core.txt

# Optional extras (enable later if needed)
# RUN micromamba run -n spar_env pip install -r /opt/build/requirements.extra.txt

# Cleanup
RUN micromamba clean -a -y

# Default to env python for all commands
ENV PATH=/opt/micromamba/envs/spar_env/bin:$PATH

# Convenience for interactive shells
RUN echo 'export MAMBA_ROOT_PREFIX=/opt/micromamba' >> /root/.bashrc \
 && echo 'export PATH=/opt/micromamba/envs/spar_env/bin:$PATH' >> /root/.bashrc \
 && echo 'eval "$(micromamba shell hook -s bash)"' >> /root/.bashrc
