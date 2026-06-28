<div align="center">

# WWN — World Wide News

**A personalized news aggregation app built with Flutter**

![Flutter](https://img.shields.io/badge/Flutter-3.5+-02569B?style=flat-square&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.5+-0175C2?style=flat-square&logo=dart&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=flat-square&logo=firebase&logoColor=black)
![Algolia](https://img.shields.io/badge/Algolia-5468FF?style=flat-square&logo=algolia&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-lightgrey?style=flat-square)

<br/>

<img src="screenshots/01_title_screen.png" alt="WWN Title Screen" width="240"/>

</div>

---

## Overview

WWN aggregates news from multiple sources — international APIs and a custom web scraper for local Sri Lankan news — and tailors the feed to each user's interests using a preference-weighted recommendation engine. Users can search, bookmark, track reading history, and read full articles offline.

---

## Features

| | Feature | Description |
|---|---|---|
| **Feed** | Personalized "For You" | Allocates articles across categories based on user preference percentages |
| **Sources** | Multi-source aggregation | NewsAPI, GNews, and custom scraper for AdaDarana (local news) |
| **Search** | Algolia full-text search | Multi-strategy matching across title, description, source, and category |
| **Auth** | Multi-method sign-in | Email/password, Google, Facebook, and OTP verification |
| **Reader** | Article reader | Full content via web scraping, adjustable font size, reading progress bar |
| **Offline** | Hive cache | Core content accessible without a network connection |
| **Sync** | Firestore persistence | Bookmarks and history synced across devices |

---

## Tech Stack

<table>
  <tr>
    <td><strong>Framework</strong></td>
    <td>Flutter 3.5+ · Dart</td>
  </tr>
  <tr>
    <td><strong>State Management</strong></td>
    <td>Provider (ChangeNotifier)</td>
  </tr>
  <tr>
    <td><strong>Backend</strong></td>
    <td>Firebase Auth · Cloud Firestore · Firebase Analytics</td>
  </tr>
  <tr>
    <td><strong>Search</strong></td>
    <td>Algolia Search</td>
  </tr>
  <tr>
    <td><strong>News Sources</strong></td>
    <td>NewsAPI · GNews · Custom HTML scraper</td>
  </tr>
  <tr>
    <td><strong>Local Storage</strong></td>
    <td>Hive · SharedPreferences</td>
  </tr>
  <tr>
    <td><strong>Auth Providers</strong></td>
    <td>Google Sign-In · Facebook Auth · OTP</td>
  </tr>
</table>

---

## Architecture

```
lib/
├── main.dart                          # Entry point — Firebase init & Provider setup
├── screens/
│   ├── home_screen.dart               # Personalized feed with category tabs & masonry grid
│   ├── article_screen.dart            # Full article reader with scraping
│   ├── search_screen.dart             # Algolia search interface
│   ├── bookmark_screen.dart           # Saved articles
│   ├── history_screen.dart            # Reading history
│   ├── profile_screen.dart            # Profile & settings
│   └── ...                            # Auth, onboarding, preferences screens
└── services/
    ├── api_service.dart               # NewsAPI & GNews integration
    ├── for_you_service.dart           # Personalization engine
    ├── advanced_search_service.dart   # Algolia integration
    ├── scraping.dart                  # Local news web scraper
    ├── bookmark_provider.dart         # Bookmark state
    └── history_provider.dart          # History state
```

**Data flow:** screens call service classes → services pull from Firestore, external APIs, or Hive cache → state changes propagate via Provider to rebuild only the affected widgets.

---

## Getting Started

> Requires Firebase credentials and API keys to run.

```bash
git clone https://github.com/anukaishara/WWNapp.git
cd WWNapp
flutter pub get
flutter run
```

**Required credentials**

| File / Location | Purpose |
|---|---|
| `android/app/google-services.json` | Firebase (Android) |
| `ios/Runner/GoogleService-Info.plist` | Firebase (iOS) |
| `lib/services/api_service.dart` | NewsAPI key · GNews key |
| `lib/services/advanced_search_service.dart` | Algolia App ID & Search key |
