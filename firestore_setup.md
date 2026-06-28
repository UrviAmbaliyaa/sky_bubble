# Firestore Ad Config — Setup Guide

## Collection: `app_config`  →  Document: `ads_config`

Create this document once in the Firebase Console:
https://console.firebase.google.com/project/bubble-burst-6af28/firestore

### Fields

| Field            | Type    | Default | Description                                              |
|-----------------|---------|---------|----------------------------------------------------------|
| `show_ads`      | boolean | `true`  | **MASTER GATE** — must be `true` for ANY ad to show. When `false`, all ads are hidden AND "Earn Coins" / "Earn Award" options are hidden too |
| `ads`           | boolean | `true`  | Standard ad set (banner in game, level-complete interstitial) |
| `moreads`       | boolean | `false` | Extra-ads mode (see behaviours below)                    |
| `banner_id`     | string  | see below | AdMob banner unit ID                                   |
| `interstitial_id` | string | see below | AdMob interstitial unit ID                           |
| `app_id`        | string  | see below | AdMob app ID (informational)                           |

### Production Ad IDs (already hardcoded as fallback)
- `app_id`          → `ca-app-pub-8536272432230680~9983882940`
- `banner_id`       → `ca-app-pub-8536272432230680/8012325727`
- `interstitial_id` → `ca-app-pub-8536272432230680/2774601057`

---

## Behaviour Matrix

| `show_ads` | `ads` | `moreads` | Effect                                                                             |
|-----------|-------|-----------|------------------------------------------------------------------------------------|
| false     | any   | any       | ALL ads hidden; "Earn Coins" and "Earn Award" hidden                               |
| true      | false | any       | All ads hidden (earn options still visible if IDs loaded OK)                       |
| true      | true  | false     | Normal ads (banner in game, interstitials on level-complete / new-best)            |
| true      | true  | true      | Normal ads + banner on every screen + interstitial on premium-bg tap + on resume  |

### Earn-options visibility (`adsReady`)

"Earn Coins" and "Earn Award" are visible **only** when **both**:
- `show_ads == true`
- Ad IDs were successfully fetched from Firestore (not just local fallback or hardcoded defaults)

---

## Firestore Security Rules

Add to your Firestore rules so only the app can read (not write) config:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /app_config/{doc} {
      allow read: if true;   // app reads this on startup
      allow write: if false; // only you via Firebase Console
    }
  }
}
```
