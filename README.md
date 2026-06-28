# WWN — World Wide News

A personalized news aggregation mobile app built with Flutter. Aggregates local and international news, tailors content to each user's interests, and supports offline reading with advanced full-text search.

<p align="center">
  <img src="screenshots/01_title_screen.png" alt="WWN Title Screen" width="260"/>
</p>

---

## Features

- **Personalized "For You" feed** — preference-weighted recommendation engine distributes articles across chosen categories
- **Multi-source aggregation** — NewsAPI, GNews, and a custom web scraper for local Sri Lankan news (AdaDarana)
- **Full-text search** — Algolia-powered with multi-strategy matching (title, description, source, category)
- **Multi-method authentication** — Email/password, Google Sign-In, Facebook, and OTP verification
- **Article reader** — full content via web scraping, adjustable font size (14–26 pt), reading progress bar
- **Bookmarks & history** — synced to Firestore, available offline via Hive cache
- **Category tabs** — Top, Business, Sports, Technology, Entertainment, Politics

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter 3.5+ / Dart |
| State Management | Provider (ChangeNotifier) |
| Auth | Firebase Auth — Email, Google, Facebook |
| Database | Cloud Firestore + Hive (offline) |
| Search | Algolia Search |
| News APIs | NewsAPI, GNews |
| Scraping | Custom HTML parser (html package) |
| Image Caching | cached_network_image |
| Analytics | Firebase Analytics |

---

## Architecture

```
lib/
├── main.dart                        # Entry point, Firebase init, Provider setup
├── screens/                         # UI layer
│   ├── home_screen.dart             # Main feed with category tabs & masonry grid
│   ├── article_screen.dart          # Full article reader
│   ├── search_screen.dart           # Algolia search interface
│   ├── bookmark_screen.dart         # Saved articles
│   ├── history_screen.dart          # Reading history
│   ├── profile_screen.dart          # User profile & settings
│   └── ...                          # Auth screens, onboarding, preferences
└── services/                        # Business logic & data layer
    ├── api_service.dart             # NewsAPI & GNews integration
    ├── for_you_service.dart         # Personalization engine
    ├── advanced_search_service.dart # Algolia search
    ├── scraping.dart                # Local news web scraper
    ├── firebase_service.dart        # Auth wrapper
    ├── bookmark_provider.dart       # Bookmark state (ChangeNotifier)
    └── history_provider.dart        # History state (ChangeNotifier)
```

---

## Local Setup

> This project requires Firebase and third-party API credentials to run.

```bash
git clone https://github.com/anukaishara/WWNapp.git
cd WWNapp
flutter pub get
flutter run
```

**Required credentials:**
- `google-services.json` (Android) from your Firebase console → `android/app/`
- `GoogleService-Info.plist` (iOS) → `ios/Runner/`
- NewsAPI key → `lib/services/api_service.dart`
- GNews key → `lib/services/api_service.dart`
- Algolia App ID & Search Key → `lib/services/advanced_search_service.dart`

---

## Highlights

- Integrated three independent news sources into a unified, deduplicated feed
- Built a preference-weighted recommendation engine that allocates article slots by category percentage
- Implemented multi-provider auth (Email, Google, Facebook) with a consistent Firestore user model
- Used Algolia for sub-100ms search with a Firestore fallback strategy
- Applied Hive as an offline-first cache so core content is accessible without a connection
