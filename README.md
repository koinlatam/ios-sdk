# ios-sdk
Koin's iOS SDK for Mobile Fingerprinting

> **Migrating from `KoinFingerprint`?** Update the pod name in your Podfile to `pod 'KoinAntifraud'`. Your existing Swift code keeps working as is.

See the [CHANGELOG](CHANGELOG.md) for what changed in each version. **1.9.0 changes
the payload contract** (some fields now emit `null`, `extraData.locationServices` was
removed); read it before upgrading.

## Requirements

- iOS 14.0 or later.
- Swift 5.5 or later. Swift Package Manager needs Swift tools 5.9 (Xcode 15 or later).
- App Store uploads require Xcode 26 or later (Apple rule).

> **Xcode 27 and CocoaPods.** Xcode 27 only accepts deployment targets from iOS 15.0,
> while `KoinAntifraud` still declares iOS 14.0, so the generated `KoinAntifraud` pod
> target fails to build. Until the minimum is raised in a future release, add this to
> your `Podfile`:
>
> ```ruby
> post_install do |installer|
>   installer.pods_project.targets.each do |target|
>     target.build_configurations.each do |config|
>       config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
>     end
>   end
> end
> ```
>
> Swift Package Manager and manual integration are not affected.

## Installation

### CocoaPods
KoinAntifraud is available through [CocoaPods](https://cocoapods.org/pods/KoinAntifraud). To install it, simply add the following line to your Podfile:
```ruby
    pod 'KoinAntifraud'
```
Latest versions can be found [here](https://github.com/koinlatam/ios-sdk/releases).
Note: If you want to learn more about CocoaPods for dependency management, check out their [Using CocoaPods](https://guides.cocoapods.org/using/using-cocoapods.html) guide.

### Swift Package Manager

Available from **1.9.0**.

1. In Xcode, choose **File → Add Package Dependencies…**.
2. Enter the package Git URL: `https://github.com/koinlatam/ios-sdk`.
3. Choose **Exact Version** `1.9.0` (or **Up to Next Major** from `1.9.0`).
4. Add the `KoinFingerprint` library product to your target.
5. Import the module:

```swift
import KoinFingerprint
```

The Swift module and SPM product are `KoinFingerprint`. The CocoaPods pod name remains `KoinAntifraud`.

Tags earlier than 1.9.0 have neither a package manifest nor a GitHub Release with
`KoinFingerprint-xcframework.zip`, so they do not resolve through SPM.

Equivalent `Package.swift` dependency:

```swift
.package(url: "https://github.com/koinlatam/ios-sdk.git", exact: "1.9.0")
```

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
For production environments an override of the default URL is needed, [learn more here.](docs/methods.md)

### Profiling

After your organization is registered, you can proceed with profiling the
device to get the `sessionId`.

```swift
let sessionId = KoinFingerprinter.profile()
```

The `sessionId` returned needs to be provided by the backend when using
Koin's Gateway or Fraud Prevention services. Custom sessionId and timeout
can be provided when profiling, [learn more here.](docs/methods.md)

- `profile()` reuses the same `sessionId` for about 20 hours, then creates a new one.
- Every call collects and sends a new payload in the background. There is no
  completion callback; failed uploads are retried up to 3 times.
- The device position is read at `register()`. If the user grants location access
  later, the position appears from the next app launch on.

### .NET MAUI / ObjC interop facade

Available since 1.8.0. When integrating from C# (.NET MAUI Slim Binding / Native
Library Interop), prefer the ObjC-compatible `KoinFingerprintBridge` over calling
`KoinFingerprinter` directly — it exposes explicit overloads (no Swift default
parameters) and Foundation-friendly types:

```objc
NSError *error = nil;
[KoinFingerprintBridge registerWithOrganizationId:@"YOUR_ORG_ID"
                                              url:KoinFingerprintBridge.defaultURL
                               geoLocationEnabled:YES
                                          timeout:5.0
                                            error:&error];
NSString *sessionId = [KoinFingerprintBridge profile];
```

`register` fails with an error when `organizationId` or `url` is blank, and clamps
`timeout` to `KoinFingerprintBridge.minTimeout`; that timeout is reused by every
`profile` call. `profile` returns the session id immediately — collection and upload
continue asynchronously, with no completion callback. A custom session id can be
passed with `profileWithSessionId:error:`.

The bridge always uses the default `FraudConfig`: `geoLocationEnabled` only turns the
`location` section on or off. To disable other sections, integrate through
`KoinFingerprinter` in Swift.

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
on another platform (e.g. Android), the iOS SDK does not emit mock keys.

### Reading the payload

| What you see | Meaning |
|---|---|
| Key absent | The field or section is disabled in `FraudConfig`, or the field does not exist on iOS. In `contacts`, `calendar` and `media`, the counts are also absent when `permission` is not `GRANTED`. |
| Key with `null` | The SDK could not read or classify the value on this device or run (the API failed, timed out, or the host did not grant what the field needs). |
| `0`, `false`, `[]` | The SDK read the value and that is what it is. |
| `permission: "DENIED"` | The host does not hold the authorization (denied, restricted, not determined, or the usage description is missing). The SDK never prompts. |
| `permission: "ERROR"` | Reading the authorization status failed. |

Fields that emit `null` when not captured:

| Field | `null` when |
|-------|-------------|
| `connectivity.connectionType` | the network monitor did not answer in time, or the active interface is none of wifi, cellular and ethernet (`"none"` still means no connectivity) |
| `connectivity.isSimPresent`, `simCount`, `isDualSimActive` | neither the telephony API nor the cellular path answered |
| `hardware.cpuArchitecture` | `sysctl` failed (`"unknown"` still means an unmapped CPU type) |
| `environment.installSource` | no provisioning profile and no receipt were found |
| `crossApplicationUniqueId` | no Metal device is available |
| `integrity.isDebuggerAttached` | `sysctl` failed |
| `integrity.targetApps`, `quantityInstalledApps*` | none of the queried schemes is declared in `LSApplicationQueriesSchemes`, or on the simulator |
| `sensors.accelerometerTemporal`, `gyroscopeTemporal`, `magnetometerTemporal` | the sensor is unavailable or no sample was captured yet |
| `sensors.hasNfc` | reading the NFC availability failed (hosts without the NFC entitlement) |
| `behavioral.touchPatterns`, `scrollPatterns`, `swipePatterns`, `interactionIntervals` | there was no event in the window |

### Privacy-sensitive sections

Some sections read data through Apple frameworks that require **`Info.plist` keys or
entitlements in the host app**. Without them the SDK never touches the underlying
framework — there is no prompt and no crash. **The SDK never triggers a system
permission prompt**: the host requests each authorization at the moment that fits its
UX, and the next `profile()` reflects it.

| Field / section | Host requirement |
|---|---|
| `media` | `NSPhotoLibraryUsageDescription` |
| `contacts` | `NSContactsUsageDescription` |
| `calendar` (events) | `NSCalendarsFullAccessUsageDescription` (iOS 17+) and `NSCalendarsUsageDescription` (iOS 16 and earlier) |
| `calendar` (reminders) | `NSRemindersFullAccessUsageDescription` (iOS 17+) and `NSRemindersUsageDescription` (iOS 16 and earlier) |
| `location` (position) | `NSLocationWhenInUseUsageDescription` |
| `location` (visit metrics) | `NSLocationAlwaysAndWhenInUseUsageDescription` and `Always` authorization (see below) |
| `sensors.barometricPressure` | `NSMotionUsageDescription` and, on iOS 17.4+, the user's Motion & Fitness authorization |
| `integrity.isDoNotDisturbEnabled` | Communication Notifications setup (see below) |
| `integrity.targetApps`, `quantityInstalledApps*` | the queried schemes in `LSApplicationQueriesSchemes` (see below) |
| `integrity.jailbreakIndicators.cydiaAvailable` | `cydia` in `LSApplicationQueriesSchemes` |
| `connectivity.wifiSsid`, `wifiBssid` | the `com.apple.developer.networking.wifi-info` entitlement and location authorization |
| `advertisingId` | `NSUserTrackingUsageDescription` and App Tracking Transparency authorization; otherwise iOS returns a zeroed identifier |

#### `permission` in `contacts`, `calendar`, `media` and `location`

Since 1.9.0 these sections carry `permission` (`"GRANTED"`, `"DENIED"` or `"ERROR"`),
read without prompting and controlled by the `permission` flag of each config
(default `true`; `false` omits the key).

- **`contacts`, `calendar`, `media`:** when the value is not `GRANTED`, the count keys
  are omitted. In `calendar`, `permission` describes the events axis only;
  `eventsRemindersCount` is independent. iOS 17 `.fullAccess` and iOS 18 `.limited`
  are `GRANTED` (limited counts reflect the authorized subset).
- **`location`:** `Always` and `When In Use` are `GRANTED`; use
  `isLocationPermissionsAlways` to tell them apart. A non-`GRANTED` value does **not**
  omit the other `location` keys, which stay `null` when they cannot be read. This
  replaces `metrics.connectivity.extraData.locationServices`, removed in 1.9.0.

#### `location` — visit metrics

`locationVisitsLast7Days`, `frequentLocationsCount` and `avgDailyMovementKm` come
from the SDK's own visit history (`CLLocationManager.startMonitoringVisits()`). They
require `Always` authorization, both location usage descriptions, and
`register(...)` called early in `application(_:didFinishLaunchingWithOptions:)`. No
background mode is needed. The values stay `null` until the monitor has run for at
least 24 hours and then cover a rolling 7-day window, so a high `null` rate is
expected.

#### `sensors` — temporal series

`accelerometerTemporal`, `gyroscopeTemporal` and `magnetometerTemporal` carry up to
5 samples `{x, y, z}`, oldest first, at least 50 ms apart, rounded half-up to 3
decimal places (same contract as the Android SDK).

#### App Review considerations

Defaults are `enabled = true` for parity with the Android SDK, but keeping
`contacts`, `calendar` and `media` enabled in production is subject to App Review
under Guideline 5.1.1 (Data Collection and Storage). Turn a section off
(`enabled = false`) if your app cannot justify that permission to Apple.

### Privacy manifest

The framework ships a `PrivacyInfo.xcprivacy`, which Xcode merges into your app's
privacy report for CocoaPods, SPM and manual integration. It declares the
`UserDefaults` (`CA92.1`) and `FileTimestamp` (`C617.1`) required-reason APIs.

`device.deviceUptime`, `hardware.totalStorage` / `availableStorage` and
`integrity.thirdPartyKeyboardDetected` read required-reason APIs (system boot time,
disk space, active keyboards) that are not declared in 1.9.0 and may trigger an
`ITMS-91053` warning on upload. To avoid it, turn those flags off:

```swift
var config = FraudConfig()
config.device.deviceUptime = false
config.hardware.totalStorage = false
config.hardware.availableStorage = false
config.integrity.thirdPartyKeyboardDetected = false
```

Your App Privacy answers in App Store Connect remain your responsibility, since only
your app knows which sections it enables.

### Payload · `integrity`

#### `targetApps` signal (installed-apps list)

**What it is.** Optional signal at `integrity.targetApps` that reports which
applications from a **curated list of URL schemes** respond to
`UIApplication.shared.canOpenURL`. The signal returns the schemes that match,
in the configured order. On the **simulator** the SDK emits `null` — the query
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
   the host app's `Info.plist`. Declaring none of them makes `targetApps` and the
   three `quantityInstalledApps*` keys come out `null`; declaring only part of the
   list silently **undercounts**.
2. Respect Apple's **~50-entry limit** on `LSApplicationQueriesSchemes` —
   that budget is shared between the SDK's schemes and the host app's own.
3. Account for the **App Review** impact: long lists or sensitive schemes
   may be questioned. Align curation with product/compliance.

<details>
<summary>Default schemes (42)</summary>

```
whatsapp, instagram, fb, tiktok, tg, linkedin, waze, nflx, nordvpn, uberdriver,
ifood.driver, unidriver, meli, mercadopago, shopeebr, nu-branch, picpay,
bancointer, c6bank, itauempresas, itauvarejo, bbapp, santanderpf,
br.gov.caixa.caixamais, com.btg.pactual.banking, appxpinvestimentos,
bradescoapppf, bradescocartoes, bvpd, recarga, crefisamais, pagaleve,
psmyaccount, meugovbr, ectpsmobile, meuinss, caixa.tem, cdt,
br.gov.caixa.caixaloterias, br.gov.caixa.fgm, serasaapp, tp
```

</details>

**How to configure on the SDK.** The signal is toggleable via
`IntegrityConfig.targetApps` (defaults to `true`), and the list of queried
schemes via `IntegrityConfig.targetAppsSchemes`. When `targetAppsSchemes` is
`nil` or empty, the SDK uses its built-in curated default of **42 schemes**. To
customize:

```swift
var config = FraudConfig()
config.integrity.targetApps = true
// nil or [] keeps the SDK's 42 default schemes; pass an array to override:
config.integrity.targetAppsSchemes = ["whatsapp", "instagram", "my-custom-app"]

KoinFingerprinter.register(organizationId: "YOUR_ORG_ID", config: config)
```

#### `isDoNotDisturbEnabled` signal (Focus Status)

**What it is.** Optional signal at `integrity.isDoNotDisturbEnabled` that
reports whether the user has a Focus mode (Do Not Disturb, Work, Sleep,
etc.) active. Type: `Bool | null`. Read via Apple's `INFocusStatusCenter`
(iOS 15+).

**Host-app prerequisites.** Apple restricts this API to **communication
apps**. Without the full setup below the signal is `null` (status not authorized,
or iOS 14) or a constant `false` (status authorized but no Intent Extension) — by
design, not a bug. To receive real values the host must:

1. Enable **Communication Notifications** capability on its App ID
2. Register a separate App ID for an Intent Extension (`<host-bundle-id>.FocusStatusIntent`) with the same capability
3. Add an **Intent Extension** target in Xcode declaring `INSendMessageIntent` / `INStartCallIntent`
4. Add `NSFocusStatusUsageDescription` to the host's `Info.plist`
5. Add `com.apple.developer.usernotifications.communication` to the host's `.entitlements`
6. Call `INFocusStatusCenter.default.requestAuthorization` from the host code

See the [host integration guide](docs/host-integration-isDoNotDisturbEnabled.md)
for the full step-by-step.

> **App Review risk.** The Communication Notifications capability is intended
> for messaging and calling apps. Non-communication hosts (delivery, banking,
> e-commerce) should align with their compliance team before submission.
> Apple has been hardening this API in recent iOS versions — treat the signal
> as best-effort.

**How to configure on the SDK.** The signal is toggleable via
`IntegrityConfig.isDoNotDisturbEnabled` (defaults to `true`). When `false`,
the key is omitted from the payload. Hosts that will not adopt the setup above
can turn it off to avoid sending `null` on every payload. The SDK never calls
`requestAuthorization` on its own — that responsibility lives on the host.

```swift
var config = FraudConfig()
config.integrity.isDoNotDisturbEnabled = false
KoinFingerprinter.register(organizationId: "YOUR_ORG_ID", config: config)
```

#### `thirdPartyKeyboardDetected` — precise signal (optional)

iOS exposes no API to list installed keyboards, so the field is a heuristic by
default. To make it precise, forward the host's extension-point callback; the SDK
always allows the extension and only records it:

```swift
func application(_ application: UIApplication,
                 shouldAllowExtensionPointIdentifier identifier: UIApplication.ExtensionPointIdentifier) -> Bool {
    KoinFingerprinter.shouldAllowExtensionPoint(identifier)
}
```

### Payload · `behavioral` — typing

`typingCadence` and `typingSpeed` capture typing **timing only — never the content**,
from `UITextField`, `UITextView` and other `UIKeyInput` hosts. Typing inside a
`WKWebView` is not captured. Both are `null` until at least two events occur.

## Troubleshooting

| Symptom | Likely cause |
|---|---|
| SPM fails to resolve the package | A version earlier than 1.9.0 is selected. Use `1.9.0` or later. |
| CocoaPods build fails on Xcode 27 with a deployment target error | Add the `post_install` snippet from [Requirements](#requirements). |
| App crashes at launch with *Library not loaded: KoinFingerprint* (manual install) | The framework is not set to *Embed & Sign*. |
| `targetApps` / `quantityInstalledApps*` always `null` | No queried scheme declared in `LSApplicationQueriesSchemes`, or running on the simulator. |
| `contacts`, `calendar` or `media` show `permission: "DENIED"` | The usage description is missing, or the host has not requested / been granted access. |
| `location` coordinates `null` with `permission: "GRANTED"` | Access was granted after `register()`; the position appears from the next launch. |
| Nothing is sent | `register` was not called before `profile`. |
| Sessions are not found in production | The production URL was not passed in `register`; without it, payloads go to the sandbox endpoint. |
