PACKAGE := com.bubble.skybubbleburst

.PHONY: run release build clean logs

# ── Android emulator — debug ──────────────────────────────────────────────────
run:
	@echo "→ Uninstalling old APK to free emulator storage..."
	-@adb shell pm uninstall $(PACKAGE) 2>/dev/null || true
	@echo "→ Running arm64 debug build..."
	fvm flutter run

# ── Android emulator — release ───────────────────────────────────────────────
release:
	@echo "→ Uninstalling old APK to free emulator storage..."
	-@adb shell pm uninstall $(PACKAGE) 2>/dev/null || true
	@echo "→ Running arm64 release build..."
	fvm flutter run --release

# ── Build release APK (for manual install / testing) ─────────────────────────
build:
	fvm flutter build apk --target-platform android-arm64 --release

# ── Clean build artifacts ─────────────────────────────────────────────────────
clean:
	fvm flutter clean

# ── Clear emulator storage manually ──────────────────────────────────────────
clear-storage:
	@echo "→ Clearing app data..."
	-@adb shell pm clear $(PACKAGE) 2>/dev/null || true
	@echo "→ Clearing package manager caches..."
	-@adb shell pm clear com.android.providers.downloads 2>/dev/null || true
	@echo "Done."

# ── Logcat filtered to this app ───────────────────────────────────────────────
logs:
	adb logcat --pid=`adb shell pidof -s $(PACKAGE)` -v color
