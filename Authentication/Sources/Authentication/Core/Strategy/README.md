# Strategy Layer (CredentialInput & CredentialLogin)

**Purpose:** Keep all credential-based auth modules (Local, LDAP, IdP) consistent, tiny, and DRY.

## The Pattern

1. **Parse input + URL** with `CredentialInput.make(...)`
2. **Perform sign-in** with `CredentialLogin.perform(...)`
3. **Map errors** automatically (`HTTPErrorMapper` → `AuthError.toAuthStatusAndMessage`)

```swift
guard
  let req = CredentialInput.make(
    from: params,
    path: "/auth/local/signin",
    defaultBase: AuthDefaults.baseServerUrl
  )
else {
  complete(.unableToAuthenticate, "Missing credentials or server URL!")
  return
}

CredentialLogin.perform(
  url: req.url,
  username: req.username,
  password: req.password,
  unauthorizedMessage: "Invalid username or password.",
  complete: complete
)
