import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    include: ["tests/**/*.test.ts"],
    environment: "node",
    // Las pruebas de integración comparten la base de datos de pruebas.
    fileParallelism: false,
    env: { NODE_ENV: "test" }
  }
});
