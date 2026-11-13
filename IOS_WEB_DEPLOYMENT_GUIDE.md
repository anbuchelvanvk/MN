# iOS IPA Cloud CI/CD & Flutter Web Deployment Guide

## 1. Automated iOS .IPA Builds (GitHub Actions Cloud CI/CD)

The automated workflow has been created at:
[`.github/workflows/ios_build.yml`](file:///.github/workflows/ios_build.yml)

### How It Works:
1. **Triggering the Build**:
   - Every time code is pushed to `main` or `master`, GitHub Actions spins up an Apple Silicon macOS runner (`macos-14`).
   - You can also run it manually anytime by going to **GitHub -> Actions tab -> "Build iOS IPA & TestFlight" -> Run workflow**.
2. **Build Process**:
   - Installs Flutter stable & CocoaPods.
   - Runs `flutter build ios --release --no-codesign`.
   - Packages the application into an installable `MNFamilyApp-release.ipa`.
   - Uploads the `.ipa` to GitHub Actions **Artifacts**.
3. **Downloading the .IPA**:
   - Navigate to the **Actions** tab on your GitHub repository.
   - Click the latest workflow run.
   - Scroll to **Artifacts** at the bottom and download `MNFamilyApp-iOS-IPA.zip`. Inside is `MNFamilyApp-release.ipa`.

### Installing on iPhone:
- **Direct Sideloading (Free, No Mac needed)**:
  - Use [Sideloadly](https://sideloadly.io) (Windows/Mac) or [AltStore](https://altstore.io): Connect your iPhone via USB, drag `MNFamilyApp-release.ipa`, enter your Apple ID, and it installs directly onto your iPhone.
- **Over-The-Air (OTA)**:
  - Upload the `.ipa` to [Diawi](https://www.diawi.com) or [InstallOnAir](https://www.installonair.com) and scan the QR code from Safari on your iPhone.
- **Direct TestFlight Deployment (Optional)**:
  - If you have an Apple Developer account, add these repository secrets in **GitHub -> Settings -> Secrets and variables -> Actions**:
    - `APP_STORE_CONNECT_KEY_ID`
    - `APP_STORE_CONNECT_ISSUER_ID`
    - `APP_STORE_CONNECT_PRIVATE_KEY`
  - When running the workflow manually, check **Deploy to TestFlight: true**, and GitHub Actions will upload the build directly to TestFlight for your testers.

---

## 2. Flutter Web Build & Deployment

The web workflow has been created at:
[`.github/workflows/web_build.yml`](file:///.github/workflows/web_build.yml)

### Local Web Build:
- **Build Directory**: `build/web/`
- **Packaged Zip Archives**:
  - [mn-family-web-build.zip (Downloads)](file:///C:/Users/achel/Downloads/mn-family-web-build.zip)
  - [mn-family-web-build.zip (OneDrive)](file:///C:/Users/achel/OneDrive/mn-family-web-build.zip)

### How to Host & Deploy the Web Build:
- **Firebase Hosting**:
  ```bash
  firebase deploy --only hosting
  ```
- **Netlify / Vercel**:
  - Drag and drop the unzipped `build/web` folder directly into the Netlify or Vercel dashboard.
- **cPanel / Apache / Nginx**:
  - Extract `mn-family-web-build.zip` and upload all files directly to your `public_html/` web root.

