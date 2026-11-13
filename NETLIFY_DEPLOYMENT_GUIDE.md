# 🌐 Netlify + GitHub Web Deployment Guide
**MN Jewel Park Family Ecosystem App**

This guide explains how to connect your **GitHub repository** (`https://github.com/anbuchelvanvk/MN`) to **Netlify** to host your Flutter web application with global edge caching, automated HTTPS, and instant live updates.

---

## ⚡ Option 1: Automatic Continuous Deployment (GitHub + Netlify)
Every time you push code to your GitHub repository, Netlify automatically updates your live website.

### Step 1: Sign in to Netlify
1. Go to **[https://app.netlify.com/](https://app.netlify.com/)**.
2. Sign in or sign up using your **GitHub account** (this makes importing repositories 1-click).

### Step 2: Import your GitHub Repository
1. On the Netlify Dashboard, click **Add new site** → **Import an existing project**.
2. Choose **GitHub** as your Git provider.
3. Select your repository: **`anbuchelvanvk/MN`** (or search for `MN`).
4. Configure your build settings:
   - **Branch to deploy**: `v2-ui-redesign` (or `main`)
   - **Base directory**: *(leave empty)*
   - **Build command**: *(Netlify will automatically detect `netlify.toml`)*
   - **Publish directory**: `build/web`
5. Click **Deploy MN**.

Netlify will assign a live URL like `https://mn-family-app.netlify.app`.

---

## 🚀 Option 2: Instant 10-Second Drag & Drop (Netlify Drop)
If you just want your website live right this minute without configuring GitHub permissions:

1. Open **[https://app.netlify.com/drop](https://app.netlify.com/drop)** in your web browser.
2. On your computer, open your **Downloads** folder:
   - Find `mn-family-web-build.zip` (located at `C:\Users\achel\Downloads\mn-family-web-build.zip`).
   - Right-click and choose **Extract All** (or open the `build/web` directory in `mn-family-app`).
3. Drag the unzipped folder and drop it into the Netlify Drop box.
4. Your website will be live in **5 seconds** with a free SSL certificate!

---

## ⚙️ How SPA Routing & Redirects Work
Flutter Web uses client-side routing. We have included a [`netlify.toml`](file:///c:/Users/achel/Downloads/mn-family-app/netlify.toml) file in your repository:
```toml
[[redirects]]
  from = "/*"
  to = "/index.html"
  status = 200
```
This ensures that if a user reloads the browser while on `/login`, `/ceo`, or any subpage, Netlify serves `index.html` and Flutter cleanly restores the route without showing a "404 Page Not Found" error.

---

## 🏷️ Custom Domain Setup (Optional)
To use your own company domain (e.g. `family.mnjpark.com`):
1. In your Netlify site dashboard, go to **Domain management** → **Add custom domain**.
2. Enter your domain name.
3. Add the CNAME record in your domain DNS registrar (GoDaddy, Cloudflare, Namecheap, etc.) pointing to your Netlify site.
4. Netlify will automatically generate a free Let's Encrypt SSL/TLS certificate.
