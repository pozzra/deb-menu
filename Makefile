TARGET = iphone:clang:latest:14.0
ARCHS = arm64 arm64e

INSTALL_TARGET_PROCESSES = SpringBoard

TWEAK_NAME = RAACHEATMenuDebug
RAACHEATMenuDebug_FILES = Tweak.x
RAACHEATMenuDebug_FRAMEWORKS = UIKit WebKit
RAACHEATMenuDebug_CFLAGS = -fobjc-arc

include $(THEOS)/makefiles/common.mk
include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
