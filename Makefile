adb=/Applications/adt-bundle-mac-x86_64-20130219/sdk/platform-tools/adb

install:
	$(adb) install -r Android.apk

log:
	$(adb) logcat -s "Unity"
