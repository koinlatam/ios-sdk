# ios-sdk
Koin's iOS SDK for Mobile Fingerprinting

### Installation (CocoaPods)
KoinFingerprint is available through [CocoaPods](https://cocoapods.org/pods/KoinFingerprint). To install it, simply add the following line to your Podfile:
```ruby
    pod 'KoinFingerprint'
```
Lastest versions can be found [here](https://github.com/koinlatam/ios-sdk/releases)    
Note: If you want to learn more about CocoaPods for dependency management, check out their [Using CocoaPods](https://guides.cocoapods.org/using/using-cocoapods.html) guide.

### Manually
- Get the latest release from [here](https://github.com/koinlatam/ios-sdk/releases)
- Open the folder location of downloaded `KoinFingerprint-xcframework.zip` and unzip it.
- Drag the `KoinFingerprint.xcframework` into the Project Navigator of you Xcode project.
- When prompt with the options for adding files:
  Make sure that `Copy items if needed` is checked, as well as the target you want to add the library to.
- Check your target's "*Frameworks, Libraries, and Embedded Content*" section and make sure the library embed option is set to "*Embed & Sign*"
  If the framework does not appear there, click the `+` button and select it from the list of available frameworks
- Check your target's "*Build Phases*" section and make sure the library was added to the "*Link Binary With Libraries*" status is set to "*Required*"
  If the framework does not appear there, click the `+` button and select it from the list of available frameworks

## Usage

First, import the library on you AppDelegate or main file 
```swift
import KoinFingerprint
```

Now, initiate the beacon at the end of `didFinishLaunchingWithOptions` or `applicationDidFinishLaunching`:
```swift
KoinFingerprinter.register(organizationId: "YOUR_ORG_ID")
```
For production environments an override of the default url is needed, [learn more here.](https://github.com/koinlatam/ios-sdk/wiki/KoinFingerprint-Methods)

After your organization is registered, you can proceed with profiling the device to get the sessionId.
```swift
let sessionId = KoinFingerprinter.profile()
```
The sessionId returned needs to be provided by the backend when using Koin's Gateway or Fraud Prevention services.
Custom sessionId and timeout can be provided when profiling, [learn more here.](https://github.com/koinlatam/ios-sdk/wiki/KoinFingerprint-Methods)
