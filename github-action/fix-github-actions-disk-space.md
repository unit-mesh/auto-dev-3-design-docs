# Fix: GitHub Actions "No Space Left on Device" Error

## Problem
GitHub Actions workflow failed with:
```
System.IO.IOException: No space left on device : '/home/runner/actions-runner/cached/_diag/Worker_20251110-081310-utc.log'
```

## Root Cause
Kotlin Multiplatform project builds generate massive amounts of files:
- **mpp-core**: JS/JVM/Android artifacts (~500MB-1GB)
- **mpp-ui**: Compose Multiplatform with Android/Desktop targets (~2-3GB)
- **mpp-server**: Fat JAR with all dependencies (~100-200MB)
- **Gradle caches**: Dependencies and transforms (~2-5GB)
- **node_modules** (via Kotlin/JS): pnpm packages (~500MB-1GB)
- **Android build outputs**: APKs, intermediate files (~1-2GB)

Total: **~8-15GB** per build, exhausting GitHub's default runner disk (~14GB free).

## Solution Applied

### 1. **Free Disk Space Before Each Job**
Added `jlumbroso/free-disk-space@main` action to remove unused packages:
- ✅ Removes: Android SDK (on non-Android jobs), .NET, Haskell, Docker images, large packages
- 💾 Frees: **~14GB** of disk space
- ⚠️ For `build-android` job: Keep Android SDK (`android: false`)

```yaml
- name: Free Disk Space (Ubuntu)
  uses: jlumbroso/free-disk-space@main
  with:
    tool-cache: false
    android: true  # false for build-android job
    dotnet: true
    haskell: true
    large-packages: true
    docker-images: true
    swap-storage: true
```

### 2. **Clean Build Artifacts After Each Build**
Added cleanup steps after each Gradle build:
```yaml
- name: Clean build cache to save space
  run: |
    ./gradlew :mpp-ui:clean
    rm -rf ~/.gradle/caches/modules-2/files-2.1
    rm -rf ~/.gradle/caches/transforms-*
    df -h
```

### 3. **Disable Gradle Cache in CI**
```yaml
- name: Setup Gradle
  uses: gradle/actions/setup-gradle@v4
  with:
    cache-disabled: true  # Don't cache in CI (saves disk)
```

### 4. **Use Gradle --no-daemon**
Prevents Gradle daemon from consuming extra memory/disk:
```yaml
./gradlew :mpp-core:assemble --no-daemon
```

## Changes Made

### Modified: `.github/workflows/compose-release.yml`
- ✅ Added disk cleanup to all 3 jobs: `build-server`, `build-android`, `build-desktop`
- ✅ Added `--no-daemon` to all Gradle commands
- ✅ Disabled Gradle cache (`cache-disabled: true`)
- ✅ Clean build artifacts after each build step

## Expected Results
- **Before**: ~14GB free → Build fails at 70-80%
- **After**: ~28GB free (14GB initial + 14GB freed) → Build completes successfully

## Disk Usage Breakdown (Estimated)
```
Initial free space:        14 GB
+ Cleanup (free-disk-space): +14 GB
= Total available:         28 GB

Build consumption:
- mpp-core:                 ~1 GB
- mpp-server:               ~2 GB
- mpp-ui (Android):         ~3 GB
- mpp-ui (Desktop x3):      ~6 GB (2GB per OS)
= Total needed:            ~12 GB

Final margin:              ~16 GB (safe)
```

## Testing
To test the fix:
```bash
# Trigger workflow manually
git tag compose-test-$(date +%Y%m%d-%H%M%S)
git push origin --tags

# Or use workflow_dispatch
# Go to Actions → MPP Release → Run workflow
```

## Alternative Solutions (Not Implemented)

### Option A: Use Larger Runners
- GitHub-hosted larger runners (4-core, 16GB RAM, 150GB SSD)
- Cost: ~$0.008/min vs $0.008/min for standard
- ❌ Not needed after cleanup optimization

### Option B: Self-Hosted Runner
- Requires dedicated server with 50GB+ disk
- ❌ Overkill for current project

### Option C: Split into Smaller Jobs
- Separate workflows for each platform
- ❌ Increases complexity, slower overall

## References
- [jlumbroso/free-disk-space](https://github.com/jlumbroso/free-disk-space)
- [Gradle Best Practices in CI](https://docs.gradle.org/current/userguide/ci_best_practices.html)
- [GitHub Actions Runner Specs](https://docs.github.com/en/actions/using-github-hosted-runners/about-github-hosted-runners)
