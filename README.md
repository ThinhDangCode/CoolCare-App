# CoolCare Mobile

Flutter mobile application for CoolCare Customer/Technician accounts.

## Sprint 1 — Authentication

- Register Customer account
- Verify registration email with OTP before the first signed-in session
- Login for Customer/Admin credentials
- Logout and clear locally stored JWT
- Forgot password: request email OTP, verify OTP, reset password
- Loading, validation, API and error states

JWT and the signed-in user are stored with `flutter_secure_storage`. The app does not contain demo credentials or mock authentication.

Android support starts at API 23 because secure storage uses Android Keystore AES-GCM. Android backup is disabled to prevent restored encrypted values from losing their device-bound keys. iOS includes Keychain Sharing entitlements for Debug/Profile and Release.

## API configuration

Android emulator defaults to `http://10.0.2.2:3000/api`. Override it for another environment:

```sh
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api
```

Expected endpoints:

| Method | Path | Request | Required response |
| --- | --- | --- | --- |
| POST | `/auth/register` | `fullName`, `email`, `phone`, `password` | 202; sends registration OTP |
| POST | `/auth/register/verify-email` | `email`, `otp` | `data.user`, `data.token` |
| POST | `/auth/register/resend-verification` | `email` | Any 2xx response |
| POST | `/auth/login` | `email`, `password` | `data.user`, `data.token` |
| POST | `/auth/logout` | Bearer token | Any 2xx response |
| POST | `/auth/forgot-password` | `email` | Any 2xx response; do not reveal whether email exists |
| POST | `/auth/forgot-password/verify` | `email`, `otp` | `data.resetToken` |
| POST | `/auth/forgot-password/reset` | `resetToken`, `newPassword` | Any 2xx response |

Run checks:

```sh
flutter analyze
flutter test
```
