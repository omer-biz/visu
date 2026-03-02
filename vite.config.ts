import { defineConfig } from 'vite';
import elm from 'vite-plugin-elm';
import wasm from "vite-plugin-wasm";
import tailwindcss from '@tailwindcss/vite';

export default defineConfig({
  plugins: [elm(), tailwindcss(), wasm()],
  build: { target: "esnext" },
  worker: {
    plugins: () => [wasm(),],
    format: "es"
  },
});
