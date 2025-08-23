.PHONY: app icon run install clean

app:
	mkdir -p build/Vigilant.app/Contents/MacOS build/Vigilant.app/Contents/Resources
	swiftc -O -parse-as-library -target arm64-apple-macos14.0 Sources/Vigilant/*.swift -o build/vigilant-arm64
	swiftc -O -parse-as-library -target x86_64-apple-macos14.0 Sources/Vigilant/*.swift -o build/vigilant-x86_64
	lipo -create build/vigilant-arm64 build/vigilant-x86_64 -output build/Vigilant.app/Contents/MacOS/Vigilant
	cp Resources/Info.plist build/Vigilant.app/Contents/Info.plist
	cp Resources/AppIcon.icns build/Vigilant.app/Contents/Resources/AppIcon.icns
	codesign --force --sign - build/Vigilant.app

icon:
	swift Tools/make-icon.swift build/AppIcon.iconset Resources/logo.png
	iconutil -c icns build/AppIcon.iconset -o Resources/AppIcon.icns

run: app
	open build/Vigilant.app

install: app
	rm -rf /Applications/Vigilant.app
	cp -R build/Vigilant.app /Applications/Vigilant.app

clean:
	rm -rf build
