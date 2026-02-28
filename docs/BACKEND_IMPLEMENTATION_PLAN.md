# Backend & Implementation Plan — Expat Homes

This document defines backend scope, data models, and implementation directives for all three user parties (Expats, Landlords, Agents). It is written in definitive, implementation-ready terminology. **Backend implementation has not started;** this file is the structural plan.

---

## 1. Expat Workflow

### 1.1 Community — Feed

| Term / Concept | Definition |
|----------------|------------|
| **Feed** | A chronological stream of user-generated posts. Each post can have multiple responses (comments). |
| **Post** | A single feed item: author, content, timestamp. Rendered in the app as a section with responses nested underneath; sections separated by a divider. |
| **Response / Comment** | A reply to a post. Supports tagging: mention the post author or another commenter (Instagram/Glassdoor-style). |

**Backend scope**

- **Posts**: CRUD for posts (create, read, update, delete). Store: author (user id), content, timestamps, visibility/scope.
- **Comments**: CRUD for comments per post. Store: post id, author id, content, timestamp, optional in-reply-to (comment id) and optional mentioned user ids for tagging.
- **Feed API**: Paginated feed of posts with nested or paginated comments (e.g. first N comments per post); full comment thread loaded when user opens the post detail.
- **Post-detail view**: API to fetch a single post with full comment tree (all comments, replies, and mentioned users). Used by the “click on a post section” screen (not yet designed in UI).
- **Create-post flow**: API and validation for creating a post. UI for “make a post” is not yet designed; backend must be in place so the feed and create-post screen can load and submit data dynamically.

**Database / storage directives**

- **Table (or collection): `posts`**  
  Fields (conceptual): `id`, `author_id` (FK to users), `content` (text), `created_at`, `updated_at`, `scope` (e.g. feed vs bowl; see Bowls).

- **Table (or collection): `post_comments`**  
  Fields: `id`, `post_id` (FK), `author_id` (FK), `content` (text), `created_at`, `parent_comment_id` (nullable, for threading), `mentioned_user_ids` (array or junction table).

---

### 1.2 Community — Bowls

| Term / Concept | Definition |
|----------------|------------|
| **Bowl** | A group space (similar to a group chat). Expats are assigned to bowls; within a bowl they see messages and a mini feed. |
| **Country Bowl** | Bowl membership derived from “Country of Citizenship” at sign-up; expats are grouped by country. |
| **Job Hunting Bowl** | Bowl for expats looking for jobs. |
| **Expatriate Life in Rwanda Bowl** | Bowl for sharing experiences about life in Rwanda. |
| **Bowl membership** | Assignment of an expat to a bowl; determines what they see (chats and mini feed) from “when they joined”. |

**Backend scope**

- **Bowls**: CRUD for bowls (e.g. country bowls, Job Hunting, Expatriate Life in Rwanda). At current stage: assign each expat to exactly three bowls — (1) their country bowl, (2) Job Hunting, (3) Expatriate Life in Rwanda.
- **Bowl membership**: Create/read membership (user id, bowl id, joined_at). Country bowl membership is derived from user’s `country_of_citizenship`; the other two may be default or chosen at sign-up.
- **Bowl chats**: Messages within a bowl (group chat). Store: bowl id, sender id, content, timestamp. API: fetch messages from `joined_at` onward (or paginated).
- **Bowl mini feed**: Per-bowl posts and comments (same semantics as main feed but scoped to `bowl_id`). Posts/comments tables should support a `scope` or `bowl_id` so that the feed in a bowl only shows that bowl’s posts; comment threading and tagging behave like the main feed.

**Database / storage directives**

- **Table: `bowls`**  
  Fields: `id`, `name`, `type` (e.g. `country`, `job_hunting`, `expat_life_rwanda`), `country_code` (nullable, for country bowls), `created_at`.

- **Table: `bowl_members`**  
  Fields: `id`, `bowl_id` (FK), `user_id` (FK), `joined_at`.

- **Table: `bowl_messages`**  
  Fields: `id`, `bowl_id` (FK), `sender_id` (FK), `content` (text), `created_at`.

- **Posts in bowls**: Either add `bowl_id` (nullable) to `posts` or a dedicated `bowl_posts` table linked to `bowls` and reuse the same comment structure (e.g. `post_comments` with `post_id` pointing to bowl-scoped posts).

---

### 1.3 Rides Page

| Term / Concept | Definition |
|----------------|------------|
| **Rides** | Feature that shows a map of Kigali, Rwanda, and calculates taxi cost from airport to a given location. |
| **Get a ride** | Action on listing detail that passes the listing’s location into the Rides page search field. |

**Backend scope**

- **No backend storage required for core Rides flow.** Integration is with **Google Maps API** (and possibly a routing/fare API): display Kigali map, geocode listing address, compute route from airport to that location, and return distance/duration/fare.
- **Optional**: Log ride requests (user id, from, to, timestamp) for analytics or future booking — not required for “calculate cost” and “Get a ride” parsing.

**Implementation directives**

- Configure **Google Maps API** (and any routing/fare API) for Kigali, Rwanda.
- Implement: map view, search field for “location of the listing”, and cost calculation (airport → location).
- Implement: “Get a ride” on listing detail so that the listing’s location is passed into the Rides page and pre-fills the search field (client-side or via deep link/query param).

---

### 1.4 Explore Page

| Term / Concept | Definition |
|----------------|------------|
| **Explore** | Browse points of interest (places) around a listing’s location. |
| **Explore Area** | Action on listing detail that passes the listing’s location into the Explore page search. |

**Backend scope**

- **No backend storage required for core Explore flow.** Integration is with **Google Places API** and **Google Maps API**: search places near a given location (the listing’s area), display on map/list.
- **Optional**: Cache or store “saved places” per user — out of scope for initial plan unless specified.

**Implementation directives**

- Configure **Google Places API** and **Google Maps API** for the region (e.g. Kigali/Rwanda).
- Implement: Explore page with search and map/list of places around a location.
- Implement: “Explore Area” on listing detail so that the listing’s location is passed into the Explore page and pre-fills the search (client-side or via deep link/query param).

---

### 1.5 Estates Page

| Term / Concept | Definition |
|----------------|------------|
| **Listings** | Property listings (apartment, house, short-stay) that expats can browse and inquire about. |
| **Representative** | The contact for a listing: either the **Landlord** (owner) or an **Agent**. If the listing has no assigned agent, the representative is the landlord; otherwise the agent. |
| **Inquire** | Action that opens a conversation with the representative and sends an initial message plus a listing card. |

**Backend scope**

- **Listings**: CRUD and search/filter. Fields should include: type (apartment, house, short-stay), location, price, title, description, media, UPI, landlord id, optional agent id, status (e.g. draft, published, archived).
- **Search and filter**: Full-text or structured search (e.g. by location, type, price range) in addition to the existing UI filters (Apartments, Houses, Short-stay, All). Backend must support query params or a search API that the client uses.
- **Representative resolution**: For each listing, backend exposes whether the representative is the landlord or the agent (and their id/name). Client uses this to show “Landlord” or “Agent” and to route the conversation correctly.
- **Inquire**: Creating an inquiry creates (or reuses) a conversation between the expat and the representative and sends the first message (with optional listing card payload). Backend: conversations, messages, link message to listing.

**Database / storage directives**

- **Table: `listings`**  
  Fields: `id`, `landlord_id` (FK), `agent_id` (FK, nullable), `type`, `title`, `description`, `location`, `price`, `upi` (sensitive; only to landlord/agent), `status`, `created_at`, `updated_at`, etc. Media (images) stored as URLs or in a separate `listing_media` table.

- **Table: `conversations`**  
  Fields: `id`, `listing_id` (FK, nullable), `created_at`, etc. Participants (expat, landlord/agent) can be stored in `conversation_participants` (conversation_id, user_id, role).

- **Table: `messages`**  
  Fields: `id`, `conversation_id` (FK), `sender_id` (FK), `content` (text), `payload` (e.g. listing card JSON), `created_at`.

---

### 1.6 Messages (Expat)

| Term / Concept | Definition |
|----------------|------------|
| **Inbox** | The representative’s (Landlord or Agent) list of conversations; when an expat inquires, a new conversation and first message (with listing card) appear in the representative’s inbox. |
| **Chat space** | A conversation thread. After inquiring, the expat sees a new chat in the Messages tab; behaviour should mirror what was implemented for the Landlord workflow (back from conversation, chat appears in list). |

**Backend scope**

- **Conversations**: Create conversation on inquire (expat + representative), or reuse existing conversation for the same listing/user pair.
- **Messages**: Store and deliver messages; support optional listing card payload for the first (or any) message. API: list conversations for current user, get messages per conversation (paginated).
- **Real-time or polling**: Decide whether messages are delivered via WebSockets/push or polling; document in this plan when decided.
- **Translate**: See §1.8; message content may be stored in original language and translated on send/display for users with Translate on.

**Database / storage directives**

- Covered under §1.5 (`conversations`, `messages`). Ensure `messages` can store a structured payload (e.g. listing card) and that conversation list API returns last message and listing summary for card display.

---

### 1.7 Translate (All Parties)

| Term / Concept | Definition |
|----------------|------------|
| **Translate** | Feature that translates message text so Expats, Landlords, and Agents can communicate without a language barrier. |
| **Behaviour** | When a user has “Translate” toggled on, outgoing and/or incoming messages are translated (e.g. via Google Translate or an AI API) so that the recipient sees text in their preferred language. |

**Backend scope**

- **Preference**: Store per user whether Translate is enabled and optionally preferred display language (if different from app language).
- **Translation**: Either (a) translate on send and store translated copy per recipient, or (b) store original only and translate on display via client or a backend translation API. Document chosen approach.
- **API**: If translation is server-side, backend calls Google Translate (or chosen API) and returns/caches translated content; respect user’s Translate toggle and language settings.

**Database / storage directives**

- **User preferences**: In `users` or `user_settings` table: `translate_enabled` (boolean), `preferred_language` (code). Use for all three parties.

---

### 1.8 Authentication & Profile (Expats)

| Term / Concept | Definition |
|----------------|------------|
| **Onboarding (first screen)** | Collects: “What best describes you” (demographic), preferred language, and email. |
| **Verification** | Send a verification link to the provided email; user clicks to verify they are human (and that they control the email). |
| **Sign-up** | After verification: collect legal names, country of citizenship, and password; create account. |
| **Sign-in** | Returning users authenticate with email (or identifier) and password. |
| **Profile persistence** | For all three parties: save profile and progress so that when the user leaves the app and returns, their data and state are still available (backend-backed profile and session). |

**Backend scope**

- **Auth**: Registration (with email verification), login, session/token issue (e.g. JWT), logout, password reset.
- **Email verification**: Generate and store verification token (or link) for email; mark user as verified when link is used; token expiry.
- **User record (Expat)**: Store: email, legal name(s), country of citizenship, preferred language, “what best describes you”, password hash, email_verified_at, created_at, updated_at.
- **Localization**: Depending on preferred language, the entire app UI is translated for that user (client-side i18n keys + backend optionally serving locale or content).
- **Profile saving**: All three roles: profile data (name, contact, preferences) and critical progress (e.g. conversations, inquiries, draft posts) stored on backend and keyed by user id so that re-login restores state.

**Database / storage directives**

- **Table: `users`** (or separate `expats`, `landlords`, `agents` with shared auth)  
  Fields (conceptual): `id`, `email`, `password_hash`, `role` (expat | landlord | agent), `email_verified_at`, `preferred_language`, `created_at`, `updated_at`.  
  Expat-specific: `legal_name`, `country_of_citizenship`, `demographic` (what best describes you).

- **Table: `verification_tokens`** (or equivalent)  
  Fields: `id`, `user_id` or `email`, `token`, `expires_at`, `used_at` (nullable).

- **Sessions**: Either store session ids in a `sessions` table (user_id, token, expires_at) or use stateless JWT; document choice.

---

## 2. Landlord Workflow

*(To be filled in when you describe the Landlord workflow. Placeholder: listing creation, edit requests, verification by super admin, payments/commissions, representative assignment, inbox/conversations.)*

---

## 3. Agent Workflow

*(To be filled in when you describe the Agent workflow. Placeholder: commission slips, assignment to listings, payments, inbox/conversations.)*

---

## 4. Cross-Cutting / Super Admin

*(To be filled when you describe super admin: e.g. review queue for new listings and edit requests, approve/reject, user moderation.)*

---

## Document control

- **Purpose**: Single source of truth for what the backend and integrations must support for Expats, Landlords, and Agents.
- **Status**: Plan only; backend implementation not started.
- **Updates**: Add Landlord and Agent sections (and cross-cutting) as you describe those workflows; keep terminology consistent with this Expat section.
