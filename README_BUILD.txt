RAACHEAT Menu Code - iOS Debug Overlay
======================================

WHAT THIS IS
------------
A Theos tweak project that adds a small floating "R" button to apps. Tapping it
opens an offline WebKit overlay containing the RAACHEAT menu-name/code catalog.

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
     com.raacheat.menudebug_1.0.0_iphoneos-arm.deb).
  4. Install it on a jailbroken device with Filza, Sileo, or:
       dpkg -i packages/*.deb
       killall -9 SpringBoard

  Rootless jailbreak (iOS 15+, Dopamine/palera1n):
       make clean package FINALPACKAGE=1 THEOS_PACKAGE_SCHEME=rootless

Option B: GitHub Actions (no Mac required)
  Push this folder to a GitHub repository. The included workflow uses a macOS
  runner, installs Theos, builds both a rootful and a rootless .deb, and uploads
  them as one artifact. See .github/workflows/build-deb.yml.

INSTALL NOTES
-------------
- Requires a jailbroken iOS 14+ device with MobileSubstrate/ElleKit.
- The overlay is injected into processes that have UIApplication. It waits
  about 1.5 seconds after process start, then adds the floating button.
- If the R button does not appear:
    * check that the package is installed
    * check the catalog files exist at one of the two paths above
    * respring/reboot userspace
    * check the tweak is enabled in your jailbreak's tweak injector
- The overlay is intentionally pass-through outside its button/panel so it does
  not block the underlying app.

SAFETY
------
This project is a static code browser, not a game cheat. Do not use the original
cracked APK on a personal device. Game cheating violates the game's rules and
can get the account banned.
