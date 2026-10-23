Rxa Menu - iOS Debug Overlay
============================
Contact / Telegram: @kun_amra

WHAT THIS IS
------------
A Theos tweak project named Rxa. It adds a small floating icon button to apps.
Tapping it opens a native Rxa list with AimLock/ESP/Radar demo switches, a
"Get Code" row, an "All Features" browser, a Telegram @kun_amra link, and Apply All / Reset All demo
actions. All Features prefers menu_catalog.json, falls back to an embedded
116-entry feature table if the JSON cannot be read, and lists the entries
grouped by category; actionable entries have UI-only switches. Get Code opens
the offline WebKit browser containing the menu-name/code catalog. The menu is
presented full screen and refreshes its overlay bounds when the scene rotates
or resizes. When the game changes windows or returns from a match, the small
button window is re-shown; the full-screen overlay is raised only while the
menu is open and stays hidden otherwise. The floating button can be
dragged anywhere on screen; its position is saved and clamped inside the safe
area. The button lives in its own 52x52 window, and the full-screen menu window
is hidden while the menu is closed, so game touches are not blocked outside the
button. The button icon is generated from menu_image.jpg.

The switches are UI-only. They save ON/OFF in NSUserDefaults and update the
label; they do not hook, read, or write any game process.

Function reference: functions.txt documents every function/method in Tweak.x and
the embedded HTML/JavaScript catalog.

This is a UI-only debug/reference tool. It contains:
  - no game hooks
  - no process memory reads or writes
  - no aimbot, ESP, silent aim, or game offsets
  - no injector and no anti-cheat bypass

No local .deb is produced on this Windows machine; it has no Theos, clang, iOS
SDK, ldid, or jailbreak packaging toolchain. Use the included GitHub Actions
workflow or a macOS/Linux Theos install.

WHAT GETS PACKAGED
------------------
layout/Library/Application Support/RAACHEATMenuDebug/
  index.html          self-contained catalog app
  menu_catalog.json   single data store
  menu_catalog.csv    spreadsheet export
  build_info.json     metadata
  menu_image.jpg      original menu icon
  menu_icon.png       192x192 icon used by the floating button
  mod_menu.py         optional Python CLI/config generator

layout/usr/bin/
  rxa-menu            terminal launcher for mod_menu.py

The tweak reads the catalog from:
  /var/jb/Library/Application Support/RAACHEATMenuDebug/index.html   (rootless)
  /Library/Application Support/RAACHEATMenuDebug/index.html          (rootful)

BUILD OPTIONS
-------------
Option A: macOS or Linux with Theos
  1. Install Theos:
       https://theos.dev/docs/installation
     You also need an iOS SDK in $THEOS/sdks and ldid.
  2. From this folder:
       export THEOS=$HOME/theos
       make clean package FINALPACKAGE=1
  3. The .deb appears in ./packages/. Run ./build_deb.sh instead of make if
     you want it copied to packages/Rxaa.deb automatically.
  4. Install it on a jailbroken device with Filza, Sileo, or:
       dpkg -i packages/Rxaa.deb
       killall -9 SpringBoard

  Rootless jailbreak (iOS 15+, Dopamine/palera1n):
       THEOS_PACKAGE_SCHEME=rootless ./build_deb.sh
  The rootless copy is packages/Rxaa-rootless.deb.

Build fix: The earlier "missing a filter property list" stage error is fixed by
RAACHEATMenuDebug.plist in the project root.

Option B: GitHub Actions (no Mac required)
  Push this folder to a GitHub repository. The included workflow uses a macOS
  runner, installs Theos, builds both a rootful and a rootless .deb, and uploads
  two artifacts. The rootful artifact contains Rxaa.deb; the rootless artifact
  contains Rxaa-rootless.deb. See .github/workflows/build-deb.yml.

INSTALL NOTES
-------------
- Requires a jailbroken iOS 14+ device with MobileSubstrate/ElleKit.
- The tweak filter is RAACHEATMenuDebug.plist. It matches apps linked against
  com.apple.UIKit.
- The overlay waits for an active UIWindowScene, then adds the floating button.
  It retries for about 60 seconds and also retries when the app becomes active.
- Fallback opening gesture: triple-tap with four fingers anywhere in the app.
  This opens Rxaa even if the floating button is covered or off-screen.
- Drag the floating button to move it. Tap it without dragging to open the menu.
  The position is remembered per app and is clamped to the screen safe area.
- While the menu is open, it is full screen and intentionally captures game
  touches. Tap Close to dismiss it; the full-screen window is hidden again and
  the game receives touches outside the floating button.
- The AimLock switch is a visual demo. It is ON/OFF only for the menu; there is
  no aimbot, memory write, or game hook behind it.
- All Features lists the 116 feature entries from menu_catalog.json, or the
  embedded fallback copy if the JSON is missing/unreadable: 70 actionable rows
  have UI-only switches, and 46 label/help rows are read-only.
- The menu is forced to UIModalPresentationFullScreen. If the device rotates or
  the scene resizes, the overlay window, root view, and floating button bounds
  are refreshed.
- The overlay listens for app activation, scene activation, and key/visible
  window changes. If the game creates a new match window, the 52x52 button
  window is kept at UIWindowLevelAlert + 101 while the full-screen overlay
  remains hidden unless the menu is open.
- Install the artifact that matches the jailbreak:
    * rootful jailbreak -> Rxaa.deb
    * rootless jailbreak (Dopamine/palera1n) -> Rxaa-rootless.deb
- If the Rxaa icon does not appear:
    * make sure the correct rootful/rootless package was installed
    * respring/reboot userspace, then force-quit and reopen the app
    * check that the package is installed
    * check the catalog files exist at one of the two paths above
    * check the tweak is enabled in your jailbreak's tweak injector
    * check Console/log output for messages beginning with [Rxaa]
- If the menu disappears after joining a match, install the 1.2.5 build
  (the button re-shows itself when the game swaps key/visible windows). If it
  still disappears, the game may be using a separate process or scene; send the
  target bundle ID and [Rxaa] logs for diagnosis.
- If game controls stop responding, tap the menu's Close button. The full-screen
  menu intentionally captures touches while open; 1.2.5 hides that window after
  Close and leaves only the 52x52 button window, so the game is clickable again.
  If controls are still blocked, send a screenshot and [Rxaa] logs.
- If the app does not link UIKit, add that app's bundle identifier to the
  Bundles array in RAACHEATMenuDebug.plist. Do not use com.apple.Security unless
  you really need every process, because it injects much more broadly.
- The floating button uses a small button-only window. The full-screen overlay
  window is hidden while the menu is closed, so the game is clickable everywhere
  except the 52x52 button. The Rxaa list itself opens as a full-screen modal
  with its own Close button.

SAFETY
------
This project is a static code browser, not a game cheat. Do not use the original
cracked APK on a personal device. Game cheating violates the game's rules and
can get the account banned.
