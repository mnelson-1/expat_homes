# Backend & Implementation Plan — Expat Homes

This document defines backend scope, data models, and implementation directives for all three user parties (Expats, Landlords, Agents). It is written in definitive, implementation-ready terminology. **Backend implementation has not started;** this file is the structural plan.

---

### Preferred language (all parties — Expats, Landlords, Agents)

**Note for all auth pages (signup, signin, and any other auth screens):** When **preferred language** is set by a user (during signup or in settings), it applies consistently across the product:

1. **Full interface translation**  
   **Every word** in that user’s interface must be shown in their preferred language. This includes **all auth pages** (signup, signin, verification, password reset, etc.) as well as every other screen in the app. There is no exception: the entire UI for that user is in their chosen language.

2. **Automatic translation of received messages**  
   The **same preferred language** is used to **automatically translate messages received** by that user. When someone sends them a message (in any language), the recipient sees it translated into their preferred language (subject to the Translate feature being enabled where applicable). So: preferred language drives both **in-app copy** (including auth) and **incoming message translation**.

This applies to **Expats, Landlords, and Agents** alike. Store `preferred_language` per user and use it for (a) UI locale/strings and (b) target language for message translation.

---

### Listing detail — full data (all parties)

**Current (placeholder) behaviour:** The listing detail screen is opened with data passed from the list or card (e.g. title, price, location, description, image path). Full details are not necessarily loaded from a single source of truth.

**Backend requirement:** When a user (**Expat**, **Landlord**, or **Agent**) opens a listing’s detail screen, the **full listing data** must be **fetched from the backend** by listing id (or stable slug). The detail view must not rely only on the payload passed from the list/card. This ensures:

- The detail screen always shows **complete, up-to-date** information (title, full description, location, price, all media, UPI where applicable, representative name, verification status, etc.).
- Edits or updates to a listing are reflected as soon as the user opens the detail.
- **Landlord workflow**: When a landlord opens “My Listings” and taps a card to view or “Request Edit”, the detail is loaded in full from the backend.
- **Agent workflow**: When an agent opens “Listings” (assigned listings) and taps a card to view, Decline, Accept, or “Chat Landlord”, the detail is loaded in full from the backend.
- **Expat workflow**: When an expat opens a listing from Estates (or from a message card), the detail is loaded in full from the backend.

**Implementation directive:** Provide a **GET listing by id** (or equivalent) API that returns the full listing record (including representative resolution, media, UPI for authorised roles only). The client **navigates** with listing id (or minimal context); the **detail screen** then **loads** the full listing via this API and renders it. List/card payloads may be used for preview or navigation only; the authoritative data for the detail view is the response of the GET listing API.

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
| **Representative** | The contact for a listing: either the **Landlord** (owner) or an **Agent**. If the listing has no assigned agent, or the assignment is not yet **accepted**, the representative is the landlord; once an agent has **accepted** the assignment, the representative is that agent. |
| **Representative name in listing detail** | The **name** shown in the listing detailed view is the **agent’s name** when there is an accepted assignment, otherwise the **landlord’s name** (see §2.1). The label shown is “Landlord” or “Agent” accordingly. |
| **Inquire** | Action that opens a conversation with the representative and sends an initial message plus a listing card. |

**Backend scope**

- **Listings**: CRUD and search/filter. Fields should include: type (apartment, house, short-stay), location, price, title, description, media, UPI, landlord id, optional agent id, status (e.g. draft, published, archived).
- **Search bar (Estates header)**: The search field (e.g. “Search Apartments…”) is **functional** and backed by the backend. Expats search for listings **by keywords** (e.g. title, location, description). Backend returns matching listings or an empty set. When there are **results**, they are displayed in the **same format** as when the user browses via the All / Apartments / Houses / Short-stay tabs (same card layout and behaviour). When there are **no results**, the client shows a clear “no results” state (e.g. message and optional suggestion). This is a **backend implementation**: an API (e.g. query param or search endpoint) that accepts a search term and returns matching listings; the client renders them in the existing Estates list/card format.
- **Search and filter**: Full-text or structured search (e.g. by location, type, price range) in addition to the existing UI filters (Apartments, Houses, Short-stay, All). Backend must support query params or a search API that the client uses.
- **Representative resolution**: For each listing, backend exposes whether the representative is the landlord or the agent (and their **id and name**). The **name** shown in the listing detail view must be: **agent’s name** if there is an assignment with status **accepted**; otherwise **landlord’s name**. Client uses this to show the correct name and “Landlord” or “Agent” label and to route the conversation correctly.
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

**Front-end parity request (Expat Messages ↔ Landlord Messages)**

- The **Expat Messages workflow** must be designed and implemented to the same level as the **Landlord Messages** workflow. Specifically:
  - **Messages tab (thread list)**: When the expat goes back to the Messages tab (not inside a chat), each conversation thread must show **timestamps** (e.g. last message time or “today”, “yesterday”) so expats can see when each chat was last active — matching the Landlord thread list behaviour.
  - **Timely threaded messages**: Conversations must be presented as **threaded by time** (e.g. date/time grouping or section headers) where appropriate, consistent with the Landlord chat experience.
  - **Full parity**: All behaviours implemented for Landlord messages (thread list with timestamps, back navigation, listing card in chat, automatic message on inquire, etc.) must have an equivalent for Expats so that the two flows are consistent and equally clear.

---

### 1.7 Translate (All Parties)

| Term / Concept | Definition |
|----------------|------------|
| **Translate** | Feature that translates message text so Expats, Landlords, and Agents can communicate without a language barrier. |
| **Behaviour** | When a user has “Translate” toggled on, outgoing and/or incoming messages are translated (e.g. via Google Translate or an AI API) so that the recipient sees text in their **preferred language**. Messages **received** by a user are automatically translated into that user’s preferred language (see cross-cutting note above). |

**Backend scope**

- **Preference**: Store per user whether Translate is enabled and **preferred_language** (used for both UI and as the target language for translating messages they receive).
- **Translation**: Either (a) translate on send and store translated copy per recipient, or (b) store original only and translate on display via client or a backend translation API. In all cases, **received** messages are shown to the user in their preferred language. Document chosen approach.
- **API**: If translation is server-side, backend calls Google Translate (or chosen API) and returns/caches translated content; respect user’s Translate toggle and **preferred_language** for message translation.

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
- **Localization**: Depending on **preferred language**, the **entire** app UI is translated for that user, **including all auth pages** (signup, signin, verification, etc.). Every word in their interface is in their preferred language. See the cross-cutting note “Preferred language (all parties)” at the top of this document. Implement via client-side i18n keys (and optionally backend-serving locale or content).
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

The Landlord front end is fully designed. Backend must support: find agents by region, assign agents to listings (one listing at a time), create/upload listings, request edits (super admin approval flow), messages (with and without assigned agent), and payments (commission slips from agents, pay via Momo mock).

---

### 2.1 Find Agents & Assign Property

| Term / Concept | Definition |
|----------------|------------|
| **Find Agents** | Landlord searches and filters agents by **region** within Kigali (e.g. Kimironko, Remera, Kacyiru, Kisimenti). Agents are seed data with IDs and profile info. |
| **Agent selection** | Landlord selects agents by **reviews**, **ratings**, and **region**. |
| **Assign Property** | Landlord assigns a selected agent to **one of their listed properties**. Only **one listing at a time** can be assigned via the “Assign Property” / select page. |
| **Assignment** | Links an agent to a listing so that the agent becomes the **representative** for that listing once the agent **accepts**; inquiries from expats then go to the agent. If no assignment or no accepted assignment, the representative is the landlord. |
| **Assignment acceptance** | The agent can **accept** (or decline) an assignment. Only when the assignment is **accepted** does the listing’s **representative name** in the listing detail view switch from the landlord’s name to the agent’s name. |
| **Representative name in listing detail** | The name shown in the **listing detailed view** (for Expats and any viewer) is: **agent’s name** if there is an assignment for that listing and the agent has **accepted**; otherwise **landlord’s name**. Default (no assignment) is always the landlord’s name. |

**Backend scope**

- **Agents**: Seed data (or CRUD) for agents: id, name, region (Kigali sub-region: Kimironko, Remera, Kacyiru, Kisimenti, etc.), reviews/ratings (or aggregate), and any profile fields used in the Find Agent UI.
- **Agent search/filter API**: Return agents filterable by region; sortable or filterable by ratings and reviews. Used by the Landlord “Find Agent” flow.
- **Assignments**: Create/read/update **listing–agent assignment**. One listing can have at most one assigned agent at a time. Store: listing_id, agent_id, assigned_at, assigned_by (landlord_id), **status** (e.g. pending, accepted, declined). When an assignment is created, trigger creation of a conversation between landlord and agent (see §2.4). When the agent **accepts**, update assignment status to accepted.
- **Representative resolution for listing detail**: For each listing, the backend must expose the **representative name** to show in the listing detailed view: if there exists an assignment with status **accepted**, use the **agent’s name**; otherwise use the **landlord’s name**. The API used by the listing detail screen (Expat, Landlord, or Agent) should return this resolved name (and optionally “Landlord” vs “Agent” as label).
- **Assign Property page**: Backend supports “list my listings” (for dropdown/select) and “assign this agent to this listing” in a single operation (one listing at a time).

**Database / storage directives**

- **Table: `agents`** (or `users` with role=agent)  
  Fields: `id`, name, region (e.g. enum or string: Kimironko, Remera, Kacyiru, Kisimenti, …), rating (numeric or aggregate), review_count or link to reviews table, and any other profile fields. **Seed data** for agents and IDs to be provided.

- **Table: `listing_assignments`** (or `listing_agent` junction)  
  Fields: `id`, `listing_id` (FK), `agent_id` (FK), `landlord_id` (FK), `assigned_at`, **`status`** (e.g. pending, accepted, declined). Enforce one active assignment per listing. Only **accepted** assignments determine that the listing’s representative name is the agent’s name; otherwise the listing detail shows the landlord’s name.

---

### 2.2 Estates — Listings, Upload, and Edit Requests

| Term / Concept | Definition |
|----------------|------------|
| **Make / upload listing** | Landlord creates a new listing (property details, media, etc.). Listing enters a workflow for super admin approval before it is visible to expats. |
| **Request edit** | Landlord requests to change details of an existing listing. They **send a request to the super admin**; no separate “what to change” form — the super admin approves or declines the request. |
| **Super admin approval (edit request)** | Super admin **approves** or **declines** the edit request. If **approved**, the listing enters an “editable” state: the landlord submits the actual changes; super admin **reviews those changes**; if valid, super admin **approves again** and the listing is **updated for all to see**. If declined, the request is closed and no change is made. |
| **Edit workflow** | Two-step approval: (1) approve/decline the request to edit; (2) after landlord submits changes, super admin reviews and approves or rejects the changes; on final approval, listing record is updated. |

**Backend scope**

- **Listings CRUD**: Landlord can create (upload) listings; store draft or pending state until super admin approves. Listings have: landlord_id, type, title, description, location, price, UPI, media, etc.
- **New listing submission**: Submit new listing for verification; super admin sees it in a queue, approves or rejects; on approval, listing becomes published (visible in Estates for expats). See §4 Cross-Cutting for super admin queue.
- **Edit request**: Landlord initiates “request edit” for a listing (no long form — just a request). Backend creates an **edit request** record (listing_id, landlord_id, status: pending). Super admin can **approve** or **decline**. On **approve**, landlord can then submit the actual changes (e.g. via the existing Edit Listing form); backend stores “pending changes” or a new revision. Super admin **reviews the changes**; if valid, **approves again** and backend **updates the listing** and marks request/revision complete. If super admin rejects the changes, landlord may be able to resubmit or the request is closed; define behaviour.
- **Listing status / lifecycle**: Define states, e.g. draft, pending_verification, published, edit_requested, edit_approved_pending_changes, changes_pending_review, etc., so that super admin and landlord UIs can drive flows correctly.

**Database / storage directives**

- **Table: `listings`**  
  As in §1.5; add `status` (e.g. draft, pending_verification, published, …) and optionally `published_at`, `verified_by` (super admin id).

- **Table: `listing_edit_requests`**  
  Fields: `id`, `listing_id` (FK), `landlord_id` (FK), `status` (pending, approved, declined), `reviewed_by` (super admin id), `reviewed_at`, `created_at`. When status = approved, landlord can submit changes.

- **Table: `listing_revisions`** (or `pending_listing_changes`)  
  Fields: `id`, `edit_request_id` (FK), `listing_id` (FK), snapshot of proposed fields (or diff), `status` (pending_review, approved, rejected), `reviewed_by`, `reviewed_at`, `created_at`. On approval, apply to `listings` and mark revision and edit request complete.

---

### 2.3 Messages (Landlord)

| Term / Concept | Definition |
|----------------|------------|
| **Conversation on assignment** | When the landlord **assigns a property** to an agent, a **conversation is automatically started** with that agent. An **automatic message** plus the **listing card** is sent (front end already designed) so they can discuss commission, house details, perks, etc. |
| **Inquiry to landlord** | When a listing has **no assigned agent**, expat inquiries go to the **landlord’s DM** (inbox). Landlord sees the conversation and listing card as in the designed front end. |
| **Live-translate** | At **send time**, messages are translated (e.g. via Google Translate or AI API) into the **landlord’s preferred language** (from sign-up). Same Translate behaviour as §1.7; landlord’s preferred language is stored and used as target for incoming messages. |

**Backend scope**

- **Auto-conversation on assign**: When `listing_assignments` (or equivalent) is created, create a **conversation** between landlord and agent; post an **automatic first message** and attach **listing card** payload (listing summary, image, price, location, etc.) so the thread is ready for discussion.
- **Inbox**: List conversations for the landlord (with agent or with expats); include last message and timestamp for thread list (timely threaded list with timestamps when returning to Messages tab — already designed on front end).
- **Translate**: Store landlord’s `preferred_language` (from sign-up); when a message is sent to the landlord, translate content to that language if the sender has Translate on or if the system sends translated copy. Backend or client implements per chosen approach in §1.7.

**Database / storage directives**

- **Conversations and messages**: Reuse §1.5 `conversations`, `conversation_participants`, `messages`. Ensure first message after assignment can carry listing card payload and be marked as “auto” or “system” if needed for UI.
- **User preferences**: Landlord’s `preferred_language` in `users` or `user_settings`; used for Translate target.

---

### 2.4 Payments (Landlord)

| Term / Concept | Definition |
|----------------|------------|
| **Commission slip** | Created by the **agent** (see §3 Agent Workflow). The slip is addressed to the **landlord** (by landlord name or landlord id) and contains payment details (amount, method e.g. Momo, recipient phone, etc.). |
| **Landlord Payments tab** | Commission slips sent to the landlord appear in the **Payments** tab (Track / Pay). Landlord can **pay via Momo** — **mock simulation** for this stage (no real payment processing). |
| **Track** | Landlord sees commission slips grouped by date (threaded by timestamp); can see status (e.g. pending, agent-confirmation-pending, confirmed). |
| **Pay** | From a slip or from the Pay tab, landlord fills or sees prefilled form and submits “pay via Momo”; backend records that the landlord claims to have paid (mock) and waits for **agent confirmation** before marking the slip as fully confirmed. |

**Backend scope**

- **Commission slips**: Agent creates a slip (amount, payment method, recipient phone, commission reference, agent id, **landlord id or name**). Backend stores slip and **delivers it to the landlord’s Payments stream** (by landlord id). Slips have status, for example: `pending` (awaiting landlord payment), `agent_confirmation_pending` (landlord has paid in Momo, waiting for agent to confirm), `confirmed` (agent has confirmed payment). See §3 for agent-side creation and confirmation.
- **List slips for landlord**: API returns commission slips for the current landlord (filter by landlord_id), ordered by date; support date-grouping (threaded by timestamp) for Track tab. Include slip details for Pay form prefill when landlord clicks “Pay” from a slip; show status so landlord can see when the agent has confirmed.
- **Pay (mock)**: When landlord submits “Pay via Momo”, backend moves slip to `agent_confirmation_pending` (not fully confirmed yet) and returns success; no real payment gateway. Optional: store payment timestamp and a “mock transaction id” for audit. Final status becomes `confirmed` only when the agent confirms on their side (see §3.3).

**Database / storage directives**

- **Table: `commission_slips`**  
  Fields: `id`, `agent_id` (FK), `landlord_id` (FK), `listing_id` (FK, optional), reference (e.g. COM-xxx), amount, currency, payment_method (e.g. MTN Momo), recipient_phone, status (`pending`, `agent_confirmation_pending`, `confirmed`), created_at, paid_at (nullable). Optional: contract_code, agent_name, estate_name for display.

---

## 3. Agent Workflow

### 3.1 Authentication & verification (Agent sign-up)

Agents sign up after the “What best describes you” step. They reach a **Verification** screen where they enter their **Agent ID** (issued by an external institution, e.g. RWAREB — Real Estate Broker regulatory body). The app validates this ID against a **database of licensed agents** (the app’s copy of or integration with the institution’s data; for now a seed/demo database).

| Term / Concept | Definition |
|----------------|------------|
| **Agent ID** | Unique identifier issued to an agent by the external institution (e.g. RWAREB) when they are licensed. Used to verify the agent’s identity at sign-up. |
| **RWAREB / institution database** | The external body that licenses agents and issues IDs. The app uses a **database of agents** (seed data or synced data) keyed by Agent ID; validation is done against this dataset. |
| **Valid ID** | The entered Agent ID exists in the app’s agent database. On success: UI shows “Valid ID” and the agent’s **first name** and **last name** are pulled from the database and pre-filled into the Legal name fields. |
| **Invalid ID** | The entered Agent ID is not found. UI shows “Invalid ID”; Legal name fields are not filled. Sign-up cannot proceed until a valid ID is entered. |
| **Legal name (Agent)** | First name and last name as held in the institution/app database for that Agent ID. Displayed as “First name on ID” and “Last name on ID”; pulled automatically on valid ID. |

**Backend scope**

- **Agent registry (seed/source of truth)**  
  Maintain a store of licensed agents keyed by **Agent ID** (and optionally region, etc.). For now this can be **seed/demo data**; later it may be synced from or validated against the institution’s (e.g. RWAREB) system.
- **Validate Agent ID at sign-up**  
  When the user types an Agent ID on the Verification screen, the client (or backend) checks it against the agent registry.  
  - **If valid**: Return (or client looks up) the agent’s **first name** and **last name**; client shows “Valid ID” and pre-fills the Legal name fields.  
  - **If invalid**: Client shows “Invalid ID”; no name data; user must correct the ID to proceed.
- **Sign-up flow**  
  Only allow sign-up once the ID is valid (and optionally once password and terms are completed). Persist the agent user with link to Agent ID (and preferred language, password hash, etc.) as for other roles. Profile persistence applies so that when they leave and return, their data and progress are stored.

**Database / storage directives**

- **Table (or collection): `licensed_agents`** (or `agent_registry`)  
  Source of agent records keyed by institution-issued ID.  
  Fields (conceptual): `agent_id` (unique, e.g. RWAREB-issued), `first_name`, `last_name`, optionally `region`, `created_at`, etc. For seed/demo, this is populated with test agents (e.g. KM-201903, RM-204112) so that validation and name pull can be demonstrated.  
  In production this may be synced from or validated against the external institution’s API/database.
- **Table: `users`** (or equivalent)  
  For agent users: store `agent_id` (FK or reference to `licensed_agents`), `role = 'agent'`, plus standard auth/profile fields (email, password hash, preferred_language, etc.). This links the in-app account to the licensed agent record so that the representative name and ID can be used in listings, commission slips, and messages.

### 3.2 Assigned listings — accept / decline (persistence)

Agents see **assigned listings** in two tabs: **Pending** (not yet decided) and **Accepted** (agent has accepted to represent). When an agent taps **Accept**, the listing moves from Pending to Accepted and must **persist** so the user sees it in the Accepted tab across sessions. When an agent taps **Decline**, the listing **disappears** from the agent’s feed (removed from Pending and not shown in Accepted); that state must also be stored so the listing does not reappear.

| Term / Concept | Definition |
|----------------|------------|
| **Pending** | Listings assigned to the agent on which they have not yet accepted or declined. Shown in the Pending tab with Decline / Accept actions. |
| **Accepted** | Listings the agent has accepted to represent. Stored so the agent sees them in the Accepted tab when they return. |
| **Declined** | Listings the agent has declined. Stored so they are removed from the feed and do not reappear in Pending or Accepted. |

**Backend scope**

- **Persist accept/decline state**  
  Store, per agent and per assigned listing, whether the agent has **accepted** or **declined**. When the agent opens the Listings screen, the backend returns:
  - **Pending**: assigned listings that have not yet been accepted or declined.
  - **Accepted**: assigned listings that have been accepted.
  - Declined listings are excluded from both lists (listing disappears from the agent’s feed).
- **APIs**  
  - List assigned listings for the current agent, with filter by status (pending vs accepted) and optionally by type (apartment, house, short-stay).  
  - When the agent taps Accept: record acceptance (e.g. `POST /agent/listings/:id/accept` or update assignment status).  
  - When the agent taps Decline: record decline (e.g. `POST /agent/listings/:id/decline` or update assignment status) so the listing is no longer returned for that agent.

**Database / storage directives**

- **Assignment/response store**  
  For each agent–listing assignment, persist the agent’s **response**: pending (no response yet), accepted, or declined. This can be a status on an `agent_listing_assignments` (or equivalent) table: e.g. `status` in `{'pending', 'accepted', 'declined'}`. Listings with status **accepted** are shown in the Accepted tab; **declined** are excluded from the feed; **pending** are shown in the Pending tab.

### 3.3 Commission slips & payments (Agent side)

Agents create **commission slips** and later **confirm** when landlords have paid. The actual money movement happens **outside** the app (e.g. MTN Momo SMS on the agent’s phone); the app only simulates and records the state of the slip.

| Term / Concept | Definition |
|----------------|------------|
| **Agent Payments tab** | For each agent, shows commission slips in a Track tab (threaded by date) and a Create tab where the agent creates new slips. Mirrors the Landlord Payments UI but from the agent’s perspective. |
| **Report slip** | Agent reports that a landlord has not paid or that there is an issue with a slip (e.g. wrong amount). Shows a “Report Successful” pop-up; later this will notify support / Super Admin. |
| **Confirm payment** | Agent confirms that a landlord has paid the commission (after cross-checking their external Momo SMS and any screenshots sent in the in-app Messages thread). This confirmation is what moves a slip to fully **confirmed** for both parties. |

**Backend scope**

- **Create commission slip (agent)**: API for agents to create slips (landlord id, listing id, amount, payment method, recipient phone, etc.). The **commission reference/ID (e.g. COM-xxxx)** is **generated by the backend at runtime** and returned to the client; the agent does **not** type this ID. New slips start in `pending` status and appear in both the agent’s and landlord’s Payments tabs.
- **Confirm payment (agent)**: When the agent taps **Confirm Payment**, backend updates slip status from `agent_confirmation_pending` to `confirmed`. Landlord’s Track tab reflects this change (status pill updates), but this is **not** tied to blockchain or real-time bank integration — it simply records the agent’s confirmation after they have checked their Momo SMS and any screenshot shared in Messages.
- **Report slip (agent)**: When the agent taps **Report**, backend records a report entry (e.g. reason, timestamp, who reported) and may notify support / Super Admin for follow-up. Status of the slip may remain `pending` or move into a separate “under_review” state depending on product rules; for now, we just capture the report event.

**Database / storage directives**

- Reuse `commission_slips` (see §2.4) as the single source of truth for slip status and details.
- Optional: `commission_slip_reports` table with `id`, `slip_id`, `reported_by_agent_id`, optional `reason`, `created_at`, and a lightweight review/status field for support.

*(Further Agent workflow sections — inbox, deeper reporting, reconciliation — to be added as screens and flows are designed.)*

---

## 4. Super Admin — Verification & Regulation of Listings

The Super Admin coordinates **(1) verification of new listings before they go live** and **(2) regulation of listing edits** (approving edit requests and then reviewing the actual changes). They do **not** use the same flows as Expats, Landlords, or Agents; they need a way to see pending work and take action.

---

### 4.1 What the Super Admin does (summary)

| Responsibility | Description |
|----------------|-------------|
| **Verify new listings** | Landlords submit listings for verification. Super Admin receives a **queue of listings pending verification**. They review each listing and **approve** (listing goes live for Expats) or **reject** (listing stays draft or is returned to landlord). |
| **Regulate edit requests** | Landlords request permission to edit a listing. Super Admin receives **edit requests** and can **approve** or **decline**. If approved, the landlord can then submit the actual changes. |
| **Review submitted changes** | After an edit request is approved, the landlord submits the new listing data (changes). Super Admin receives a **queue of pending changes** to review. They **check if the changes are valid** and either **approve** (listing is updated for all to see) or **reject** (changes are not applied; landlord may resubmit or the request is closed, depending on product rules). |

So the Super Admin needs to see **three types of items**: (a) new listings awaiting verification, (b) edit requests awaiting approval/decline, (c) submitted changes awaiting review (approve/reject).

---

### 4.2 Do we need another interface for the Super Admin?

**Yes.** Expats, Landlords, and Agents use the existing app for browsing, messaging, payments, etc. The Super Admin does **none** of that; they only do verification and regulation. So they need a dedicated way to:

- See **queues** (pending listings, edit requests, pending changes)
- Open each item, review details (and, for changes, optionally see a **diff** vs current listing)
- **Approve** or **Reject** (and optionally add a short reason or comment)

That “dedicated way” can be implemented in different forms. Below are the main options so you can choose what fits your team and users.

---

### 4.3 Interface options (for discussion)

| Option | Description | Pros | Cons |
|--------|-------------|------|------|
| **A. Separate web admin panel** | Build a **web-only** dashboard (e.g. `admin.expathomes.com` or a path like `/admin`). Super Admin logs in in a **browser** and sees queues, filters, and actions. Mobile app stays for Expats, Landlords, Agents only. | Familiar for admins; easy to handle tables, filters, bulk actions; one clear “admin” place. | Two UIs to build and maintain (mobile app + web admin). |
| **B. Same app, role-based screens** | Keep **one** (mobile) app. When the user logs in with a **Super Admin** account, they get a different home: e.g. tabs like “Verification”, “Edit requests”, “Change reviews” instead of Estates/Messages. Same codebase, different navigation and screens by role. | Single codebase; one app to install. | Admin workflows on a small screen can be tight; may need a tablet or “admin” profile for larger devices later. |
| **C. Web admin + optional read-only in app** | Primary interface for Super Admin is a **web dashboard** (as in A). Optionally, a “Super Admin” role in the mobile app could show a **simplified** view (e.g. “You have N items to review” with a link or deep link to the web dashboard). | Clear separation; admins work on web; mobile can still notify or surface counts. | More moving parts if you add the mobile slice. |

**Suggested recommendation: Option A — separate web admin panel.**  
Super Admin work is back-office: queues, review, approve/reject. That workflow is better on a **larger screen** (tables, filters, side‑by‑side diff for changes). A **separate web app** (e.g. `admin.yourapp.com`) keeps the mobile app focused on Expats, Landlords, and Agents; avoids a large set of admin-only screens in the same app; and matches how most teams run listing moderation. The backend APIs are the same; only the UI lives in a different (web) project. You can add a lightweight in-app “You have N pending” + link to web later (Option C) if needed.

---

### 4.4 How can this be done? (Backend and interface)

**Backend (regardless of which interface option you pick):**

- **Auth & role**  
  - Super Admin is a **role** (e.g. `role = super_admin`). Only users with this role can access Super Admin APIs and, if you use the same app, the admin screens.  
  - Sign-in for Super Admin can be the same auth system (email/password or SSO) with role checks.

- **APIs for the three queues**  
  - **Listings pending verification**: e.g. `GET /admin/listings/pending` (or similar). Returns listings in status “pending_verification” (or equivalent).  
  - **Edit requests**: e.g. `GET /admin/edit-requests`. Returns edit requests in “pending”.  
  - **Pending changes (revisions)**: e.g. `GET /admin/revisions/pending`. Returns submitted changes that are awaiting review.  
  - **Actions**:  
    - For a listing: `POST /admin/listings/:id/approve`, `POST /admin/listings/:id/reject`.  
    - For an edit request: `POST /admin/edit-requests/:id/approve`, `POST /admin/edit-requests/:id/decline`.  
    - For a revision: `POST /admin/revisions/:id/approve`, `POST /admin/revisions/:id/reject`.  
  - Optional: include a **reason** or comment in the body of reject/decline for the landlord to see.

- **Data already in the plan**  
  - Listings (with status), `listing_edit_requests`, and `listing_revisions` (or equivalent) are already described in §2.2. The Super Admin APIs **read** from these tables and **update** their status when the admin approves or rejects.

**Interface (depends on Option A, B, or C):**

- **If web admin (A or C):**  
  - Build a separate web app (e.g. React, Vue, or simple server-rendered pages) that calls the above APIs.  
  - Screens: login → dashboard with three sections or tabs (pending listings, edit requests, pending changes) → detail view per item (listing full data, or diff for changes) → approve/reject buttons.  
  - Host it on a subdomain or path that only Super Admins use.

- **If same app (B):**  
  - In the existing app, after login, if `role == super_admin` show a different “home” (e.g. Super Admin dashboard).  
  - That dashboard fetches the same APIs and shows the three queues; tapping an item opens a detail screen; approve/reject call the action APIs.  
  - No separate app; reuse auth and API client, add new screens and navigation for Super Admin only.

**Security & audit:**  
- All admin endpoints must **check** that the authenticated user has the Super Admin role; otherwise return 403.  
- Optionally store an **audit log** (who approved/rejected what, when) for compliance and support.

---

### 4.5 Database / storage (recap)

- **Listings**: `status` includes a state for “pending verification”; when Super Admin approves, set to “published” (or equivalent); when rejected, set to “rejected” or “draft” as you define.  
- **listing_edit_requests**: `status` (e.g. pending, approved, declined); Super Admin sets it when they approve/decline.  
- **listing_revisions** (or pending changes): `status` (e.g. pending_review, approved, rejected); Super Admin sets it when they approve/reject the changes; on approve, apply the revision to the listing.  
- **users**: ensure a role or flag identifies Super Admins (e.g. `role = 'super_admin'`).  
- **Optional**: `admin_audit_log` table (admin_user_id, action, entity_type, entity_id, created_at, reason) for tracking approvals/rejections.

---

### 4.6 Open decisions to confirm

- **Interface choice**: Web-only admin (A), in-app role-based (B), or web + lightweight in-app (C)? **Suggested default: A (separate web admin).**  
- **Rejection reason**: Should the landlord see a mandatory or optional reason when a listing or edit is rejected?  
- **Revisions**: After rejecting a change, can the landlord resubmit the same or a new revision, or is the edit request closed?  
- **Notifications**: Should the landlord (or agent) be notified in-app or by email when the Super Admin approves or rejects?

Once you decide the interface option and the above product rules, the backend plan above is enough to implement the APIs and data model; the chosen interface then consumes those APIs.

---

## Document control

- **Purpose**: Single source of truth for what the backend and integrations must support for Expats, Landlords, and Agents.
- **Status**: Plan only; backend implementation not started.
- **Updates**: Add Landlord and Agent sections (and cross-cutting) as you describe those workflows; keep terminology consistent with this Expat section.
