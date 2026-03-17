# Be Proud

Be Proud is a location-based discovery platform that helps people find local venues and experiences with an integrated AI assistant.

This implementation includes:
- **Flutter mobile app** with modern dark UI, list/map tabs, AI assistant, and a square-based 3D venue preview.
- **Django backend API** that serves venue search and AI recommendation/direction responses.

## Project Structure

- `backend/` – Django API service
- `mobile/` – Flutter app (Android, iOS, Web, Desktop scaffolded)

## 1) Install Flutter SDK

If Flutter is not installed on your machine:

```bash
git clone https://github.com/flutter/flutter.git -b stable ~/flutter-sdk
export PATH="$PATH:$HOME/flutter-sdk/bin"
flutter --version
```

(Optional) add the PATH export to your shell profile.

## 2) Run Backend (Django)

```bash
cd backend
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
python manage.py runserver 0.0.0.0:8000
```

API endpoints:
- `GET /api/venues/?query=<text>&category=<type>`
- `POST /api/assistant/`

## 3) Run App (Flutter)

```bash
cd mobile
flutter pub get
flutter run
```

> Android emulator can use the default backend URL (`10.0.2.2:8000`).


### Note about binary assets

This repository intentionally excludes generated Flutter icon/launch-image binaries to keep PR diffs text-only in environments that reject binary files.
If you need to regenerate missing platform assets locally, run:

```bash
cd mobile
flutter create .
```


## Windows Android build fix (Gradle cache error)

If you see this error while building Android:

`Error resolving plugin [id: 'dev.flutter.flutter-plugin-loader', version: '1.0.0']`
with a nested message like
`Could not move temporary workspace ... transforms ... to immutable location`.

Run these steps in **PowerShell**:

```powershell
cd mobile
flutter clean
flutter pub get
./gradlew --stop
Remove-Item -Recurse -Force "$env:USERPROFILE\.gradle\caches\8.14\transforms" -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force "$env:USERPROFILE\.gradle\daemon" -ErrorAction SilentlyContinue
flutter run
```

Also make sure your antivirus is not locking files in `%USERPROFILE%\.gradle`.
This project already disables Gradle daemon/parallel/build-cache/file-watching in
`mobile/android/gradle.properties` to reduce this Windows lock contention.

## Design Notes

- **Modern UI:** Material 3 + neon-accent dark interface.
- **Discovery:** quick search, list/map tab switch, venue cards with distance + rating.
- **AI assistant:** natural language prompt input and ranked nearby suggestions.
- **3D style:** `SquareCityPainter` renders layered square blocks representing venue models.
