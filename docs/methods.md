# KoinFingerprint Methods

### Register
`register` must be called first, at the end of
`application(_:didFinishLaunchingWithOptions:)`. It stores the organization ID
provided by Koin and the endpoint used by every request.

```swift
// organizationId is required.
// url is optional and overrides the default endpoint.
// config is optional; FraudConfig() collects every field.
KoinFingerprinter.register(organizationId: "YOUR_ORG_ID",
                           url: "KOIN_SERVICES_URL",
                           config: FraudConfig())
```

Pass Koin's production URL in `url` for production builds. Without it, every
profile is sent to the sandbox endpoint (`KoinFingerprinter.DEFAULT_URL`).

`register` also reads the device position once (when `location` is enabled and
the host already holds location authorization). If the user grants location
access later, the position appears from the next app launch on.

### Profile
`profile` gathers the device data and sends it to Koin in the background. It
returns a `sessionId` that your backend must send when calling Koin's Gateway or
Fraud Prevention services, so both sides are associated.

#### Variants

```swift
// Default and recommended approach.
let sessionId = KoinFingerprinter.profile()

// Custom harvest timeout, in seconds.
let sessionId = KoinFingerprinter.profile(timeoutInSeconds: 5.0)

// Custom sessionId. Not recommended; prefer profile().
KoinFingerprinter.profile(sessionId: "YOUR_UNIQUE_SESSION_ID")

// Custom sessionId and timeout. Not recommended; prefer profile(timeoutInSeconds:).
KoinFingerprinter.profile(sessionId: "YOUR_UNIQUE_SESSION_ID", timeoutInSeconds: 5.0)
```

#### Behavior

- **Session reuse:** `profile()` reuses the same `sessionId` for about 20 hours,
  then creates a new one. A custom `sessionId` replaces the stored one and starts
  a new 20-hour window.
- **One upload per call:** every `profile` call collects and sends a new payload,
  even when the `sessionId` is reused.
- **Fire-and-forget:** there is no completion callback. Network failures are
  retried up to 3 times (after 5, 10 and 15 seconds).
- **Timeout:** the default and minimum is `KoinFingerprinter.MIN_TIMEOUT`
  (1 second). A lower value is raised to 1 second.
- **Not registered:** calling `profile` before `register` sends nothing.

A custom `sessionId` must be unique. We strongly suggest letting the SDK
generate it.

### Third-party keyboard signal (optional)
To make `integrity.thirdPartyKeyboardDetected` precise, forward the host's
extension-point callback. The SDK always allows the extension and only records
it:

```swift
func application(_ application: UIApplication,
                 shouldAllowExtensionPointIdentifier identifier: UIApplication.ExtensionPointIdentifier) -> Bool {
    KoinFingerprinter.shouldAllowExtensionPoint(identifier)
}
```

### Objective-C / .NET MAUI facade
`KoinFingerprintBridge` (since 1.8.0) exposes the same flow with explicit
overloads and Foundation types, for Slim Binding / Native Library Interop:

```objc
NSError *error = nil;
[KoinFingerprintBridge registerWithOrganizationId:@"YOUR_ORG_ID"
                                              url:KoinFingerprintBridge.defaultURL
                               geoLocationEnabled:YES
                                          timeout:5.0
                                            error:&error];

NSString *sessionId = [KoinFingerprintBridge profile];

// Custom sessionId (not recommended):
[KoinFingerprintBridge profileWithSessionId:@"YOUR_UNIQUE_SESSION_ID" error:&error];
```

- `register` fails with an error when `organizationId` or `url` is blank.
- The `timeout` passed to `register` (raised to `KoinFingerprintBridge.minTimeout`
  when lower) is reused by every `profile` call.
- The bridge always uses the default `FraudConfig`; `geoLocationEnabled` only
  turns the `location` section on or off. To disable other sections, integrate
  through `KoinFingerprinter` in Swift.
