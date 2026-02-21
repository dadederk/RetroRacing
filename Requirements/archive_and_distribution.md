# Archive and Distribution (iOS, watchOS, macOS)

## Overview

RetroRacing ships as one app in App Store Connect with **multiple platforms**: iPhone/iPad (iOS), Apple Watch (watchOS), and Mac (macOS). The **RetroRacingUniversal** target builds for iOS, macOS, and visionOS; the **RetroRacingWatchOS** target builds for watchOS and is **embedded** in the iOS app when you archive for iOS.

Because of that, you need **two separate archives** to get everything into TestFlight/App Store:

1. **iOS archive** (destination: **Any iOS Device**) → contains **iPhone/iPad app + watchOS app** (watch app is inside the iOS app bundle).
2. **macOS archive** (destination: **Any Mac**) → contains **Mac app only**.

You then upload **both** archives to the same app version in App Store Connect.

---

## 1. Submitting for macOS

**Yes — you need to archive using Any Mac.**

- **RetroRacingUniversal** has `SUPPORTED_PLATFORMS = iphoneos iphonesimulator macosx xros xrsimulator`. So one target, multiple platforms, but **one archive = one platform**.
- When you choose **Any iOS Device** and Archive, you get an **iOS** archive (no Mac build inside it).
- When you choose **Any Mac (Apple Silicon, Intel)** and Archive, you get a **macOS** archive.

**Steps for macOS:**

1. In Xcode, set the run destination to **Any Mac (Apple Silicon, Intel)**.
2. **Product → Archive**.
3. When the archive finishes, **Window → Organizer** → select the new archive.
4. **Distribute App** → App Store Connect → upload. This adds the **Mac** build to your app version.
5. In App Store Connect, the same version will then show both an **iOS** build (from the iOS archive) and a **Mac** build (from this archive).

So: **one archive per platform**. To have both iOS+watchOS and macOS, you do **two archives** and **two uploads** (or add the second build to the same version).

---

## 2. watchOS: Why you only see the iOS build

The watch app **does not** show up as a separate build in TestFlight. It is **inside** the iOS build:

- You archive **once** with **Any iOS Device**.
- That archive contains **RetroRacingUniversal.app** (or the .ipa), and **inside** it there is a **Watch** folder with **RetroRacingWatchOS.app**.
- You upload **that one archive** to App Store Connect.
- TestFlight shows **one build** (e.g. “iOS”). When testers install the **iOS** app, the **watchOS** app is available to install from the Watch app on their iPhone.

So “I only see the iOS build” can mean two different things:

- **Expected:** You see one build in TestFlight (e.g. “iPhone, iPad”) — that build **includes** the watch app; testers get the watch app when they install the iOS app. ✅
- **Problem:** The watch app was **not** embedded, so the archive doesn’t contain it. Then you need to fix the archive process (see below).

---

## 3. Making sure the watch app is in the iOS archive

If you’re not sure whether the watch app is inside your iOS archive, or if TestFlight/Organizer suggests only iOS:

### 3.1 Destination must be **Any iOS Device**

- In the toolbar, set the run destination to **Any iOS Device (arm64)** (or **Generic iOS Device**).
- **Do not** use a simulator or “My Mac”.
- Then **Product → Archive**.

If you archive with “My Mac” or a simulator, you will **not** get the watch app (and for “My Mac” you get a Mac-only archive).

### 3.2 Scheme must build the watch target for Archive

- **Product → Scheme → Edit Scheme…** (or ⌘<).
- Select **Build** in the left column (this is where the Targets list lives; it applies to Run, Archive, etc.).
- Ensure these targets are in the list and **checked** for Archive (and Run):
  - **RetroRacingUniversal**
  - **RetroRacingWatchOS** (must be in the list — if missing, click + and add it)
  - **RetroRacingShared** (as dependency)
- If you **do not see RetroRacingWatchOS** in the Targets list (only RetroRacingUniversal entries), click the **+** under the list, select **RetroRacingWatchOS** from the RetroRacing project, click **Add**, and ensure its **Archive** checkbox is checked. Find Implicit Dependencies often does not add the watch target for the scheme.
- Close the scheme editor and archive again with **Any iOS Device**.

### 3.3 Verify the archive on disk

After archiving with **Any iOS Device**:

1. **Window → Organizer** → select the archive.
2. Right-click the archive → **Show in Finder**.
3. Right-click the `.xcarchive` → **Show Package Contents**.
4. Go to **Products/Applications/**.
5. You should see **RetroRacingUniversal.app** (or an .ipa). Right-click it → **Show Package Contents**.
6. Inside the app bundle there must be a **Watch** folder, and inside that **RetroRacingWatchOS.app**.

If **Watch/RetroRacingWatchOS.app** is missing, the watch target was built but the Embed Watch Content step did not copy it into the bundle. Try:

1. **Clean and re-archive:** **Product → Clean Build Folder** (⇧⌘K), set destination to **Any iOS Device**, then **Product → Archive** again.
2. **Build log:** When archiving, open the **Report navigator** (last tab) and select the archive build. Search the log for **"Embed Watch Content"** or **"RetroRacingWatchOS.app"** to see whether the copy step ran and if it reported an error (e.g. file not found).
3. **Scheme build order:** In **Edit Scheme → Build**, ensure **RetroRacingWatchOS** is in the list and is built **before** RetroRacingUniversal (dependency order should do this; if not, drag Watch above Universal).

**Why the Watch folder can be missing:** The **Embed Watch Content** build file can be filtered with an invalid/over-broad platform expression, so the phase is skipped for iOS archive builds even though the watch target itself is compiled.

### 3.4 Embed Watch Content build phase

The project is already set up correctly:

- **RetroRacingUniversal** target → **Build Phases** → **Embed Watch Content** copies **RetroRacingWatchOS.app** into `$(CONTENTS_FOLDER_PATH)/Watch`.
- Configure the embedded watch app build file with **`platformFilter = ios`** (not a negated list). This ensures the copy phase runs for iOS archive builds.
- Keep **RetroRacingWatchOS** as a target dependency of **RetroRacingUniversal** so the watch app is built before embed.

---

## 4. Summary checklist

| Goal | Destination | Action |
|------|-------------|--------|
| **iOS + watchOS** | **Any iOS Device (arm64)** | Product → Archive. Upload this archive. The **one** build includes the watch app. |
| **macOS** | **Any Mac (Apple Silicon, Intel)** | Product → Archive (separate archive). Distribute App → add this build to the same app version. |

- **Two archives** for iOS+watchOS and macOS.
- **One upload** for the iOS archive (watch is inside it).
- **One upload** for the Mac archive (or add Mac build to the same version).
- In App Store Connect, the version will show builds for **iOS** (with watch) and **macOS**.
- In TestFlight, testers see one iOS build (watch installs from the Watch app) and one Mac build if you added it.

---

## 5. App Store Connect

- For the **app version**, enable **iOS**, **macOS**, and **Apple Watch** in the Platforms section if your app supports them.
- For **Apple Watch**, you can enable “Supports Running Without iOS App Installation” if the watch app is standalone; otherwise leave it off for a companion app.
- The **iOS** build you upload (from the iOS archive) is what provides the watch app; you do **not** upload a separate “watchOS” build.
