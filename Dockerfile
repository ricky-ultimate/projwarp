# Use official Rust image (Linux-based)
FROM rust:1.85

# Create app directory
WORKDIR /usr/src/projwarp

# Copy Cargo manifests
COPY Cargo.toml Cargo.lock ./

# Pre-download dependencies
RUN cargo fetch

# Copy source code
COPY src ./src

# Build the project in release mode
RUN cargo build --release

# Default command
CMD ["./target/release/projwarp"]
