import { existsSync, readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const root = fileURLToPath(new URL('../', import.meta.url));
const env = { ...process.env };

function run(command, args, options = {}) {
  const result = spawnSync(command, args, { cwd: root, env, stdio: 'inherit', ...options });
  if (result.error) {
    console.error(result.error.message);
    process.exit(1);
  }
  if (result.status !== 0) process.exit(result.status ?? 1);
}

// Pagefind's Linux ARM64 release uses a 4 KB-page musl allocator. A native
// build works on 16 KB Apple Silicon Linux kernels without changing search.
if (process.platform === 'linux' && process.arch === 'arm64' &&
    !env.PAGEFIND_BINARY_PATH && !env.PAGEFIND_EXTENDED_BINARY_PATH) {
  const pageSize = spawnSync('getconf', ['PAGESIZE'], { encoding: 'utf8' });
  if (pageSize.status !== 0) {
    console.error('Could not determine the system page size for Pagefind.');
    process.exit(1);
  }
  if (Number(pageSize.stdout.trim()) > 4096) {
    const packageUrl = new URL('../package.json', import.meta.resolve('pagefind'));
    // import.meta.resolve() points at pagefind/lib/index.js.
    const { version } = JSON.parse(readFileSync(packageUrl, 'utf8'));
    const cache = resolve(root, '.cache/pagefind');
    const binary = resolve(cache, 'bin/pagefind');
    const installed = existsSync(binary)
      ? spawnSync(binary, ['--version'], { encoding: 'utf8' })
      : null;
    if (installed?.status !== 0 || installed?.stdout.trim() !== `pagefind ${version}`) {
      console.log(`Building native Pagefind ${version} for this Linux page size (requires Rust/Cargo).`);
      run('cargo', ['install', 'pagefind', '--version', version, '--locked', '--root', cache]);
    }
    env.PAGEFIND_BINARY_PATH = binary;
  }
}

const astroPackageUrl = new URL(import.meta.resolve('astro/package.json'));
const { bin } = JSON.parse(readFileSync(astroPackageUrl, 'utf8'));
run(process.execPath, [fileURLToPath(new URL(bin.astro, astroPackageUrl)), 'build']);

// The upstream native service can terminate before reporting an error. Do not
// accept a successful build without its generated documentation search index.
if (!existsSync(resolve(root, 'dist/pagefind/pagefind.js'))) {
  console.error('Build did not generate the documentation search index.');
  process.exit(1);
}
