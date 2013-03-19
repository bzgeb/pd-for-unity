adb=/Applications/adt-bundle-mac-x86_64-20130219/sdk/platform-tools/adb
pdforunity=Android/PdForUnity/bin/pdforunity.jar
unity=/Applications/Unity/Unity.app/Contents/MacOS/Unity

install: apk
	$(adb) install -r Android.apk

log:
	$(adb) logcat -s "Unity"

#pdcore:
#	cp -f $(pdcore) Assets/Plugins/Android/

pdforunity:
	cp -f $(pdforunity) Assets/Plugins/Android/

apk: pdforunity
	$(unity) -quit -batchmode -executeMethod CommandBuild.BuildAndroid
