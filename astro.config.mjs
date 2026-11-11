import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';
import sitemap from '@astrojs/sitemap';
import { execFileSync } from 'node:child_process';
import { existsSync } from 'node:fs';
import { fileURLToPath } from 'node:url';

const root = fileURLToPath(new URL('./', import.meta.url));

// Pages that only redirect, and the 404 page, have no place in the sitemap.
const unlisted = new Set(['/docs/devices/', '/docs/installation/', '/download/', '/blog/hello-world/', '/404/']);

// A page's last change is the newest commit touching its source, or for the
// device page its data too. Pages with no source file get no lastmod.
function sourcesFor(pathname) {
  if (pathname === '/') return ['src/pages/index.astro'];
  if (pathname === '/blog/') return ['src/pages/blog/index.astro', 'src/content/blog'];
  if (pathname === '/devices/') return ['src/pages/devices.astro', 'src/components/DeviceFinder.astro', 'src/data'];
  const post = pathname.match(/^\/blog\/([^/]+)\/$/);
  if (post) return ['md', 'mdx'].map(ext => `src/content/blog/${post[1]}.${ext}`);
  const doc = pathname.replace(/^\/|\/$/g, '');
  return ['md', 'mdx'].flatMap(ext => [`src/content/docs/${doc}.${ext}`, `src/content/docs/${doc}/index.${ext}`]);
}
function lastmod(pathname) {
  const sources = sourcesFor(pathname).filter(source => existsSync(new URL(source, `file://${root}`)));
  if (!sources.length) return undefined;
  try {
    const date = execFileSync('git', ['log', '-1', '--format=%cI', '--', ...sources], { cwd: root, encoding: 'utf8' }).trim();
    return date || undefined;
  } catch {
    return undefined;
  }
}

export default defineConfig({
  site: 'https://aurorasilicon.org',
  trailingSlash: 'always',
  devToolbar: { enabled: false },
  integrations: [
    starlight({
      title: 'Aurora Silicon',
      description: 'Linux and Windows on Apple Silicon Macs. Downloads, device support, and project documentation.',
      logo: { src: './src/assets/aurora-silicon-mark.svg', replacesTitle: false },
      favicon: '/favicon.svg',
      social: [
        { icon: 'github', label: 'GitHub', href: 'https://github.com/aurora-silicon' },
        { icon: 'x.com', label: 'X', href: 'https://x.com/aurorasilicon' },
        { icon: 'discord', label: 'Discord', href: 'https://discord.gg/DXmsSSc5aY' },
      ],
      customCss: ['./src/styles/docs.css'],
      // Support and Blog sit in the docs header, as in the site's main navigation.
      components: { SocialIcons: './src/components/DocsSocialIcons.astro' },
      editLink: {
        baseUrl: 'https://github.com/aurora-silicon/aurora-silicon.github.io/edit/main/',
      },
      head: [
        { tag: 'meta', attrs: { property: 'og:image', content: 'https://aurorasilicon.org/og-image.png' } },
        { tag: 'meta', attrs: { property: 'og:image:width', content: '1200' } },
        { tag: 'meta', attrs: { property: 'og:image:height', content: '630' } },
        { tag: 'meta', attrs: { property: 'og:image:alt', content: 'The Aurora Silicon mark' } },
        { tag: 'meta', attrs: { name: 'twitter:image', content: 'https://aurorasilicon.org/og-image.png' } },
        { tag: 'link', attrs: { rel: 'icon', type: 'image/png', sizes: '32x32', href: '/favicon-32.png' } },
        { tag: 'link', attrs: { rel: 'apple-touch-icon', href: '/apple-touch-icon.png' } },
        { tag: 'link', attrs: { rel: 'manifest', href: '/site.webmanifest' } },
        { tag: 'script', attrs: { type: 'application/ld+json' }, content: JSON.stringify({
          '@context': 'https://schema.org',
          '@type': 'Organization',
          name: 'Aurora Silicon',
          url: 'https://aurorasilicon.org/',
          logo: 'https://aurorasilicon.org/icon-512.png',
          sameAs: ['https://github.com/aurora-silicon', 'https://x.com/aurorasilicon', 'https://discord.gg/DXmsSSc5aY'],
        }) },
      ],
      sidebar: [
        { label: 'Start here', items: [
          { label: 'Introduction', slug: 'docs' },
          { label: 'Download', slug: 'docs/download' },
          { label: 'Project overview', slug: 'docs/project' },
          { label: 'Attribution', slug: 'docs/attribution' },
          { label: 'Support records', slug: 'docs/hardware' },
        ] },
        { label: 'Linux', slug: 'docs/linux' },
        { label: 'Userland and packages', items: [
          { label: 'Overview', slug: 'docs/userland' },
          { label: 'Audio', collapsed: true, items: [
            'docs/userland/speakerguardd',
            'docs/userland/audio',
            'docs/userland/airplay',
          ] },
          { label: 'Touch ID and Secure Enclave', collapsed: true, items: [
            'docs/userland/touch-id',
            'docs/userland/security-key',
            'docs/userland/ssh-keys',
            'docs/userland/disk-unlock',
          ] },
          { label: 'Display, keyboard and camera', collapsed: true, items: [
            'docs/userland/keyboard-backlight',
            'docs/userland/ambient-white-point',
            'docs/userland/boot-splash',
            'docs/userland/camera-denoise',
          ] },
          { label: 'Graphics, media and apps', collapsed: true, items: [
            'docs/userland/graphics',
            'docs/userland/video-decode',
            'docs/userland/video-encode',
            'docs/userland/gaming',
            'docs/userland/neural-engine',
          ] },
          { label: 'Network and power', collapsed: true, items: [
            'docs/userland/airdrop',
            'docs/userland/power',
          ] },
          { label: 'System', collapsed: true, items: [
            'docs/userland/installer',
            'docs/userland/first-boot',
            'docs/userland/boot-and-updates',
            'docs/userland/platform',
          ] },
        ] },
        { label: 'Contribute', items: [
          { label: 'Getting involved', slug: 'docs/contributing' },
          { label: 'Policies & guidelines', slug: 'docs/policies' },
        ] },
      ],
    }),
    sitemap({
      filter: page => !unlisted.has(new URL(page).pathname),
      serialize: item => {
        const date = lastmod(new URL(item.url).pathname);
        return date ? { ...item, lastmod: date } : item;
      },
    }),
  ],
});
