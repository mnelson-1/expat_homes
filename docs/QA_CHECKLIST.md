# Manual QA checklist — ExpatHomes (`expat_app`)

Use this after releases or before demos. Record **Pass / Fail / N/A** and notes. Combine with automated metrics from `docs/qa/README.md` for a full QA picture.

## Environment

| # | Check | Notes |
|---|--------|------|
| 1 | Debug build installs on target device/emulator | |
| 2 | `env/google_maps.properties` present with valid key | |
| 3 | Firebase `google-services.json` matches project | |
| 4 | Firestore rules deployed for your environment | |

## Authentication & roles

| # | Check | Notes |
|---|--------|------|
| 5 | New user: Get Started → register → profile created | |
| 6 | Sign in with email/password | |
| 7 | Sign in with Google (if enabled) | |
| 8 | Expat role lands on Community tab | |
| 9 | Landlord / Agent land on correct home shell | |

## Expat — Community

| # | Check | Notes |
|---|--------|------|
| 10 | Feed loads posts; open thread | |
| 11 | Create post (text + optional images) | |
| 12 | Like / comment | |
| 13 | Bowls list; join bowl; open thread | |

## Expat — Estates

| # | Check | Notes |
|---|--------|------|
| 14 | Listings stream loads; filters (All / Apartments / Houses / Short-Stay) | |
| 15 | Search filters list | |
| 16 | Open listing detail | |
| 17 | **Get a Ride** → Rides tab; To field prefilled / geocodes | |
| 18 | **Explore Area** → Explore tab; search prefilled; results load | |

## Expat — Rides

| # | Check | Notes |
|---|--------|------|
| 19 | From / To autocomplete | |
| 20 | Route draws; distance/time panel | |
| 21 | RWF estimate panel (green card); dismiss | |
| 22 | GPS “From” when permitted | |

## Expat — Explore

| # | Check | Notes |
|---|--------|------|
| 23 | Search place → map marker; open category results | |
| 24 | Tabs: Food / Health / Fitness / Shopping load lists | |
| 25 | Place photos, rating line, hours line | |
| 26 | **Continue in Google** opens Maps / browser | |
| 27 | Back → map + search text preserved; shell (header/nav) returns | |
| 28 | Cold start: Explore session restores within TTL (if used) | |

## Expat — Messages

| # | Check | Notes |
|---|--------|------|
| 29 | Conversation list | |
| 30 | Open chat; send message | |
| 31 | Translation / language ID in composer (if configured) | |
| 32 | Open listing from chat where applicable | |

## Cross-cutting

| # | Check | Notes |
|---|--------|------|
| 33 | Splash → animation → Get Started / home | |
| 34 | Account / profile screen from header | |
| 35 | No unhandled red screen on tab switches | |
| 36 | Airplane mode / API errors: user-visible message (Maps, Places) | |

## Landlord / Agent / Admin (smoke)

| # | Check | Notes |
|---|--------|------|
| 37 | Landlord: listings / payments / key flows you ship | |
| 38 | Agent: assignments / listings / messages | |
| 39 | `admin-web`: login and one critical path | |

---

**Sign-off**

- Tester: _________________  
- Date: _________________  
- Build / commit: _________________  
