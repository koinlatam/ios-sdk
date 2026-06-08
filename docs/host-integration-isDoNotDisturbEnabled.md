# Host Integration Guide — `isDoNotDisturbEnabled`

> Step-by-step requirements for an iOS app embedding `KoinFingerprint` to
> receive real `Bool` values (instead of `null`) in
> `mobileApplication.integrity.isDoNotDisturbEnabled`.

---

## 1. Why this is not plug-and-play

Apple designed `INFocusStatusCenter` **exclusively for communication apps**
(messaging, calling). Reading the user's Focus/DND state without the right
configuration returns `null` — not because the SDK is broken, but because iOS
silently keeps `focusStatus.isFocused = false` for non-communication hosts.

Apple's stated intent for this API is to *let users communicate to other
people* whether they're focused — for example, a messaging app showing
"Person is silenced" next to a contact. Using the same signal for fraud
detection, fingerprinting, analytics or any other non-communication purpose
is **outside Apple's declared intent** for the API. The SDK exposes the
value because some hosts may have a legitimate communication-adjacent use
case; whether your specific use qualifies is a decision for your product
and compliance teams, not for this guide.

Verified against:

- [Apple Developer Forums thread 690081](https://developer.apple.com/forums/thread/690081) (Apple engineer response)
- [WWDC21 session 10091](https://developer.apple.com/videos/play/wwdc2021/10091/)
- [Apple Docs — Handling Communication Notifications and Focus Status Updates](https://developer.apple.com/documentation/UserNotifications/handling-communication-notifications-and-focus-status-updates)

---

## 2. What the SDK guarantees regardless of host setup

The SDK never crashes, never displays an OS prompt on its own, and always
emits a valid payload. Hosts that skip the steps below simply receive `null`
for this field. No degradation of other `integrity.*` keys.

---

## 3. The 6 host-side requirements

### 3.1 Apple Developer portal — host App ID

1. Sign in at https://developer.apple.com/account/resources/identifiers/list
2. Open the host App ID (e.g. `<host-bundle-id>`)
3. Scroll to **Communication Notifications** capability → check it
4. Save

### 3.2 Apple Developer portal — Intent Extension App ID (new)

The Intent Extension lives as a separate bundle with its own App ID:

1. Same page → **+** (Register a new identifier)
2. Type: **App IDs** → Continue → **App** → Continue
3. Bundle ID: **Explicit** → `<host-bundle-id>.FocusStatusIntent`
4. Description: `Focus Status Intent Extension`
5. Check **Communication Notifications** capability
6. Continue → Register

### 3.3 Xcode project — Intent Extension target

In the host's Xcode project (or workspace):

1. File → New → Target → **Intents Extension**
2. Product Name: `FocusStatusIntent`
3. Replace the boilerplate `IntentHandler.swift` with:

   ```swift
   import Intents

   class IntentHandler: INExtension {
       override func handler(for intent: INIntent) -> Any { self }
   }

   extension IntentHandler: INSendMessageIntentHandling {
       func handle(intent: INSendMessageIntent,
                   completion: @escaping (INSendMessageIntentResponse) -> Void) {
           completion(INSendMessageIntentResponse(code: .success, userActivity: nil))
       }
   }

   #if os(iOS)
   extension IntentHandler: INStartCallIntentHandling {
       func handle(intent: INStartCallIntent,
                   completion: @escaping (INStartCallIntentResponse) -> Void) {
           completion(INStartCallIntentResponse(code: .continueInApp, userActivity: nil))
       }
   }
   #endif
   ```

4. Edit the extension's `Info.plist` so that `NSExtension.NSExtensionAttributes.IntentsSupported` contains:

   ```xml
   <array>
       <string>INSendMessageIntent</string>
       <string>INStartCallIntent</string>
   </array>
   ```

5. Edit the extension's `.entitlements`:

   ```xml
   <key>com.apple.developer.usernotifications.communication</key>
   <true/>
   ```

6. In the host app target → **Build Phases** → **Embed App Extensions** → confirm the extension is listed (Xcode usually adds this automatically).

### 3.4 Host `Info.plist`

Add the user-facing usage description. The string below is a neutral
placeholder — **customize it for your app's tone and reasoning**:

```xml
<key>NSFocusStatusUsageDescription</key>
<string>This app reads whether a Focus mode is active to better adapt the experience.</string>
```

> Be specific about the user-facing benefit. Vague, generic, or
> surveillance-flavoured text increases the chance of an App Review flag
> and erodes user trust at the OS prompt.

### 3.5 Host `.entitlements`

Add the same capability flag:

```xml
<key>com.apple.developer.usernotifications.communication</key>
<true/>
```

### 3.6 Host code — request authorization once

Call `requestAuthorization` once early in the app lifecycle (e.g. `.onAppear`
of the root SwiftUI view, or `applicationDidFinishLaunching` in UIKit):

```swift
import Intents

if #available(iOS 15.0, *) {
    INFocusStatusCenter.default.requestAuthorization { _ in }
}
```

> The SDK itself **never** calls `requestAuthorization` — it only reads the
> already-granted state via `INFocusStatusCenter.default.focusStatus`.

---

## 4. Validation

After all 6 steps:

1. Run the host on a **physical device** (Focus Status APIs are unreliable on simulator)
2. Accept the OS prompt for "Allow Focus Status access"
3. Activate a Focus mode (Work, DND, Sleep, etc.) from Control Center
4. Trigger a `KoinFingerprinter.profile()` call
5. Check the payload — `mobileApplication.integrity.isDoNotDisturbEnabled` should now be `true`
6. Disable the Focus mode and trigger another profile — should be `false`

---

## 5. Troubleshooting

| Symptom | Likely cause |
|---|---|
| Build error: *"Entitlement com.apple.developer.usernotifications.communication not found"* | Step 3.1 or 3.2 missing in the portal |
| Build succeeds, but `isFocused` is **always `false`** even with Focus active | Step 3.3 missing — the Intent Extension target isn't registered |
| App crashes with *"This app has crashed because it attempted to access privacy-sensitive data without a usage description"* | Step 3.4 missing — `NSFocusStatusUsageDescription` not in `Info.plist` |
| Status stays `.notDetermined` forever | Step 3.6 missing — host never called `requestAuthorization` |
| Payload shows `null` even with everything configured | User denied the OS prompt — request again or accept it from the OS settings |

---

## 6. App Review considerations

Adding **Communication Notifications** capability to a host that is **not** a
communication app (messaging, calling) is **outside Apple's stated purpose**
for the API. Apple has been clear about the intended scope in developer
forums and WWDC sessions: this capability and `INFocusStatusCenter` are
gates for communication apps. Hosts that don't fit that profile but enable
the capability are betting on Apple's tolerance, not on policy alignment.
Plan accordingly.

Possible outcomes during App Review:

- **No issue** — historically Apple has not rejected non-communication apps with this capability
- **Reviewer flag** — be ready to explain the user-facing benefit in plain terms; avoid words like "fingerprinting", "tracking" or "fraud" in the justification
- **Rejection** — has been reported for combinations of this capability with overly aggressive features or with weak/contradictory user-facing rationale

The SDK itself doesn't trigger any of these — the decision belongs entirely to
the host. Align with your compliance and product teams before submission.

---

## 7. Future-proofing

Apple has been hardening the Focus Status API in recent iOS versions. Treat
this signal as **best-effort** — host teams should be ready to fall back to
`null` if a future iOS release tightens the rules further.
