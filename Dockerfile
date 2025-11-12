# Use official Rust image (Linux-based)
FROM rust:1.85

# Create app directory
WORKDIR /usr/src/projwarp

COPY . .
RUN cargo fetch

# Build the project in release mode
RUN cargo build --release

# Default command
CMD ["./target/release/projwarp"]
