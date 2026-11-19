FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    apt-utils \
    ca-certificates \
    cpio \
    createrepo-c \
    curl \
    dpkg-dev \
    gnupg \
    python3 \
    python3-pip \
    rpm \
    rpm2cpio \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

CMD ["/bin/bash"]
