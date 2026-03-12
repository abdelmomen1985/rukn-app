#!/usr/bin/env node
import os from "node:os";
import QRCode from "qrcode";
function getLanIPv4() {
  const interfaces = os.networkInterfaces();

  for (const entries of Object.values(interfaces)) {
    if (!entries) continue;
    for (const entry of entries) {
      if (entry.family === "IPv4" && !entry.internal) {
        return entry.address;
      }
    }
  }

  return null;
}

const providedUrl = process.argv[2];
const port = process.env.EXPO_PORT ?? "8081";
const host = process.env.EXPO_HOST ?? getLanIPv4();
const url = providedUrl ?? (host ? `exp://${host}:${port}` : null);

if (!url) {
  console.error('Usage: node scripts/generate_qr.mjs "exp://..."');
  console.error(
    "Could not detect a LAN IP automatically. Pass the Expo URL manually."
  );
  process.exit(1);
}

await QRCode.toFile("expo-qr-code.png", url, { width: 512 });
console.log(`✅ QR code saved to expo-qr-code.png`);
console.log(`🔗 Encoded URL: ${url}`);
