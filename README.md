# yuva_classes

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Authentication Setup

This app uses Firebase Auth for primary social/phone login and Supabase Auth for email/password, with runtime environment variables for Supabase (no hardcoded keys).

Run with:

```bash
flutter run \
	--dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
	--dart-define=SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY
```

Expected backend table:

- `students` table with `full_name`, `email`, `phone`, `firebase_uid`, `user_id`, `aspirant_type`, and `created_at`

Auth flow behavior:

- Phone OTP login via Firebase Auth, restricted to Indian numbers (`+91XXXXXXXXXX`)
- Google sign-in via Firebase Auth
- Email/password via Supabase Auth
- Session restore on app startup using the last active auth method
- Student profile sync after every successful login
- Onboarding for new or incomplete student profiles before entering the app
- Password reset via Supabase email flow

Implementation notes:

- Auth state lives in `lib/features/auth/providers/auth_provider.dart`
- Auth service lives in `lib/features/auth/services/auth_service.dart`
- Shared preferences persist the last auth method and pending OTP details
- Legacy auth files re-export the new implementation for compatibility
- For strict duplicate prevention, add unique indexes on `students.email`, `students.phone`, `students.firebase_uid`, and `students.user_id` in Supabase
