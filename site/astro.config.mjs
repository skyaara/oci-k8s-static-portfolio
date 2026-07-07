// @ts-check
import { defineConfig } from 'astro/config';
import sitemap from '@astrojs/sitemap';

const site = 'https://www.example.com';

export default defineConfig({
  site,
  output: 'static',
  integrations: [sitemap()],
});
