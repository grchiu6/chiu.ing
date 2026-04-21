# chiu·ing

Social food discovery iOS app — part TikTok scroll, part friend recommendations, part personal taste engine. SwiftUI, iOS 17+.

## Run it

```
open chiu.ing.xcodeproj
```

Pick any iPhone simulator (iOS 17+) and hit ⌘R. First launch shows the 4-step onboarding; subsequent launches drop you straight into the Scroll tab.

Build from CLI:

```
xcodebuild -project chiu.ing.xcodeproj -scheme chiu.ing \
  -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' build
```

## Features

**Core pages**
- **Home** — curated social feed with location chip + notifications bell: friends visited, trending in your circle, *For You* (scored by follows, likes, friend engagement, popularity, and taste-tag overlap), places your friends loved, suggested users. Pull-to-refresh.
- **Scroll** — TikTok-style vertical paging via iOS 17's `scrollTargetBehavior(.paging)`. Following/Discover toggle at the top, empty-state CTA when following is thin. Double-tap the media to like and fire a gradient heart burst. Swipe up/down for next/previous, swipe left → restaurant, swipe right → creator. Action rail with real `ShareLink`.
- **Profile** — hero banner, stats strip, badges, mutual-connections strip on other users' profiles, Posts/Liked/Saved grid (tappable tiles open the post in a full-screen scroll view), Edit/Share buttons, gear icon for the current user opens Settings.
- **Search** — live fuzzy search over users, places, tags. All/Places/People/Tags scope filter. Discover state: trending tags, top foodies, hot spots in your city. Tags open into a tag-filtered scroll feed.
- **Activity** (sheet from Home) — like / follow / mention / friend-visited / milestone, filtered by All · Mentions · Friends. Rows deep-link to the underlying post or user.
- **Create Post** — `PhotosPicker`-backed real photo **or** video capture with live preview, emoji + vibe-color fallback when no media is picked, caption, restaurant tagging chip strip, tag multi-select. Submit adds to `PostStore` so the post lands in Scroll, Profile, and the restaurant's reviews immediately.
- **Restaurant Detail** — hero, `Map(position:)` + `Marker`, "Been here" toggle (with success haptic), directions/share buttons, tappable tags → tag feed, friends-who've-been avatars, lightweight review cards.
- **Location Filter** — modal with map + radius ring overlay, current-location toggle, text search, popular cities grid, apply button. **The selected city actually filters Scroll feed + Home friends-visited + Search hot spots** — posts/places in other cities are hidden (except the user's own posts, which always show).
- **Settings** — edit display name, handle, city, bio, re-pick taste tags, reset onboarding with destructive confirmation.

**Cross-cutting systems**
- **Onboarding** — 4-step paged flow (welcome → handle → city → ≥3 taste tags). Persisted in `@AppStorage`.
- **Personalization** — score-based For You: follows (+3), own likes (+2), friends-who-liked count, popularity bucket, taste-tag overlap (+2 per match), restaurant-tag overlap (+1 per match).
- **Media** — `PostMedia` is a single enum with `photo` / `video` / `userImage(data:)` / `userVideo(url:)`. `MediaBackdrop` renders all four. `VideoPreviewPlayer` uses `AVKit.VideoPlayer` with mute + loop. Picked videos are copied to the temp dir via a `Transferable` wrapper so their URLs survive picker dismissal.
- **Haptics** — light tap on like/follow, soft on save/refresh/toggle, success on "been here".
- **Design** — bright & playful: sunset orange, mango yellow, bubblegum pink, lime, sky. SF Rounded. Shared `chiuCard()` and pill/tag styles, gradient avatars.

## Structure

```
chiu.ing/
├── ChiuingApp.swift          app entry + AppGate (onboarding ↔ root)
├── Theme/Theme.swift         palette, typography, gradients, card styles
├── Models/                   User · Restaurant · Post · LocationFilter · Notification
├── ViewModels/               SessionStore · PostStore
├── Data/MockData.swift       seeded users, restaurants (ATL + NYC + LA), posts, notifications, trending tags
├── Views/
│   ├── RootView.swift        custom tab bar host
│   ├── HomeView.swift
│   ├── ScrollFeedView.swift  also hosts TagFeedContainer + HeartBurstView + EmptyFollowingFeed
│   ├── ProfileView.swift
│   ├── RestaurantDetailView.swift
│   ├── LocationFilterView.swift
│   ├── SearchView.swift
│   ├── NotificationsView.swift
│   ├── CreatePostView.swift
│   ├── OnboardingView.swift
│   ├── SettingsView.swift
│   └── Components/           AvatarView · TagPill · MediaBackdrop · VideoPreviewPlayer · PickedMovie · Haptics
└── Resources/Assets.xcassets
```

## Notes

- Ships with in-memory seed data (6 users, 11 restaurants across ATL/NYC/LA, 7 posts, 6 notifications). No backend.
- No external dependencies — everything is first-party Apple frameworks (SwiftUI, MapKit, PhotosUI, AVKit, UIKit).
- Builds clean with zero warnings on iOS 17+ simulators.
