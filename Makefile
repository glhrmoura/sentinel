.PHONY: app icon run install clean

app:
	mkdir -p build/Sentinel.app/Contents/MacOS build/Sentinel.app/Contents/Resources
	swiftc -O -parse-as-library -target arm64-apple-macos14.0 Sources/Sentinel/*.swift -o build/sentinel-arm64
	swiftc -O -parse-as-library -target x86_64-apple-macos14.0 Sources/Sentinel/*.swift -o build/sentinel-x86_64
	lipo -create build/sentinel-arm64 build/sentinel-x86_64 -output build/Sentinel.app/Contents/MacOS/Sentinel
	cp Resources/Info.plist build/Sentinel.app/Contents/Info.plist
	cp Resources/AppIcon.icns build/Sentinel.app/Contents/Resources/AppIcon.icns
	codesign --force --sign - build/Sentinel.app

icon:
	rm -rf build/AppIcon.iconset
	swift Tools/make-icon.swift Resources/logo.png build/AppIcon.iconset
	iconutil -c icns build/AppIcon.iconset -o Resources/AppIcon.icns

run: app
	open build/Sentinel.app

install: app
	rm -rf /Applications/Sentinel.app
	cp -R build/Sentinel.app /Applications/Sentinel.app

clean:
	rm -rf build
