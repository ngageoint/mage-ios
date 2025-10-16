# Auth Obsolescence Ledger

> Any removal must be listed here with justification and a replacement path.

| Item | Why it’s obsolete | Replacement | User impact | Removal PR |
|---|---|---|---|---|
| `AuthenticationButton` (+ delegate) | Strategy selection is owned by modern `IDPCoordinator`/SwiftUI; duplicate abstraction | `IDPCoordinator` APIs and SwiftUI entry points | None; UI routes are equivalent | PR9 |
| Obj-C XIB login/signup screens | Replaced by SwiftUI screens with equivalent validation, CAPTCHA, and error flows | `LoginViewSwiftUI`, `SignupViewSwiftUI` | None; parity proven before removal | PR9 |
| AFNetworking (auth paths) | Superseded by URLSession client with same endpoints and error mapping | `AuthHTTPClient` | None; contract parity tests pass | PR10 |
