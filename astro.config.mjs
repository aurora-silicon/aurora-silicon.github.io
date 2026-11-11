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
      // Support and Blog sit in the docs header, as in the site's main navigation.
      components: { SocialIcons: './src/components/DocsSocialIcons.astro' },
      editLink: {
        baseUrl: 'https://github.com/aurora-silicon/aurora-silicon.github.io/edit/main/',
      },
      head: [
        { tag: 'meta', attrs: { property: 'og:image', content: 'https://aurorasilicon.org/og-image.png' } },
        { tag: 'link', attrs: { rel: 'apple-touch-icon', href: '/apple-touch-icon.png' } },
        { tag: 'link', attrs: { rel: 'manifest', href: '/site.webmanifest' } },
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
        { label: 'Windows', slug: 'docs/windows' },
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
  ],
});
