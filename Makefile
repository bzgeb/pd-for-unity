adb=/Applications/adt-bundle-mac-x86_64-20130219/sdk/platform-tools/adb
pdcore=~/Developer/pd-for-android/PdCore/bin/pdcore.jar
unity=/Applications/Unity/Unity.app/Contents/MacOS/Unity

install: apk
	$(adb) install -r Android.apk

log:
	$(adb) logcat -s "Unity"

pdcore:
	cp -f $(pdcore) Assets/Plugins/Android/

apk: pdcore
	$(unity) -quit -batchmode -executeMethod CommandBuild.BuildAndroid
