# 🌐 MN Family App - GitHub Website Publishing Guide

This guide explains how to take your compiled Flutter Web bundle (`mn-family-web-build.zip`) and your Flutter codebase to publish **MN Family App** as a live, publicly accessible website on **GitHub Pages** (free hosting with HTTPS).

---

## 🎯 Your GitHub Repository Details
- **Repository**: [https://github.com/anbuchelvanvk/MN](https://github.com/anbuchelvanvk/MN)
- **Live Website URL**: `https://anbuchelvanvk.github.io/MN/`

---

## 🚀 Method 1: Automated Deployment via GitHub Actions (Recommended)
This is the modern, industry-standard method. Every time you push Flutter code changes to GitHub, GitHub automatically builds the web app and updates the live website.

### Step 1: Push the workflow to GitHub
Open your terminal in `C:\Users\achel\Downloads\mn-family-app` and run:
```powershell
git add .github/workflows/deploy_web.yml
git commit -m "feat: add automated Flutter Web GitHub Pages deployment"
git push origin v2-ui-redesign
```

### Step 2: Enable GitHub Pages in your Repository Settings
1. Open your repository on GitHub: **[https://github.com/anbuchelvanvk/MN](https://github.com/anbuchelvanvk/MN)**
2. Click the **Settings** tab at the top.
3. In the left sidebar, click **Pages** (under the "Code and automation" section).
4. Under **Build and deployment**:
   - Change **Source** to **GitHub Actions**.
5. Go to the **Actions** tab on GitHub:
   - You will see the **"Deploy Flutter Web to GitHub Pages"** workflow running.
   - Once it shows a green checkmark, your website is live!
6. Visit: **`https://anbuchelvanvk.github.io/MN/`**

---

## 📦 Method 2: Deploy Directly Using `gh-pages` Branch
If you want to publish the pre-compiled files from `mn-family-web-build.zip` directly without waiting for GitHub Actions:

### Step 1: Extract and push to `gh-pages` branch
Run these commands in PowerShell inside `C:\Users\achel\Downloads\mn-family-app`:
```powershell
# 1. Create a clean orphan branch for the website files
git checkout --orphan gh-pages

# 2. Clear old files from staging
git rm -rf .

# 3. Extract your pre-built web files into the root
Expand-Archive -Path "C:\Users\achel\Downloads\mn-family-web-build.zip" -DestinationPath "." -Force

# 4. Commit and push the website to GitHub
git add -A
git commit -m "deploy: publish MN Family Flutter Web release"
git push -u origin gh-pages --force

# 5. Return to your development branch
git checkout v2-ui-redesign
```

### Step 2: Configure GitHub Pages
1. Go to **[https://github.com/anbuchelvanvk/MN/settings/pages](https://github.com/anbuchelvanvk/MN/settings/pages)**
2. Under **Build and deployment**:
   - **Source**: Select **Deploy from a branch**
   - **Branch**: Select **`gh-pages`** and folder **`/ (root)`**
   - Click **Save**.
3. In 1–2 minutes, your website will be live at:
   **`https://anbuchelvanvk.github.io/MN/`**

---

## ⚡ Method 3: 1-Click Instant Free Hosting on Netlify (Alternative)
If you need an instant public link in 10 seconds:
1. Go to **[app.netlify.com/drop](https://app.netlify.com/drop)** (no account needed or free signup).
2. Unzip `mn-family-web-build.zip` on your computer.
3. Drag and drop the unzipped folder into the box on the Netlify webpage.
4. Netlify will instantly provide a live HTTPS link (e.g., `https://mn-family-app.netlify.app`).

---

## 🔍 Why `<base href="/MN/">` Matters on GitHub Pages
When hosting a project repository on GitHub Pages, the site URL is:
`https://<username>.github.io/<repository-name>/` (in your case: `https://anbuchelvanvk.github.io/MN/`).

If `<base href="/">` is used instead, the browser looks for `flutter_bootstrap.js` at the domain root (`anbuchelvanvk.github.io/flutter_bootstrap.js`) and shows a blank screen with a 404 error. 

The build we just generated in `mn-family-web-build.zip` has already been pre-compiled with:
```bash
flutter build web --release --base-href "/MN/"
```
and our automated GitHub Action dynamically passes `/${{ github.event.repository.name }}/` so everything loads with 100% precision.

