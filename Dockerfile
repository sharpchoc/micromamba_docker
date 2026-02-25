FROM runpod/pytorch:2.4.0-py3.11-cuda12.4.1-devel-ubuntu22.04

# Install micromamba
RUN curl -L https://micro.mamba.pm/api/micromamba/linux-64/latest \
  | tar -xvj bin/micromamba \
 && mv bin/micromamba /usr/local/bin/micromamba \
 && chmod +x /usr/local/bin/micromamba \
 && rm -rf bin

# Where micromamba stores pkgs/envs
ENV MAMBA_ROOT_PREFIX=/opt/micromamba
ENV PATH=/usr/local/bin:$PATH

# Make `micromamba activate` work in bash shells
RUN echo 'export MAMBA_ROOT_PREFIX=/opt/micromamba' >> /root/.bashrc \
 && echo 'eval "$(micromamba shell hook -s bash)"' >> /root/.bashrc
