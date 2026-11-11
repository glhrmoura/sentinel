.PHONY: app icon run install clean

LSREGISTER = /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister

app:
	mkdir -p build/Sentinel.app/Contents/MacOS build/Sentinel.app/Contents/Resources
	swiftc -O -parse-as-library -target arm64-apple-macos14.0 Sources/Sentinel/*.swift -o build/sentinel-arm64
	swiftc -O -parse-as-library -target x86_64-apple-macos14.0 Sources/Sentinel/*.swift -o build/sentinel-x86_64
	lipo -create build/sentinel-arm64 build/sentinel-x86_64 -output build/Sentinel.app/Contents/MacOS/Sentinel
	cp Resources/Info.plist build/Sentinel.app/Contents/Info.plist
	cp Resources/AppIcon.icns build/Sentinel.app/Contents/Resources/AppIcon.icns
	cp Resources/Assets.car build/Sentinel.app/Contents/Resources/Assets.car
	codesign --force --sign - build/Sentinel.app

icon:
	swift Tools/make-icon.swift Resources/logo.png Resources/AppIcon.icon/Assets/art.png
	rm -rf build/icon && mkdir -p build/icon
	xcrun actool Resources/AppIcon.icon --compile build/icon --platform macosx --minimum-deployment-target 14.0 --app-icon AppIcon --output-partial-info-plist build/icon/partial.plist
	cp build/icon/AppIcon.icns Resources/AppIcon.icns
	cp build/icon/Assets.car Resources/Assets.car

run: app
	open build/Sentinel.app

install: app
	rm -rf /Applications/Sentinel.app
	cp -R build/Sentinel.app /Applications/Sentinel.app
	$(LSREGISTER) -u build/Sentinel.app
	$(LSREGISTER) -f /Applications/Sentinel.app

clean:
	rm -rf build
