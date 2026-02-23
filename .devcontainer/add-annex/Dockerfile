FROM mcr.microsoft.com/devcontainers/base:ubuntu

# -----------------------------------------------
# Repo URLs — override via devcontainer.json args
# -----------------------------------------------
ARG SIMPLICITYHL_REPO=https://github.com/BlockstreamResearch/SimplicityHL.git
ARG SIMPLICITYHL_BRANCH=master
ARG HAL_SIMPLICITY_REPO=https://github.com/BlockstreamResearch/hal-simplicity.git
ARG HAL_SIMPLICITY_BRANCH=master
ARG LWK_REPO=https://github.com/Blockstream/lwk.git

# Install system dependencies
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
RUN git clone --branch ${SIMPLICITYHL_BRANCH} ${SIMPLICITYHL_REPO}
WORKDIR /opt/SimplicityHL
RUN cargo build --release --features "serde"
RUN cp target/release/simc /usr/local/bin/

# -------------------------------
# Build hal-simplicity
# -------------------------------
WORKDIR /opt
RUN git clone --branch ${HAL_SIMPLICITY_BRANCH} ${HAL_SIMPLICITY_REPO}
WORKDIR /opt/hal-simplicity
RUN cargo build --release
RUN cp target/release/hal-simplicity /usr/local/bin/

# ----------------
# Build lwk
# ----------------
WORKDIR /opt
RUN git clone ${LWK_REPO}
WORKDIR /opt/lwk
RUN cargo build --release
RUN cp target/release/lwk_cli /usr/local/bin/

# Default workspace
WORKDIR /workspace
