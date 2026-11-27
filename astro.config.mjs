import { defineConfig } from 'astro/config';
import react from '@astrojs/react';

export default defineConfig({
  site: 'https://cismgpyrbo.github.io',
  base: '/Repository',
  integrations: [react()],
  output: 'static'
});