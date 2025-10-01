# Igloo Ventures Corporation Website

Professional one-page website for Igloo Ventures Corporation, a software consulting company in Anchorage, Alaska.

## Local Development

### Prerequisites
- Hugo Extended v0.100.0 or later

### Running Locally

```bash
hugo server -D
```

Visit `http://localhost:1313` to view the site.

### Building for Production

```bash
hugo --gc --minify
```

The built site will be in the `public/` directory.

## Deployment

This site is configured to automatically deploy to GitHub Pages when changes are pushed to the `main` branch.

### Setup GitHub Pages

1. Go to your repository settings
2. Navigate to Pages (under Code and automation)
3. Under "Build and deployment", set Source to "GitHub Actions"
4. Push to main branch - the site will automatically build and deploy

## Structure

- `content/_index.md` - Main page content (About section)
- `hugo.toml` - Site configuration and content for Services, Benefits, and Contact
- `themes/igloo/` - Custom minimal theme
  - `layouts/index.html` - Homepage template
  - `static/css/style.css` - Styling

## Copyright

© 2025 Igloo Ventures Corporation. All rights reserved.
