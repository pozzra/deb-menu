Rxaa Menu - iOS Debug Overlay
=============================

WHAT THIS IS
------------
A Theos tweak project named Rxaa. It adds a small floating icon button to apps.
Tapping it opens a native Rxaa list with AimLock/ESP/Radar demo switches and a
"Code Catalog" row. The Code Catalog opens the offline WebKit browser containing
the menu-name/code catalog. The button icon is generated from menu_image.jpg.

The switches are UI-only. They save ON/OFF in NSUserDefaults and update the
label; they do not hook, read, or write any game process.

This is a UI-only debug/reference tool. It contains:
  - no game hooks
  - no process memory reads or writes
  - no aimbot, ESP, silent aim, or game offsets
  - no injector and no anti-cheat bypass

It is also not a compiled .deb. This machine is Windows and has no Theos,
clang, iOS SDK, ldid, or jailbreak packaging toolchain, so a working iOS binary
cannot be produced here. This folder is the buildable source.

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
     com.rxaa.menudebug_1.1.0_iphoneos-arm.deb).
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
  them as the artifact RxaaMenuDebug-deb. See .github/workflows/build-deb.yml.

INSTALL NOTES
-------------
- Requires a jailbroken iOS 14+ device with MobileSubstrate/ElleKit.
- The tweak filter is RAACHEATMenuDebug.plist and targets apps linked against
  com.apple.UIKit. This satisfies Theos's required filter-plist stage.
- The overlay is injected into processes that have UIApplication. It waits
  about 1.5 seconds after process start, then adds the floating button.
- The AimLock switch is a visual demo. It is ON/OFF only for the menu; there is
  no aimbot, memory write, or game hook behind it.
- If the Rxaa icon does not appear in a specific app, that process may not link
  UIKit. Change the Bundles entry in RAACHEATMenuDebug.plist to that app's bundle
  identifier, or use com.apple.Security to target all processes.
- If the Rxaa icon does not appear:
    * check that the package is installed
    * check the catalog files exist at one of the two paths above
    * respring/reboot userspace
    * check the tweak is enabled in your jailbreak's tweak injector
- The floating button's window is pass-through outside the button, so it does
  not block the underlying app. The Rxaa list itself opens as a full-screen
  modal with its own Close button.

SAFETY
------
This project is a static code browser, not a game cheat. Do not use the original
cracked APK on a personal device. Game cheating violates the game's rules and
can get the account banned.
