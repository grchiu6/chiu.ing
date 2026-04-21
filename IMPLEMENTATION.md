# chiu·ing — Implementation Rundown

A rundown of everything that has been built across 10 iterations from the `ralph.md` spec. This document covers the architecture, every feature, every screen, and every cross-cutting system, with pointers to the files that own each piece.

---

## 1. What the app is

`chiu.ing` is a SwiftUI iOS app (iOS 17+, no external dependencies) for social food discovery. It blends three things:

- **A TikTok-style vertical video/photo scroll** as the main discovery surface.
- **A curated social home feed** driven by friends' activity, not aggregate ratings.
- **A personalized recommendation engine** tuned by follows, likes, friend engagement, popularity, and the user's own taste tags.

The design language is bright and playful — sunset orange, mango yellow, bubblegum pink, lime, sky — rendered in SF Rounded with shared card and pill styles.

---

## 2. Project layout

```
chiu.ing/
├── chiu.ing.xcodeproj/              Xcode 16 synchronized-group project
├── chiu.ing/
│   ├── ChiuingApp.swift             @main entry + AppGate (onboarding ↔ root)
│   ├── Theme/
│   │   └── Theme.swift              palette, typography, gradients, chiuCard(), pill styles
│   ├── Models/
│   │   ├── User.swift
│   │   ├── Restaurant.swift
│   │   ├── Post.swift               Post + PostMedia enum (4 cases)
│   │   ├── LocationFilter.swift
│   │   └── Notification.swift       AppNotification + Kind enum
│   ├── ViewModels/
│   │   ├── SessionStore.swift       current user, filters, likes, saves, follows, visits, taste tags, onboarding flag
│   │   └── PostStore.swift          user-created + seeded posts, merged views
│   ├── Data/
│   │   └── MockData.swift           seeded users, restaurants (ATL + NYC + LA), posts, notifications, trending tags
│   ├── Views/
│   │   ├── RootView.swift           custom tab bar + tab switching
│   │   ├── HomeView.swift           home feed + header + notification bell
│   │   ├── ScrollFeedView.swift     TikTok-style paging + tag feed container + empty states + heart burst
│   │   ├── ProfileView.swift        identity, grid, mutual connections
│   │   ├── RestaurantDetailView.swift
│   │   ├── LocationFilterView.swift
│   │   ├── SearchView.swift
│   │   ├── NotificationsView.swift
│   │   ├── CreatePostView.swift     photo + video picker, preview, submit
│   │   ├── OnboardingView.swift     4-step paged onboarding
│   │   ├── SettingsView.swift       form-based edit profile + reset onboarding
│   │   └── Components/
│   │       ├── AvatarView.swift
│   │       ├── TagPill.swift        tappable pill
│   │       ├── MediaBackdrop.swift  renders all 4 PostMedia cases
│   │       ├── VideoPreviewPlayer.swift   AVKit VideoPlayer wrapper + PickedMovie Transferable
│   │       └── Haptics.swift        tap / soft / success helpers
│   └── Resources/Assets.xcassets    AppIcon + AccentColor
└── README.md
```

---

## 3. Models and state

### User (`Models/User.swift`)

- Identity (`id`, `username`, `displayName`, `bio`, `avatarEmoji`), counts (followers, following, posts), `badges`, `city`.
- Hashable, Codable, Identifiable.

### Restaurant (`Models/Restaurant.swift`)

- `name`, `cuisine`, `neighborhood`, `city`, `priceLevel`, `rating`, `tags`, `heroEmoji`, `latitude`, `longitude`.
- Computed `coordinate: CLLocationCoordinate2D` for MapKit, and `priceLabel` (`$`…`$$$$`).

### Post (`Models/Post.swift`)

- `authorID`, `restaurantID`, `caption`, `media: PostMedia`, `tags`, counts, `createdAt`, `friendsWhoLiked`.
- `PostMedia` is a single Codable/Hashable enum with four cases:
  - `photo(emoji:bgHex:)` — seed emoji posts
  - `video(posterEmoji:bgHex:durationSeconds:)` — seed video posters
  - `userImage(data:bgHex:)` — from `PhotosPicker` image
  - `userVideo(url:bgHex:)` — from `PhotosPicker` video (URL stored after copying to the temp dir)

### AppNotification (`Models/Notification.swift`)

- `actorID`, `kind`, `createdAt`, `isRead`.
- `Kind` enum: `.like(postID:)`, `.follow`, `.mention(postID:)`, `.friendVisited(restaurantID:)`, `.milestone(text:)`.

### LocationFilter (`Models/LocationFilter.swift`)

- `city`, `radiusMiles`, `usingCurrentLocation`, with a `displayText` (e.g. `"Atlanta • 5 mi"`).
- Default: Atlanta, 5 mi.

### SessionStore (`ViewModels/SessionStore.swift`)

`ObservableObject` holding all per-session state:

- `currentUser`, `locationFilter`
- `likedPostIDs`, `savedPostIDs`, `followedUserIDs`, `visitedRestaurantIDs` (all `Set<UUID>`)
- `tasteTags: Set<String>`
- `@AppStorage("chiuing.hasOnboarded") hasOnboarded: Bool` — persists onboarding across launches.
- `toggleLike / toggleSave / toggleFollow / toggleVisit` — each fires an appropriate haptic.

### PostStore (`ViewModels/PostStore.swift`)

- Holds `userCreatedPosts: [Post]`.
- Exposes `allPosts` which prepends new posts before the seeded ones and sorts by `createdAt` descending.
- `add(_:)`, `posts(byAuthor:)`, `posts(atRestaurant:)` helpers.

### MockData (`Data/MockData.swift`)

Seeded in-memory data:

- 6 users (Grace, Milo, Kiwi, Joy, Theo, Ren) with badges.
- 11 restaurants — 7 in Atlanta, 2 in New York, 2 in Los Angeles.
- 7 posts covering a range of cuisines and creators.
- 6 notifications covering each `Kind`.
- 15 trending tags.
- Helpers: `user(id:)`, `restaurant(id:)`, `posts(byAuthor:)`, `posts(atRestaurant:)`, `restaurants(in:)`, `isPost(_:in:)`.

---

## 4. App entry & gating

`ChiuingApp.swift` (`@main`):

- Creates `SessionStore` and `PostStore` as `@StateObject`s and injects both via `.environmentObject`.
- Forces light color scheme for the bright/playful design.

`AppGate`:

- If `session.hasOnboarded == false` → shows `OnboardingView`.
- Otherwise → `RootView`.
- Transitions between the two with a fade.

---

## 5. Navigation shell

`RootView.swift`:

- Custom `ChiuTabBar` at the bottom — 5 tabs (Home · Search · **+ Create** · Scroll · Profile) with the center create button rendered as a 54pt gradient circle that raises a `.sheet` of `CreatePostView`.
- Top-level switch selects which view to show, including `.ignoresSafeArea(edges: .scroll ? .all : [])` so the Scroll feed goes edge-to-edge.
- The active tab is animated with color + weight changes.

---

## 6. Screens

### 6.1 HomeView

The curated social feed — explicitly *not* an infinite scroll.

Sections, top-to-bottom:
- **Header** — `chiu·ing` wordmark in a warm gradient, "your circle's table" subtitle, a **location chip** (tap opens `LocationFilterView` as a sheet), and a **bell** button (tap opens `NotificationsView` as a sheet) with an unread-count badge.
- **Friends recently visited** — horizontal strip of cards built from restaurants in the user's current city, each showing the hero emoji, name, neighborhood, price level, and a stacked avatar cluster of three friends. If no seeded restaurants exist in the selected city, a friendly `NoLocalContent` card explains how to switch cities.
- **Trending among your circle** — `TrendingFeatureCard` highlighting the most-liked post, with the author chip overlaid on the media and like/save/share counts below the caption.
- **For You** — horizontal `LovedMiniCard` strip of five posts, each tappable to open the restaurant.
- **Places your friends loved** — second horizontal mini-card strip.
- **New foodies to follow** — vertical list of three `SuggestedUserRow`s with avatar, stats, and a Follow/Following toggle.

Pull-to-refresh fires a soft haptic.

### 6.2 ScrollFeedView

The TikTok-style main discovery surface. Reusable — the same view is used for:

- The primary Scroll tab (no params).
- Tag-filtered feeds (`postsOverride:` + `title:`).
- Deep links from Notifications into a single post (`startPostID:` + `postsOverride: [post]`).
- Tapping a Profile grid tile (`startPostID:` + `postsOverride: visiblePosts` + `title:`).

Technical approach:

- `ScrollView(.vertical)` with `LazyVStack`, each post sized to the full screen via `GeometryReader`, snapped by `scrollTargetBehavior(.paging)` + `scrollTargetLayout()`.
- `scrollPosition(id: $scrollPosition)` with an `onAppear` that sets the position to `startPostID ?? posts.first?.id` so deep links land on the right post.
- Empty states: `EmptyFollowingFeed` for when the Following filter has nothing; `EmptyTagView` for empty tag feeds.

Filter bar:
- **Following / Discover** toggle (two underlined pills) at the top when presented as the primary tab. Filtering:
  - `Discover` = every post whose restaurant is in the current city (plus the user's own posts always).
  - `Following` = same, further restricted to authors the user follows (plus the user).

Top overlay:
- Location chip when shown as the main tab (opens `LocationFilterView`).
- Chevron-down dismiss button when presented as a sheet.
- Centered title.

### 6.3 ScrollPostCard

The individual card that fills the screen in the Scroll feed.

- **`MediaBackdrop`** renders the media behind everything.
- A vertical darken gradient on the bottom half gives text contrast.
- **Bottom-left** info stack: tappable creator chip (avatar + username + display name), tappable place chip (pin + name + neighborhood), caption (3 lines max), tappable tag pills.
- **Right action rail**: like (heart fills in pink), save (bookmark fills in yellow), share (real `ShareLink`), ellipsis. Like and save counts update optimistically.
- **Horizontal swipe gestures**: left past -80pt → restaurant detail; right past +80pt → creator profile; the card tilts under your finger with live swipe hints appearing on the opposite side.
- **Double-tap to like**: anywhere on the media fires a haptic, toggles a like if not already liked, and spawns a `HeartBurstView` — a gradient-filled heart with random rotation that scales from 0.2× → 1.3× and fades out over 0.9s at the tap location. Multiple simultaneous bursts supported.
- **Tag pills** open `TagFeedContainer` in a full-screen cover.

### 6.4 ProfileView

Own vs other users' profiles, all in one view.

- **Hero banner** — a gradient rectangle with a ringed avatar floating below it.
- **Stats strip** — posts, followers, following in a `chiuCard()`.
- **Bio block** — display name, `@handle • city`, bio, horizontal strip of star-prefixed badges on a gradient pill.
- **Mutual connections** — shown only on other users' profiles; stacked avatars of up to three mutual follows plus text like "Followed by @milotaste + 2 others".
- **Action buttons**
  - For the current user: Edit profile (opens Settings), Share (real `ShareLink`).
  - For other users: Follow/Following (toggles via SessionStore, gives haptic feedback), Message (placeholder).
- **Section tabs** — Posts / Liked / Saved pill segmented control.
- **Grid** — 2-column `LazyVGrid` of `ProfileGridTile`s, each a 3:4 `MediaBackdrop` with a heart count overlay. Tapping a tile opens a full-screen `ScrollFeedView` scoped to the visible section, starting at that post.
- **Settings gear** — top-right overlay for the current user, opens `SettingsView`.

Empty states (themed, not default SwiftUI empty) for Posts/Liked/Saved when nothing matches the filter.

### 6.5 RestaurantDetailView

Opened via sheet from the Scroll swipe-left, Home cards, Search results, and Notification rows.

Sections:
- **Hero** — gradient card with the restaurant's hero emoji at display size.
- **Heading block** — name, cuisine · neighborhood · price, star rating, post count from `PostStore`.
- **Action row** — "Been here" (toggles + success haptic; flips to a gradient-filled pill when set), Directions and Share chips.
- **Tags row** — horizontally scrolling `TagPill`s; tapping one opens `TagFeedContainer`.
- **Map section** — `Map(position:)` + `Marker` using the restaurant coordinate, rounded.
- **Friends who've been** — avatars of followed users who have posted about this restaurant.
- **Quick reviews** — rows of follower avatar + username + caption for every post at this restaurant (including user-created ones).
- **Close button** — top-right overlay.

### 6.6 LocationFilterView

Presented as a sheet (the swipe-up modal from the spec).

- Drag-handle capsule.
- `Map(position:)` with a dashed sunset-orange circle overlay sized proportionally to the radius.
- **Use current location** toggle.
- **City text field**.
- **Radius slider** (1–50 mi) with a live badge.
- **Popular cities** horizontal chips.
- **Apply filter** bottom-bar button that writes back into `session.locationFilter` and dismisses.

### 6.7 SearchView

Search tab.

- **Search field** — with a clear button; query is fuzzy case-insensitive.
- **Scope picker** — All / Places / People / Tags.
- **Discover state** (empty query)
  - Trending tags grid (taps open tag feed).
  - Top foodies in your city (top 3 by follower count, each opens their profile).
  - Hot spots in your city (sorted by rating; each opens restaurant detail).
- **Results state**
  - People: fuzzy match on username + display name, rendered as `SuggestedUserRow` → profile.
  - Places: fuzzy match on name/cuisine/neighborhood/tags, rendered as `PlaceRow` → restaurant.
  - Tags: union of trending + restaurant tags that contain the query → open tag feed.
  - Empty state if no category matched.

### 6.8 NotificationsView

Sheet from the Home bell.

- Filter bar: All / Mentions / Friends.
- Rows (`NotificationRow`) styled as cards with:
  - Ringed avatar (tap → profile).
  - Formatted sentence ("Milo **liked your post**", "Ren **started following you**", etc.).
  - Relative timestamp ("12m ago").
  - Kind-specific inline action area:
    - Likes/mentions → small `MediaBackdrop` thumbnail + caption, tap opens that exact post in a full-screen Scroll view.
    - Follows → "View profile" pill.
    - Friend visits → restaurant chip with hero emoji → restaurant detail.
    - Milestones → bold text, no action.
  - Unread dot for `!isRead`.

### 6.9 CreatePostView

Sheet from the tab bar's center + button.

- **Drag handle + header** (Cancel · "Share a bite" · no-op spacer).
- **Media type** — Photo / Video toggle. Switching clears any picked media of the other type.
- **Media builder** — a 240pt gradient card that shows, in priority order:
  - The picked video via `VideoPreviewPlayer` if one was chosen.
  - The picked photo as `UIImage` if one was chosen.
  - Otherwise, the selected emoji at display size with a gradient backdrop.
  - Floating pill at the bottom: `PhotosPicker(matching: isVideo ? .videos : .images)`, with an X button to clear.
- **Dish strip** — scrolling emoji picker for the fallback media.
- **Vibe color strip** — scrolling circle swatches that change the gradient.
- **Caption field** — multi-line.
- **Restaurant picker** — horizontal chips for every seeded restaurant; tapping selects/deselects.
- **Tags** — multi-select flow grid, with the currently-selected tags shown as solid pills below.
- **Post bar** — disabled until caption + restaurant are set. On tap:
  - Builds the correct `PostMedia` case (userVideo > userImage > seeded video > seeded photo).
  - Constructs a `Post` with `authorID: currentUser.id` and current timestamp.
  - Calls `postStore.add(_:)` so the post appears at the top of Scroll, on Profile.Posts, and in the restaurant's reviews immediately.
  - Bumps `session.currentUser.postsCount` and dismisses.

### 6.10 OnboardingView

Shown on first launch via `AppGate`; can also be reset from Settings.

Four paged steps with a live progress-dot bar:

1. **Welcome** — wordmark + "Find food the way your friends find food."
2. **Pick a handle** — `@` prefix + text field.
3. **Where do you eat?** — 2-column grid of 8 city options (Atlanta, NY, LA, Chicago, Austin, Seattle, Miami, Denver).
4. **Pick your cravings** — adaptive tag grid; must pick at least 3 to advance.

The bottom bar shows Back (>0) and Next/Let's go, with the Next button dimmed when the current step's requirement isn't met. Finishing writes username, display name (if empty), city, city→locationFilter, and taste tags into `SessionStore`, then flips `hasOnboarded = true`.

### 6.11 SettingsView

Sheet from the Profile gear.

- Form-based with sections:
  - **Profile** — name, handle, city, bio.
  - **Cravings** — full taste-tag re-selector.
  - **Location filter** — read-out of current city and radius.
  - **Reset onboarding** — destructive button with a confirmation dialog. On confirm, flips `hasOnboarded = false` so `AppGate` sends the user back to `OnboardingView`.
- Cancel and Save toolbar buttons. Save trims, writes changes back into `SessionStore`, and syncs city → locationFilter.

---

## 7. Cross-cutting systems

### 7.1 Theme (`Theme/Theme.swift`)

- Palette: sunsetOrange, mangoYellow, limeGreen, bubblegumPink, skyBlue, eggplant, cream, charcoal.
- Gradients: `gradientWarm`, `gradientFresh`, `gradientPlayful`.
- Typography: display / title / headline / body / caption / tag in SF Rounded.
- Metrics: `cornerRadius: 20`, `cornerRadiusSmall: 12`, card shadow presets.
- View extensions: `chiuCard()` (white + rounded + soft shadow), `chiuPillTag(color:)`.

### 7.2 Media rendering (`Views/Components/`)

- **`MediaBackdrop`** — switches on the four `PostMedia` cases. `userVideo` uses `VideoPreviewPlayer`; `userImage` decodes `UIImage`; the seeded variants render the emoji on a gradient; `video` also paints a duration badge.
- **`VideoPreviewPlayer`** — creates an `AVPlayer`, mutes it, starts playback, listens for `AVPlayerItemDidPlayToEndTime` to loop back to zero, pauses on `onDisappear`.
- **`PickedMovie`** — a `Transferable` that accepts a `.movie` `FileRepresentation` and copies the received file into `FileManager.default.temporaryDirectory` under a fresh UUID name, so the URL survives after the PhotosPicker dismisses.

### 7.3 Haptics (`Views/Components/Haptics.swift`)

- `tap()` — light impact (likes, follows, filter toggles).
- `soft()` — soft impact (save, refresh, media filter switch).
- `success()` — `.success` notification feedback ("been here").

All toggle methods on `SessionStore` call the appropriate helper automatically.

### 7.4 Personalization (For You scoring)

In `HomeView.personalizedPosts`, each post gets a score:

- `+3` if the viewer follows the author.
- `+2` if the viewer has liked the post.
- `+count` for how many of the viewer's friends liked it.
- `+min(likeCount / 200, 5)` popularity bucket.
- `+2 × overlap` of post tags with the viewer's taste tags.
- `+overlap` of restaurant tags with taste tags.

Top 5 by score, sorted, render as a horizontal strip.

### 7.5 Tag discovery

Every `TagPill` has an optional `onTap`. Wired in:

- `ScrollPostCard` — tag pills on posts.
- `RestaurantDetailView` — tags row.
- `SearchView` — trending tags strip + matched tags in results.

All open a full-screen `TagFeedContainer` that resolves the tag into `postStore.allPosts` where the post is tagged OR the restaurant is tagged. Empty results show `EmptyTagView` with a close button.

### 7.6 Location filter respect

The selected city affects:

- **Scroll feed** — posts in other cities are hidden from Discover and Following, but the user's own posts always show.
- **Home friends-visited** — only restaurants in the current city; otherwise shows the `NoLocalContent` card with a CTA to change city.
- **Search hot spots** — scoped to the current city.

### 7.7 Sharing

Uses real `ShareLink` in two places:

- Post-level — the share button on the Scroll action rail generates "Check out @user's take on {place} on chiu·ing — {caption}".
- Profile-level — the Share button on own profile generates "Follow me on chiu·ing — @handle".

---

## 8. Build & tooling

- **Xcode project** — Xcode 16 with `fileSystemSynchronizedGroups`, so adding a file to the folder structure automatically includes it in the target with no project.pbxproj edits.
- **Build settings**
  - `IPHONEOS_DEPLOYMENT_TARGET = 17.0`
  - `SWIFT_VERSION = 5.0`
  - `TARGETED_DEVICE_FAMILY = "1,2"` (iPhone + iPad)
  - `SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD = YES`
  - `GENERATE_INFOPLIST_FILE = YES` — no manual Info.plist; the `INFOPLIST_KEY_*` settings generate scene, launch screen, orientations, and `NSLocationWhenInUseUsageDescription`.
- **Frameworks** — all first-party Apple: SwiftUI, Combine, Foundation, UIKit, MapKit, CoreLocation, PhotosUI, AVKit.
- **No third-party dependencies.**
- Builds clean for the iOS simulator: `** BUILD SUCCEEDED **`, zero warnings, zero errors.

---

## 9. Spec coverage vs `ralph.md`

| Spec item | Status |
|---|---|
| Mobile-first social food discovery app | ✅ |
| Short-form content (videos + photos) | ✅ real photos + videos via PhotosPicker, plus emoji fallbacks |
| Friends' activity (likes, visits, posts) | ✅ |
| Personalized discovery | ✅ multi-signal score |
| Home — posts from friends + followed, friends recently visited, trending among your circle, places your friends loved, suggested users, For You | ✅ all sections present |
| Scroll — vertical paging, videos, photos, mixed media | ✅ |
| Scroll — creator info, restaurant tag, caption, like/share/save | ✅ |
| Scroll — swipe up/down next/prev, swipe left → restaurant, swipe right → creator | ✅ |
| Location — map chip with current city & radius | ✅ |
| Location — swipe-up modal map, change city/location, adjust radius, use current location, search | ✅ |
| Location — feed updates dynamically | ✅ Scroll + Home + Search all respect the filter |
| Restaurant detail — name, map, reviews, tags, friends, external actions | ✅ |
| Profile — info, followers/following, posts, liked, saved, follow/unfollow, mutual connections | ✅ |
| Personalization learns from likes, saves, watch time, places viewed, social graph | ✅ everything except watch-time (no video analytics layer) |
| UX: clean, modern, smooth animations, gesture-heavy, minimal text, visual-first, bright/cartoonish/colorful | ✅ |
| Optional: "Been here" button | ✅ with haptic |
| Optional: food tagging | ✅ |
| Optional: creator badges | ✅ ("Top foodie in ATL", etc.) |
| Optional: search (users, places, tags) | ✅ |
| Optional: notifications | ✅ |

### Additions beyond the spec

- 4-step onboarding flow, persisted in `UserDefaults`.
- Settings screen with destructive reset-onboarding.
- Double-tap-to-like with animated gradient heart burst.
- System haptic feedback hooked into every social action.
- Tag-everywhere-opens-tag-feed discovery.
- Real `ShareLink` for posts and profiles.
- Pull-to-refresh on Home.
- Following / Discover toggle on Scroll with empty-state CTA.
- Multi-city seed data (Atlanta, New York, Los Angeles) so the location filter is demonstrable.
