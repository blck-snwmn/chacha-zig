# chacha-zig

Toy implementation of chacha20 poly1305 written in Zig.

See: https://datatracker.ietf.org/doc/html/rfc8439

## Run

```
zig run src/main.zig
```

## Test

```
zig test src/main.zig
```

## WASI

```
zig build-exe src/main.zig -target wasm32-wasi
wasmtime main.wasm
```
