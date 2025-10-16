# Auth Parity Matrix (Legacy Obj-C/AFN → New Swift/URLSession/SwiftUI)

> Source of truth for auth migration. No PR may regress any “✅ parity” item.

## Legend
- Legacy: behavior in Obj-C/AFNetworking code today
- New: behavior target in Swift/URLSession/SwiftUI code
- Status: ❓(pending), 🧪(tests landed), ✅(parity proven), ⚠️(needs decision)
- Gate: feature flag or build config used to control rollout

---

### Core Flows

| Area | Legacy (Obj-C/AFN) | New (Swift) | Status | Gate | Notes |
|---|---|---|---:|:---:|---|
| **Local Login** | Username+password → token persisted (`MageSessionManager.setToken`, `StoredPassword`). Errors map to alerts. | Same contract; token persisted via new `CredentialStore`. Same error mapping or equivalent wording. | ❓ | — | Preserve strings semantically (exact match not required). iOS 16+. |
| **IDP (initial)** | Coordinator + web view returns token; uses legacy coordinator. | New `IDPCoordinator` with same entry/exit semantics (OIDC first). | ❓ | `authNextGenEnabled` | Scope = OIDC first; confirm SAML later. |
| **Signup + CAPTCHA** | Captcha always visible; refresh on username change; policy feedback; server 401/409 handling. | Same behavior; always show CAPTCHA; same 401/409 handling; password policy checks. | ❓ | `authNextGenEnabled` | Keep “always visible CAPTCHA” invariant. |

---

### Session / Token Handling

| Area | Legacy | New | Status | Gate | Notes |
|---|---|---|---:|:---:|---|
| **Token use** | `MageSessionManager` & `MageSession` add bearer, validate responses. | URLSession client adds bearer; same validation outcomes. | ❓ | — | Same exempt paths: signin/authorize/devices/password/auth/token. |
| **Token expiry reaction** | No silent refresh. If online login and 401: `expireToken` + post `MAGETokenExpiredNotification`. If offline login and 401: post `MAGEServerContactedAfterOfflineLogin`. | Same notifications fired, same branching. | ❓ | — | Derived from `MageSessionManager.m` and `MageSession.swift`. |
| **Offline login** | Allowed if password cached; token reused offline until server is contacted. | Same; no forced ping at launch; honors offline mode semantics. | ❓ | — | Confirm exact cached-password signal we will key off. |
| **Logout** | Clears keychain + in-mem token; forces login. | Same. | ❓ | — | — |

---

### Change Password

| Area | Legacy | New | Status | Gate | Notes |
|---|---|---|---:|:---:|---|
| **Change Password Screen** | Validates required fields, mismatch, current=new; strength meter via `DBZxcvbn`. Calls `PUT /api/users/myself/password`. On success: modal → logout. | Same validation & endpoint semantics; migrate UI to SwiftUI later; parity first. | ❓ | `authNextGenEnabled` (when migrated) | Until migration, legacy VC remains. |

---

### Server & Environment

| Area | Legacy | New | Status | Gate | Notes |
|---|---|---|---:|:---:|---|
| **Server picker** | User can switch servers at login. Nothing purged until a new valid server is set or switch is canceled. | Same; “commit on success” semantics; otherwise keep prior state. | ❓ | — | Maintain exact semantics. |
| **Minimum Server** | ≥ 6.0 required for new flows. | Target endpoints assume v6+. | 🧪 | — | Documented constraint. |
| **Minimum iOS** | iOS 16 | iOS 16 | ✅ | — | No shims needed. |

---

### Legal & Analytics

| Area | Legacy | New | Status | Gate | Notes |
|---|---|---|---:|:---:|---|
| **EULA** | Must be agreed before or immediately after first login. | Same gate remains; no bypass. | ❓ | — | Confirm exact screen/timing. |
| **Analytics** | Username and authorizationToken tracked (where applicable). | Same events (names/params) preserved. | ⚠️ | — | Need exact event names & locations. |

---

## Notifications to Preserve

- `MAGETokenExpiredNotification` — fired when a valid online session gets a 401 and we expire the token.
- `MAGEServerContactedAfterOfflineLogin` — fired when offline-mode user hits server and receives 401.

We must prove, via tests, these still fire under the same conditions.

---

## Test Plan Index (to be added as PRs land)

- Unit: `CredentialStore`, error mapping, password policy.
- Integration (stubbed): AFN vs URLSession contract tests for `/login`, `/users/signups`, `/verifications`, `/users/myself/password`.
- UI: ViewInspector for SwiftUI login/signup (fields, disabled states, error text).
- Notification tests: token-expiry → notifications above.

