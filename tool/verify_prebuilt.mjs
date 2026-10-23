import {verifyNoPhpArtifacts} from './verify_edge_runtime.mjs';
import fs from "node:fs";

for (const file of ["dist/index.html", "dist/flutter_bootstrap.js", "dist/main.dart.js"]) {
  if (!fs.existsSync(file)) {
    console.error(`Missing ${file}. Run npm run build:flutter before committing.`);
    process.exit(1);
  }
}
verifyNoPhpArtifacts();
console.log("Prebuilt Flutter web bundle is ready for Cloudflare Pages.");
