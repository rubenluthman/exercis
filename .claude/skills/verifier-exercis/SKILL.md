# Verifier — Exercis

Protocol for verifying that a change works in the running Exercis app (iOS simulator).

**Note:** Ruben's primary testing is on a physical iPhone 17. This skill uses the iPhone 17 simulator — functional but slower. Face ID cannot be triggered in the simulator, so the lock screen is bypassed (simulator uses passcode fallback or `lockEnabled` can be disabled).

---

## 1. Build

From the repo root:

```bash
xcodebuild \
  -project Exercis.xcodeproj \
  -scheme Exercis \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -configuration Debug \
  build 2>&1 | tail -20
```

Exit code must be 0. If the build fails, abort verification and report the build error.

---

## 2. Launch

Kill any running instance, boot the simulator, and install + launch the app:

```bash
# Boot iPhone 17 simulator
xcrun simctl boot "iPhone 17" 2>/dev/null || true

# Wait for Simulator.app to be ready (open it so computer-use can screenshot it)
open -a Simulator

# Give simulator time to fully boot (first run: up to 30s; subsequent: ~5s)
sleep 15

# Install the freshly built app
APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name "Exercis.app" -path "*/Debug-iphonesimulator/*" | head -1)
xcrun simctl install booted "$APP_PATH"

# Terminate any existing instance, then launch
xcrun simctl terminate booted rubenluthman.Exercis 2>/dev/null || true
xcrun simctl launch booted rubenluthman.Exercis

# Wait for the app to settle
sleep 3
```

Take a screenshot via computer-use to confirm the app is on screen before proceeding.

---

## 3. Computer-use setup

```
request_access: ["Simulator"]
reason: "Verifying Exercis iOS app behavior after code change"
```

Simulator is a native app — use `mcp__computer-use__*` tools (screenshot, left_click, type). The simulator window may need to be brought forward with `open -a Simulator`.

---

## 4. Scenarios

### S1 — App launches and reaches the tab bar

**What to do:** Take a screenshot immediately after launch.  
**Expected:** LockView is shown (black screen, "EXERCIS" in Jost Black at center) **or** MainTabView with four tabs (Training · History · Profile · Settings) if `lockEnabled` is false in the simulator.  
**Pass:** Either LockView or MainTabView is visible; the app has not crashed to the home screen.  
**Fail:** Home screen or springboard is visible (crash at launch).

**Simulator workaround:** Face ID does not work in the simulator. If LockView appears and blocks further testing, disable the lock by setting `lockEnabled = false` in UserDefaults before launch:
```bash
xcrun simctl spawn booted defaults write rubenluthman.Exercis lockEnabled -bool false
xcrun simctl terminate booted rubenluthman.Exercis 2>/dev/null || true
xcrun simctl launch booted rubenluthman.Exercis
sleep 3
```

---

### S2 — Training tab is visible and shows content

**What to do:** Tap the "Training" tab (leftmost tab in the tab bar).  
**Expected:** TrainingView is shown. STRENGTH section lists program cards (or an empty-state message). CARDIO section lists cardio type cards.  
**Pass:** At least one of STRENGTH or CARDIO sections is visible with content or an empty-state.  
**Fail:** White screen, crash, or missing sections.

---

### S3 — History tab loads without crashing

**What to do:** Tap the "History" tab (second tab).  
**Expected:** HistoryView header "HISTORY" is visible. Either session rows grouped by month, or an empty state.  
**Pass:** Header visible, no crash.  
**Fail:** Blank screen or crash.

---

### S4 — Profile tab renders stats

**What to do:** Tap the "Profile" tab (third tab).  
**Expected:** ProfileView shows the top stats row (STRENGTH · VOLUME · CARDIO · TIME), streak section with number and 14-day dots, and personal records list (or empty states for all of these if no data exists).  
**Pass:** Top stats row is visible.  
**Fail:** Missing stat labels or crash.

---

## 5. Cleanup

```bash
xcrun simctl terminate booted rubenluthman.Exercis 2>/dev/null || true
```

Leave the simulator booted (avoids a slow re-boot on the next run).

---

## 6. Report format

```
Verdict: PASS | FAIL
Scenarios tested: S1, S2, S3, S4
Build: OK | FAILED (paste error)
Evidence:
  - S1: [screenshot description or paste]
  - S2: [screenshot description]
  - S3: [screenshot description]
  - S4: [screenshot description]
Findings:
  - [any unexpected behavior, even if not a hard failure]
```
