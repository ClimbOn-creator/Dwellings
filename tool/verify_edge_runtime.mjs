import fs from 'node:fs';
import path from 'node:path';
import {pathToFileURL} from 'node:url';

// A deployment inventory guard, not a scanner for PHP runtime vulnerabilities.
export function verifyNoPhpArtifacts(root = '.', roots = ['functions', 'workers', 'web', 'dist']) {
  const forbidden = [];
  function visit(directory) {
    if (!fs.existsSync(directory)) return;
    for (const entry of fs.readdirSync(directory, {withFileTypes: true})) {
      const full = path.join(directory, entry.name);
      if (entry.isSymbolicLink()) throw new Error(`Review deployment symlink: ${full}`);
      if (entry.isDirectory()) visit(full);
      else if (/\.(?:php\d*|phtml|phar|phps)(?:\.|$)/i.test(entry.name)
        || /^(?:composer\.(?:json|lock)|php(?:-cgi|-fpm)?(?:\d+(?:\.\d+)*)?(?:\.exe)?|php\.ini|\.user\.ini)$/i.test(entry.name)) {
        forbidden.push(full);
      }
    }
  }
  for (const directory of roots) visit(path.join(root, directory));
  if (forbidden.length) throw new Error(`PHP artifacts require a separate patched-runtime review before deployment:\n${forbidden.join('\n')}`);
  return true;
}
if (process.argv[1] && import.meta.url === pathToFileURL(path.resolve(process.argv[1])).href) {
  if (process.argv[2]) verifyNoPhpArtifacts(process.argv[2], ['.']);
  else verifyNoPhpArtifacts();
  console.log('Edge deployment inventory: no PHP artifacts.');
}
