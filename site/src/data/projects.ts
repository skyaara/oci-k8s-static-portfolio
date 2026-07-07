export type Project = {
  slug: string;
  title: string;
  description: string;
  date: string;
  tags: string[];
  url?: string;
  repo?: string;
  body: string;
};

export const projects: Project[] = [
  {
    slug: 'portfolio-k8s',
    title: 'Portfolio on Oracle Free Tier Kubernetes',
    description: 'Static Astro site built into an nginx image, deployed to OKE with Cloudflare DNS.',
    date: '2026-07-07',
    tags: ['astro', 'kubernetes', 'oci', 'terraform'],
    repo: 'https://github.com/YOUR_GITHUB_USERNAME/portfolio',
    body: `Static Astro portfolio baked into an nginx Docker image and served on Oracle Always Free OKE. Cloudflare handles DNS and TLS; external-dns syncs the Load Balancer IP.`,
  },
];
