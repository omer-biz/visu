import type { Config } from "tailwindcss";

const config: Config = {
  content: ["./src/*{.ts,.elm}"],
  theme: {
    extend: {
      fontFamily: {
        inter: ['Inter', 'sans-serif'],
        mono: ['JetBrains Mono', 'monospace'],
      },
    },
  },
};

export default config;
