FROM runpod/pytorch:2.4.0-py3.11-cuda12.4.1-devel-ubuntu22.04

# --- DEBUG: show which user we are during build + whether /etc is writable ---
RUN echo "== DEBUG: user / perms ==" && whoami && id && echo "HOME=$HOME" && \
    ls -ld / /etc /etc/conda || true && \
    touch /etc/.write_test 2>/dev/null && echo "wrote /etc/.write_test OK" || echo "CANNOT write to /etc" && \
    rm -f /etc/.write_test 2>/dev/null || true

# If the above says you cannot write to /etc, uncomment this to force root:
# USER root

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

# --- DEBUG: after micromamba install ---
RUN echo "== DEBUG: micromamba ==" && which micromamba && micromamba --version && \
    echo "MAMBA_ROOT_PREFIX=$MAMBA_ROOT_PREFIX" && ls -ld /opt /opt/micromamba || true

# (Optional) Conda config. If this fails due to permissions, either:
#  - uncomment USER root above, OR
#  - delete this line (since we pass -c conda-forge anyway)
RUN mkdir -p /etc/conda && printf "channels:\n  - conda-forge\nchannel_priority: strict\n" > /etc/conda/.condarc

# Create env
RUN micromamba create -y -n spar_env -c conda-forge python=3.11 -vv

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

RUN echo 'export MAMBA_ROOT_PREFIX=/opt/micromamba' >> /root/.bashrc \
 && echo 'export PATH=/opt/micromamba/envs/spar_env/bin:$PATH' >> /root/.bashrc \
 && echo 'eval "$(micromamba shell hook -s bash)"' >> /root/.bashrc
