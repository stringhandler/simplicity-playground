FROM mcr.microsoft.com/devcontainers/base:ubuntu

# Install C and Rust build toolchains
RUN apt-get update && apt-get install -y \
    curl \
    git \
    build-essential \
    ca-certificates \
    pkg-config \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Rust
RUN curl https://sh.rustup.rs -sSf | bash -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

# Clone SimplicityHL
WORKDIR /opt
RUN git clone https://github.com/BlockstreamResearch/SimplicityHL.git

# Build simc compiler
WORKDIR /opt/SimplicityHL
RUN cargo build --release

# Install simc globally
RUN cp target/release/simc /usr/local/bin/

# Default working dir for user
WORKDIR /workspace
