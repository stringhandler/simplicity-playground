FROM mcr.microsoft.com/devcontainers/base:ubuntu

# Install dependencies
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

# -------------------------
# Build simc (SimplicityHL)
# -------------------------
WORKDIR /opt
RUN git clone https://github.com/BlockstreamResearch/SimplicityHL.git
WORKDIR /opt/SimplicityHL
RUN cargo build --release
RUN cp target/release/simc /usr/local/bin/

# -------------------------------
# Build hal-simplicity compiler
# -------------------------------
WORKDIR /opt
RUN git clone https://github.com/BlockstreamResearch/hal-simplicity.git
WORKDIR /opt/hal-simplicity
RUN cargo build --release
RUN cp target/release/hal-simplicity /usr/local/bin/

# Set default working directory
WORKDIR /workspace
