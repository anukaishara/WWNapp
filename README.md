# WWN — World Wide News

A personalized news aggregation mobile app built with Flutter, delivering curated news tailored to each user's interests with real-time updates, offline reading, and advanced search.

<p align="center">
  <img src="screenshots/01_title_screen.png" alt="WWN Title Screen" width="280"/>
</p>

---

## Features

**Personalized Feed**
- "For You" section powered by a preference-weighted recommendation engine
- Category feeds: Top, Business, Sports, Technology, Entertainment, Politics
- Local news (Sri Lanka) aggregated via web scraping alongside international sources
- Masonry grid layout with a featured article carousel

**Authentication**
- Email/password, Google, and Facebook sign-in
- OTP verification for added security
- Password reset flow
- First-login preference selection to seed recommendations

**Article Reader**
- Full article content fetched via web scraping
- Adjustable font size (14–26 pt) for accessibility
- Reading progress indicator
- One-tap bookmarking

**Search**
- Algolia-powered full-text search with real-time results
- Multi-strategy matching: title, description, source, category
- Relevance-sorted results

**Bookmarks & History**
- Bookmark articles synced to Firestore
- Reading history tracked locally and in the cloud

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter 3.5.4+ |
| State Management | Provider (ChangeNotifier) |
| Authentication | Firebase Auth — Email, Google, Facebook |
| Database | Cloud Firestore + Hive (offline cache) |
| Search | Algolia Search |
| News Sources | NewsAPI, GNews, web scraping (AdaDarana) |
| Image Caching | cached_network_image |
| Analytics | Firebase Analytics |
| Local Storage | SharedPreferences, Hive |
| Networking | http, html (scraping) |

---

## Architecture

```
lib/
├── main.dart                        # Entry point, Firebase init, Provider setup
├── screens/                         # UI layer
│   ├── home_screen.dart             # Main feed with category tabs
│   ├── article_screen.dart          # Article reader
│   ├── search_screen.dart           # Search interface
│   ├── bookmark_screen.dart         # Saved articles
│   ├── history_screen.dart          # Reading history
│   ├── profile_screen.dart          # User profile & settings
│   └── ...                          # Auth screens, onboarding, preferences
├── services/                        # Business logic & data layer
│   ├── api_service.dart             # NewsAPI & GNews integration
│   ├── for_you_service.dart         # Personalization engine
│   ├── advanced_search_service.dart # Algolia search
│   ├── scraping.dart                # Local news web scraper
│   ├── firebase_service.dart        # Auth wrapper
│   ├── bookmark_provider.dart       # Bookmark state (ChangeNotifier)
│   ├── history_provider.dart        # History state (ChangeNotifier)
│   └── user_data_service.dart       # Firestore user data
└── widgets/                         # Reusable components
```

**Data flow:** screens call service classes → services fetch from Firestore, external APIs, or the local Hive cache → state changes propagate via Provider to rebuild only the affected widgets.

---

## Screenshots

| Title Screen | Home Feed | Article Reader |
|:---:|:---:|:---:|
| <img src="screenshots/01_title_screen.png" width="180"/> | _coming soon_ | _coming soon_ |

| Search | Bookmarks | Profile |
|:---:|:---:|:---:|
| _coming soon_ | _coming soon_ | _coming soon_ |

---

## Setup

> **Note:** This project uses Firebase and several third-party APIs. You will need your own credentials to run it locally.

**Prerequisites**
- Flutter 3.5.4+
- Android Studio / Xcode (for emulator) or a physical device
- Firebase project with Firestore, Auth, and Analytics enabled

**Steps**

1. Clone the repo
   ```bash
   git clone https://github.com/anukaishara/WWNapp.git
   cd WWNapp
   ```

2. Install dependencies
   ```bash
   flutter pub get
   ```

3. Configure Firebase — download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) from your Firebase console and place them in the respective platform folders.

4. Add API keys — create a `.env` file or add your keys to the relevant service files:
   - `NewsAPI` key → `lib/services/api_service.dart`
   - `GNews` key → `lib/services/api_service.dart`
   - `Algolia` App ID & Search Key → `lib/services/advanced_search_service.dart`

5. Run the app
   ```bash
   flutter run
   ```

---

## What I Built & Learned

- Integrated **three separate news data sources** (two REST APIs + a custom web scraper) and unified them into a single feed
- Designed a **preference-weighted recommendation engine** that allocates article slots by category based on user interest percentages
- Implemented **multi-provider authentication** (Email, Google, Facebook) with a consistent user data model in Firestore
- Used **Algolia** for sub-100ms full-text search across a large article corpus with graceful Firestore fallback
- Applied **Hive** as an offline-first local cache so the app is usable without a network connection
- Managed app-wide state with **Provider** using a clean service/provider separation

---

## License

This project was built as a learning and portfolio project. Not licensed for commercial use.
