# Changelog

Integrator-facing changes of `KoinAntifraud` / `KoinFingerprint`. Earlier versions are
listed on the [releases page](https://github.com/koinlatam/ios-sdk/releases).

## [1.9.0]

### Breaking payload changes

Consumers of the payload must handle these before upgrading:

- **`metrics.connectivity.extraData.locationServices` removed.** `metrics.connectivity`
  now carries only `dispatchedAt` and `executionTime`. The permission signal moves to
  `location.permission` (see Added). The position read time is no longer reported.
- **Fields that now emit `null` when not captured** (aligned with the Android SDK):
  - `connectivity.connectionType` (was `"unknown"`);
  - `connectivity.isSimPresent`, `simCount`, `isDualSimActive` (were `false` / `0` / `false`);
  - `hardware.cpuArchitecture` and `environment.installSource` (were `"unknown"`);
  - `crossApplicationUniqueId` (was `""`);
  - `integrity.isDebuggerAttached` (was `false`);
  - `integrity.targetApps` and `quantityInstalledApps*` (were `[]` and `0`), when the
    host declares no queried scheme in `LSApplicationQueriesSchemes`, and on the simulator;
  - the `*Temporal` series in `sensors` (key was omitted or `[]`);
  - `behavioral.touchPatterns`, `scrollPatterns`, `swipePatterns`, `interactionIntervals`
    (were `[]`).

  `0`, `false` and `[]` still mean "captured, and this is the value".
- **`sensors.hasNfc` can be `null`** (was always `Bool`). See Fixed.
- **`contacts`, `calendar` and `media` omit their counts** when `permission` is not
  `GRANTED` (they were sent as `null`). See Added.

### Added

- **Swift Package Manager.** Add `https://github.com/koinlatam/ios-sdk`, product and
  module `KoinFingerprint`. 1.9.0 is the first tag with a package manifest. CocoaPods
  (`KoinAntifraud`) and manual installation are unchanged.
- **`permission` in `contacts`, `calendar` and `media`**: `"GRANTED"`, `"DENIED"` or
  `"ERROR"`, controlled by the `permission` flag of each config (default `true`).
  In `calendar` it describes the events axis only; `eventsRemindersCount` is
  independent. The SDK still never prompts.
- **`permission` in `location`**: same values, read from
  `CLLocationManager.authorizationStatus` without prompting. `Always` and `When In Use`
  are `GRANTED`. Controlled by `LocationConfig.permission` (default `true`). Unlike the
  other three sections, a non-`GRANTED` value does not omit the other `location` keys.
- **`sensors.accelerometerTemporal`, `gyroscopeTemporal`, `magnetometerTemporal`**: up
  to 5 samples `{x, y, z}` per axis, oldest first, at least 50 ms apart, rounded half-up
  to 3 decimal places. A disabled flag omits the key; an axis without hardware emits
  `null`.
- **Privacy manifest**: `PrivacyInfo.xcprivacy` now declares the `UserDefaults`
  (`CA92.1`) and `FileTimestamp` (`C617.1`) required-reason APIs. See the README for the
  fields whose APIs are not declared yet.

### Changed

- **Typing timing** (`behavioral.typingCadence` / `typingSpeed`) is now also recorded in
  `UIKeyInput` hosts that are neither `UITextField` nor `UITextView`. Timing only, never
  the content. Typing inside `WKWebView` is not captured.

### Fixed

- **Host app crash** caused by an Objective-C exception while reading NFC availability
  in hosts without the NFC entitlement. Exceptions raised inside any collector are now
  contained: the field is dropped (`sensors.hasNfc` becomes `null`) and the app keeps
  running.

### Notes

- **Minimum iOS stays 14.0.** On Xcode 27, which only accepts iOS 15.0+, CocoaPods hosts
  need the `post_install` snippet in the README. SPM and manual installation are not
  affected.
- **Host requirements** for `sensors.barometricPressure` (`NSMotionUsageDescription` and,
  on iOS 17.4+, Motion & Fitness authorization) and `integrity.isDoNotDisturbEnabled`
  (Communication Notifications setup) are documented in the README. Without the Intent
  Extension, `isDoNotDisturbEnabled` can be a constant `false` instead of `null`.

## [1.8.0]

### Changed

- **`behavioral.typingCadence`** now emits the **average** inter-event delta (ms, number
  or `null`) instead of the array of deltas.

### Added

- **`KoinFingerprintBridge`**: an Objective-C compatible facade for .NET MAUI Slim
  Binding / Native Library Interop.
- **Extended behavioral collection**: `appForegroundTimeRatio`, `sessionStartHour`,
  `timeToFirstInteractionMs`, `touchXVariance`, `touchYVariance`, `tapPressureAvg`,
  `tapPressureVariance`, `clipboardChangeCount`.
- `device.fontScale`, `hardware.cameraCount`, `isFrontCameraAvailable`,
  `isBackCameraAvailable`, `environment.audioOutputType`, `mediaVolume`.
