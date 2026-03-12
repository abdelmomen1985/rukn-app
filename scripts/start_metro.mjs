#!/usr/bin/env node
import net from "node:net";
import { spawn } from "node:child_process";

const DEFAULT_PORT = Number.parseInt(process.env.EXPO_PORT ?? "8081", 10);
const MAX_PORT_ATTEMPTS = 20;

function canUsePort(port) {
  return new Promise((resolve) => {
    const server = net.createServer();

    server.once("error", () => resolve(false));
    server.once("listening", () => {
      server.close(() => resolve(true));
    });

    server.listen(port, "0.0.0.0");
  });
}

async function findAvailablePort(startPort) {
  for (let i = 0; i < MAX_PORT_ATTEMPTS; i += 1) {
    const port = startPort + i;
    if (await canUsePort(port)) return port;
  }

  return null;
}

const selectedPort = await findAvailablePort(DEFAULT_PORT);

if (!selectedPort) {
  console.error(
    `❌ Could not find an available port in range ${DEFAULT_PORT}-${DEFAULT_PORT + MAX_PORT_ATTEMPTS - 1}.`
  );
  process.exit(1);
}

if (selectedPort !== DEFAULT_PORT) {
  console.warn(
    `⚠️  Port ${DEFAULT_PORT} is busy. Starting Metro on port ${selectedPort} instead.`
  );
}

const child = spawn(
  "npx",
  ["expo", "start", "--lan", "--port", String(selectedPort)],
  {
    stdio: "inherit",
    env: {
      ...process.env,
      EXPO_USE_METRO_WORKSPACE_ROOT: "1",
      EXPO_PORT: String(selectedPort),
    },
  }
);

child.on("exit", (code, signal) => {
  if (signal) {
    process.kill(process.pid, signal);
    return;
  }
  process.exit(code ?? 0);
});
