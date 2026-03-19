# OrphanAge - Orphanage Management Application

Production-style Flutter application for managing an orphanage with role-based access, Supabase backend, and responsive UI.

## 1. Overview

The app manages:
- Children records
- Staff records
- Donations
- Adoptions
- Role-based authentication and user approval
- Admin dashboard with analytics and quick actions

Tech stack:
- Frontend: Flutter (Material UI)
- Backend logic: Dart (inside Flutter app)
- Cloud DB/Auth/Realtime: Supabase

---

## 2. Run The App

### Prerequisites
- Flutter SDK (stable)
- Android Studio or VS Code + Android SDK
- Supabase project with SQL schema applied

### Install dependencies
```bash
flutter pub get
```

### Run
```bash
flutter run --dart-define=SUPABASE_URL=YOUR_SUPABASE_URL --dart-define=SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY
```

If `SUPABASE_URL` / `SUPABASE_ANON_KEY` are missing, app shows configuration help screen.

---

## 3. Authentication & Session Flow

### Registration
1. User opens Register mode.
2. Enters: full name, email, password, role (`staff` / `donor` / `adopter`).
3. App calls `supabase.auth.signUp(...)`.
4. DB trigger `handle_new_user()` inserts user profile into `public.users`.
5. Role fan-out trigger logic also inserts into role table:
   - `staff` -> `public.staff`
   - `donor` -> `public.donors`
   - `adopter` -> `public.adopters`
   - `admin` -> `public.admin_users` (for admin account provisioning)

### Login
1. App calls `signInWithPassword`.
2. Reads role from `public.users`.
3. Checks approval status:
   - `admin` can enter directly
   - Non-admin must be `approved`
4. Inserts login event into `public.login_logs`.
5. Routes by role:
   - `admin` -> Dashboard
   - `staff` -> Staff Home
   - `donor` -> Donor Home
   - `adopter` -> Adopter Home

### Special Admin Shortcut (current implementation)
- Static credential shortcut exists:
  - Email: `admin@gmail.com`
  - Password: `Admin@123456`
- It still performs real Supabase login before opening dashboard.

### Session Persistence
- Supabase session is reused on app restart.
- Guarded routes redirect unauthorized users to login.

---

## 4. Role Model & Intent

### Admin
Intent:
- Full operational control.

Access:
- Full dashboard analytics
- All CRUD modules (children/staff/donations/adoptions)
- Approve pending registered users
- Realtime login notifications

### Staff
Intent:
- Day-to-day operational visibility.

Access:
- View children
- View staff
- Role home overview (children/staff/adoptions totals)
- No admin-level modify actions

### Donor
Intent:
- Donor-side visibility and navigation.

Access:
- Donor home overview
- Restricted financial/module controls per role policies

### Adopter
Intent:
- Adoption applicant experience.

Access:
- Adopter home overview
- Adoption apply/track features (as allowed by screen/service rules)

---

## 5. Module Features

## Children Management
- List children
- Search by name or ID
- Add / Edit / Delete (admin only)
- Form validation and error messages

## Staff Management
- List staff
- Search by name or ID
- Add / Edit / Delete (admin only)

## Donation Management
- List donations from `donars` table (current app query target)
- Add donation
- Delete donation
- Date filters
- Total amount summary

## Adoption Management
- List adoptions
- Add adoption/apply
- Update approval status
- Delete adoption (admin)

## Dashboard
- Cards:
  - Total Children
  - Total Staff
  - Total Donations
  - Total Adoptions
  - Donation Amount
- Quick links
- Recent login feed
- Pending user approvals (admin action)

## Role Home Dashboards (staff/donor/adopter)
- Banner image
- Overview cards:
  - Total Children
  - Total Staff
  - Total Adoptions

---

## 6. Supabase Database Design

Core tables:
- `public.users` (app profile + role + approval)
- `public.login_logs`
- `public.children`
- `public.staff`
- `public.donations` (exists in schema)
- `public.adoptions`
- `public.admin_users`
- `public.donors`
- `public.adopters`

Auth table:
- `auth.users` (managed by Supabase Auth)

Trigger:
- `public.handle_new_user()` on `auth.users` insert.
- Includes fail-safe `exception when others then null` blocks to avoid signup failure from auxiliary table issues.

RLS:
- Enabled across key tables.
- Policies allow authenticated access according to project rules.
- Admin update policy exists on `public.users`.

---

## 7. Admin Approval Flow

1. New user registers -> row in `public.users` with `approval_status='pending'`.
2. Pending user login attempt is blocked with message: `Account pending admin approval.`
3. Pending login attempt is logged in `login_logs` with role marker `pending_<role>`.
4. Admin dashboard receives realtime event and can approve pending users.

---

## 8. Error Handling & Logging

Implemented:
- Friendly auth error mapping for:
  - Invalid credentials
  - Email not confirmed
  - Rate limits
  - Network/DNS issues
  - Trigger/database signup failures
- App logger writes event/error logs to local file and tracks live in memory.
- Global error hooks:
  - `FlutterError.onError`
  - `PlatformDispatcher.instance.onError`

---

## 9. UI/UX Features Implemented In This Project

- Responsive layouts (mobile-first)
- SafeArea + Scroll views for overflow handling
- Drawer navigation with logo branding
- Dashboard image banner
- Material cards/forms/lists
- Loading indicators and snackbar messages
- Back navigation control on dashboard exit flow
- Profile page with photo picker

---

## 10. Libraries / Tools Used

Main:
- `flutter`
- `supabase_flutter`
- `intl`
- `shared_preferences`
- `path_provider`
- `image_picker`
- `permission_handler`

Dev:
- `flutter_lints`
- `flutter_launcher_icons`
- `flutter_test`

Backend services:
- Supabase Auth
- Supabase PostgREST
- Supabase Realtime channels

---

## 11. Important Notes

- Ensure DB schema is applied from:
  - `supabase/schema.sql`
- Role strings must be lowercase:
  - `admin`, `staff`, `donor`, `adopter`
- Donation module currently queries table `donars`. Keep table name consistent in Supabase.

---

## 12. Quick Operational Checklist

1. Apply SQL schema to Supabase.
2. Create/confirm admin auth account.
3. Ensure `public.users.role='admin'` for admin account.
4. Run app with dart-defines.
5. Register sample users.
6. Approve users from admin dashboard.
7. Verify role-specific navigation and module access.
