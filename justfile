# Install all JS dependencies
install:
    pnpm install

# Start the Vite dev server (runs Elm and watches for JS changes)
dev:
    pnpm vite

# Watch Rust and rebuild the Wasm package in the background
# Run this in a separate terminal or use 'just dev-all'
watch-rust:
    cd parser && cargo watch -i pkg -s "wasm-pack build --target web --out-dir pkg"

# Build both Rust and Elm for production
build:
    cd parser && wasm-pack build --target web --out-dir pkg
    pnpm vite build

# Run all project tests
test:
    cd parser && cargo test
    pnpm elm-test

# Format everything
fmt:
    cd parser && cargo fmt
    pnpm elm-format src/ --yes
