import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';

export default defineConfig({
  site: 'https://aurorasilicon.org',
  trailingSlash: 'always',
  devToolbar: { enabled: false },
  integrations: [
    starlight({
      title: 'Aurora Silicon',
      description: 'Linux on Apple Silicon Macs. Downloads, device support, and project documentation.',
      logo: { src: './src/assets/aurora-silicon-mark.svg', replacesTitle: false },
      favicon: '/favicon.svg',
      social: [
        { icon: 'github', label: 'GitHub', href: 'https://github.com/aurora-silicon' },
        { icon: 'x.com', label: 'X', href: 'https://x.com/aurorasilicon' },
        { icon: 'discord', label: 'Discord', href: 'https://discord.gg/DXmsSSc5aY' },
      ],
      customCss: ['./src/styles/docs.css'],
      editLink: {
        baseUrl: 'https://github.com/aurora-silicon/aurora-silicon.github.io/edit/main/',
      },
      head: [
        { tag: 'meta', attrs: { property: 'og:image', content: 'https://aurorasilicon.org/og-image.png' } },
        { tag: 'link', attrs: { rel: 'apple-touch-icon', href: '/apple-touch-icon.png' } },
        { tag: 'link', attrs: { rel: 'manifest', href: '/site.webmanifest' } },
      ],
      sidebar: [
        { label: 'Home', link: '/' },
        { label: 'Start here', items: [
          { label: 'Introduction', slug: 'docs' },
          { label: 'Download', link: '/#omarchy' },
          { label: 'Device support', link: '/devices/' },
          { label: 'Project overview', slug: 'docs/project' },
          { label: 'Attribution', slug: 'docs/attribution' },
          { label: 'Support records', slug: 'docs/hardware' },
        ] },
        { label: 'Linux', slug: 'docs/linux' },
        { label: 'Contribute', items: [
          { label: 'Getting involved', slug: 'docs/contributing' },
          { label: 'Policies & guidelines', slug: 'docs/policies' },
        ] },
      ],
    }),
  ],
});
