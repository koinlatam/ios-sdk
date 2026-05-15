# ios-sdk
Koin's iOS SDK for Mobile Fingerprinting

> **Migrating from `KoinFingerprint`?** Update the pod name and version in your Podfile to `pod 'KoinAntifraud', '~> 1.5.0'`. Your existing Swift code keeps working as is.

## Installation

### CocoaPods
KoinAntifraud is available through [CocoaPods](https://cocoapods.org/pods/KoinAntifraud). To install it, simply add the following line to your Podfile:
```ruby
    pod 'KoinAntifraud'
```
Latest versions can be found [here](https://github.com/koinlatam/ios-sdk/releases).
Note: If you want to learn more about CocoaPods for dependency management, check out their [Using CocoaPods](https://guides.cocoapods.org/using/using-cocoapods.html) guide.

### Manually
- Get the latest release from [here](https://github.com/koinlatam/ios-sdk/releases).
- Open the folder location of downloaded `KoinFingerprint-xcframework.zip` and unzip it.
- Drag the `KoinFingerprint.xcframework` into the Project Navigator of your Xcode project.
- When prompted with the options for adding files:
  Make sure that `Copy items if needed` is checked, as well as the target you want to add the library to.
- Check your target's "*Frameworks, Libraries, and Embedded Content*" section and make sure the library embed option is set to "*Embed & Sign*". If the framework does not appear there, click the `+` button and select it from the list of available frameworks.
- Check your target's "*Build Phases*" section and make sure the library is listed under "*Link Binary With Libraries*" with its status set to "*Required*". If the framework does not appear there, click the `+` button and select it from the list of available frameworks.

## Usage

First, import the library in your AppDelegate or main file:
```swift
import KoinFingerprint
```

### Basic registration

Now, initiate the beacon at the end of `didFinishLaunchingWithOptions` or `applicationDidFinishLaunching`:
```swift
KoinFingerprinter.register(organizationId: "YOUR_ORG_ID")
```
For production environments an override of the default URL is needed, [learn more here.](https://github.com/koinlatam/ios-sdk/wiki/KoinFingerprint-Methods)

### Registration with granular configuration

Starting in 1.4.0, `register` accepts an optional `FraudConfig` that lets you
enable or disable individual fields within each section of the payload.

By default, `FraudConfig()` collects everything — so you only need to provide
a config when you want to turn something off.

**Recommended: configure via initializer** (concise, declarative):

```swift
let config = FraudConfig(
    connectivity: ConnectivityConfig(wifiSsid: false, wifiBssid: false),
    behavioral: BehavioralConfig(enabled: false)
)

KoinFingerprinter.register(
    organizationId: "YOUR_ORG_ID",
    url: "YOUR_PRODUCTION_URL",
    config: config
)
```

**Alternative: mutate properties after instantiation** (useful when flags
come from runtime values, feature flags, etc.):

```swift
var config = FraudConfig()
config.behavioral.enabled = false
config.connectivity.wifiSsid = false
config.connectivity.wifiBssid = false

KoinFingerprinter.register(organizationId: "YOUR_ORG_ID", config: config)
```

Every section exposes an `enabled` flag plus one boolean per field. Fields
disabled via `FraudConfig` are omitted from the payload. When a field exists only
on another platform (e.g. Android), the iOS SDK does not emit mock keys — parity is
documented in the product backlog / ticket, not as placeholder values in the payload.

### Payload · `integrity`

#### `targetApps` signal (installed-apps list)

**What it is.** Optional signal at `integrity.targetApps` that reports which
applications from a **curated list of URL schemes** respond to
`UIApplication.shared.canOpenURL`. The signal returns the schemes that match,
in the configured order. On the **simulator** the SDK emits `[]` — the query
is not reliable outside a physical device. Detection is limited by design:
Apple only allows inspecting previously declared schemes, and most Brazilian
apps (banks, fintechs, gov) now publish only **Universal Links** — those are
**not detectable** through `canOpenURL` and fall outside the signal's reach.

The list is not a list of app names or bundle IDs — it is a list of **URL
schemes** (e.g. `whatsapp`, `instagram`, `nu-branch`). The SDK ships with a
curated default validated on a physical device; you can override it with
your own list when needed.

**Host-app prerequisites.** For the signal to work, the app embedding the
SDK must:

1. Declare **every desired scheme** inside `LSApplicationQueriesSchemes` in
   the host app's `Info.plist`. Without this declaration the system silently
   denies the query and the signal becomes noise.
2. Respect Apple's **~50-entry limit** on `LSApplicationQueriesSchemes` —
   that budget is shared between the SDK's schemes and the host app's own.
3. Account for the **App Review** impact: long lists or sensitive schemes
   may be questioned. Align curation with product/compliance.

**How to configure on the SDK.** The signal is toggleable via
`IntegrityConfig.targetApps` (defaults to `true`), and the list of queried
schemes via `IntegrityConfig.targetAppsSchemes`. When `targetAppsSchemes` is
`nil`, the SDK uses its built-in curated default of **42 schemes** validated
on a physical device (Brazilian antifraud scope). To customize:

```swift
var config = FraudConfig()
config.integrity.targetApps = true
// nil keeps the SDK's 42 default schemes; pass an array to override:
config.integrity.targetAppsSchemes = ["whatsapp", "instagram", "my-custom-app"]

KoinFingerprinter.register(organizationId: "YOUR_ORG_ID", config: config)
```

### Profiling

After your organization is registered, you can proceed with profiling the
device to get the `sessionId`.

```swift
let sessionId = KoinFingerprinter.profile()
```

The `sessionId` returned needs to be provided by the backend when using
Koin's Gateway or Fraud Prevention services. Custom sessionId and timeout
can be provided when profiling, [learn more here.](https://github.com/koinlatam/ios-sdk/wiki/KoinFingerprint-Methods)
