Rxaa Menu - iOS Debug Overlay
=============================

WHAT THIS IS
------------
A Theos tweak project named Rxaa. It adds a small floating icon button to apps.
Tapping it opens a native Rxaa list with AimLock/ESP/Radar demo switches, a
"Get Code" row, an "All Features" browser, and Apply All / Reset All demo
actions. All Features reads menu_catalog.json and lists the 108 catalog feature
entries grouped by category; actionable entries have UI-only switches. Get Code
opens the offline WebKit browser containing the menu-name/code catalog. The
button icon is generated from menu_image.jpg.

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
  3. The .deb appears in ./packages/ (normally
     com.rxaa.menudebug_1.2.0_iphoneos-arm.deb).
  4. Install it on a jailbroken device with Filza, Sileo, or:
       dpkg -i packages/*.deb
       killall -9 SpringBoard

  Rootless jailbreak (iOS 15+, Dopamine/palera1n):
       make clean package FINALPACKAGE=1 THEOS_PACKAGE_SCHEME=rootless

Build fix: The earlier "missing a filter property list" stage error is fixed by
RAACHEATMenuDebug.plist in the project root.

Option B: GitHub Actions (no Mac required)
  Push this folder to a GitHub repository. The included workflow uses a macOS
  runner, installs Theos, builds both a rootful and a rootless .deb, and uploads
  two separate artifacts: Rxaa-rootful-deb and Rxaa-rootless-deb.
  See .github/workflows/build-deb.yml.

INSTALL NOTES
-------------
- Requires a jailbroken iOS 14+ device with MobileSubstrate/ElleKit.
- The tweak filter is RAACHEATMenuDebug.plist. It matches apps linked against
  com.apple.UIKit.
- The overlay waits for an active UIWindowScene, then adds the floating button.
  It retries for about 60 seconds and also retries when the app becomes active.
- Fallback opening gesture: triple-tap with four fingers anywhere in the app.
  This opens Rxaa even if the floating button is covered or off-screen.
- The AimLock switch is a visual demo. It is ON/OFF only for the menu; there is
  no aimbot, memory write, or game hook behind it.
- All Features lists the 108 feature entries from menu_catalog.json: 63
  actionable rows have UI-only switches, and 45 label/help rows are read-only.
- Install the artifact that matches the jailbreak:
    * rootful jailbreak -> Rxaa-rootful-deb
    * rootless jailbreak (Dopamine/palera1n) -> Rxaa-rootless-deb
- If the Rxaa icon does not appear:
    * make sure the correct rootful/rootless package was installed
    * respring/reboot userspace, then force-quit and reopen the app
    * check that the package is installed
    * check the catalog files exist at one of the two paths above
    * check the tweak is enabled in your jailbreak's tweak injector
    * check Console/log output for messages beginning with [Rxaa]
- If the app does not link UIKit, add that app's bundle identifier to the
  Bundles array in RAACHEATMenuDebug.plist. Do not use com.apple.Security unless
  you really need every process, because it injects much more broadly.
- The floating button's window is pass-through outside the button, so it does
  not block the underlying app. The Rxaa list itself opens as a full-screen
  modal with its own Close button.

SAFETY
------
This project is a static code browser, not a game cheat. Do not use the original
cracked APK on a personal device. Game cheating violates the game's rules and
can get the account banned.
