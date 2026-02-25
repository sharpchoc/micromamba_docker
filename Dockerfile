FROM runpod/pytorch:2.4.0-py3.11-cuda12.4.1-devel-ubuntu22.04

# Install micromamba
RUN curl -L https://micro.mamba.pm/api/micromamba/linux-64/latest \
  | tar -xvj bin/micromamba \
 && mv bin/micromamba /usr/local/bin/micromamba \
 && chmod +x /usr/local/bin/micromamba \
 && rm -rf bin

# Put micromamba envs/pkgs somewhere standard
ENV MAMBA_ROOT_PREFIX=/opt/micromamba
ENV PATH=/opt/micromamba/bin:/usr/local/bin:$PATH

# Make `micromamba activate` work in interactive shells
RUN micromamba shell init -s bash -p ${MAMBA_ROOT_PREFIX} \
 && echo 'eval "$(micromamba shell hook -s bash)"' >> /root/.bashrc
