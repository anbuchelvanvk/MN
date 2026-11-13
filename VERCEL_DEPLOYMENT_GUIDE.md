# ▲ Vercel + GitHub Web Deployment Guide
**MN Jewel Park Family Ecosystem App**

This guide explains how to connect your **GitHub repository** (`https://github.com/anbuchelvanvk/MN`) to **Vercel** to host your Flutter web application on Vercel's global edge network with instant previews, automated HTTPS, and zero downtime deployments.

---

## 🚀 Option 1: Automatic Continuous Deployment (GitHub + Vercel)
Every time you push code to your GitHub repository, Vercel automatically deploys the latest version.

### Step 1: Open Vercel Project Import
1. Go to **[https://vercel.com/new](https://vercel.com/new)**.
2. Log in with your **GitHub account** (or connect your GitHub).

### Step 2: Import your Repository
1. Under "Import Git Repository", search for and select **`anbuchelvanvk/MN`** (or `MN`).
2. Click **Import**.

### Step 3: Configure Project Settings
Vercel will automatically read our [`vercel.json`](file:///c:/Users/achel/Downloads/mn-family-app/vercel.json) file:
- **Framework Preset**: `Other`
- **Root Directory**: `./`
- **Output Directory**: `build/web` (pre-configured in `vercel.json`)
3. Click **Deploy**!

Vercel will build and assign you a live production URL, such as:
`https://mn-family-app.vercel.app` (or `https://mn-five.vercel.app`).

---

## ⚡ Option 2: Instant 10-Second CLI Deploy (No Git required)
If you want to push your existing production build to Vercel directly from your command line:

Run this command in PowerShell inside `C:\Users\achel\Downloads\mn-family-app`:
```powershell
npx vercel deploy build/web --prod
```
- It will ask you to confirm your Vercel account or log in via browser.
- Once authenticated, it immediately uploads `build/web` and gives you a live production URL in **under 15 seconds**!

---

## 🛠️ How `vercel.json` Powers Single-Page Apps (SPA)
Flutter Web uses client-side routing. We have created a [`vercel.json`](file:///c:/Users/achel/Downloads/mn-family-app/vercel.json) file in your repository:
```json
{
  "cleanUrls": true,
  "trailingSlash": false,
  "rewrites": [
    {
      "source": "/(.*)",
      "destination": "/index.html"
    }
  ],
  "headers": [
    {
      "source": "/assets/(.*)",
      "headers": [{ "key": "Cache-Control", "value": "public, max-age=31536000, immutable" }]
    },
    {
      "source": "/(.*).(js|wasm)",
      "headers": [{ "key": "Cache-Control", "value": "public, max-age=31536000, immutable" }]
    }
  ]
}
```

### Why this is essential:
- **No 404 on Refresh**: When users reload the page on `/login`, `/ceo`, or any portal, Vercel serves `index.html` so Flutter's router handles the page seamlessly.
- **Maximum Performance**: WebAssembly (`.wasm`) and JavaScript bundles are cached immutably for blazing-fast subsequent page visits.

---

## 🏷️ Adding a Custom Domain on Vercel
1. Go to your project dashboard on Vercel: **Settings** → **Domains**.
2. Enter your custom domain (e.g. `family.mnjewelpark.com`).
3. Add the suggested CNAME or A record in your DNS provider (GoDaddy, Cloudflare, etc.).
4. Vercel automatically provisions and renews SSL certificates for free.
