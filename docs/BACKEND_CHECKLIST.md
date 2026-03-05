# Expat Homes — Backend Implementation Checklist

Use this file as a single checklist to implement the backend for the full ecosystem: **Super Admin (web)**, **Expat**, **Landlord**, and **Agent** roles. Tables, APIs, and directives are listed so you can work through them in order.

---

## 1. Database tables

Create and maintain these tables (or equivalent in your DB).

### 1.1 Users & auth

| Table | Purpose | Key fields |
|-------|---------|------------|
| `users` | All authenticated users (Expat, Landlord, Agent, Super Admin). | `id`, `email`, `password_hash`, `role` (expat \| landlord \| agent \| super_admin), `email_verified_at`, `preferred_language`, `created_at`, `updated_at`. Expat: `legal_name`, `country_of_citizenship`, `demographic`. Landlord/Agent: extend or link to profile tables. |
| `verification_tokens` | Email verification (sign-up). | `id`, `email` or `user_id`, `token`, `expires_at`, `used_at` (nullable). |
| `sessions` | Optional: store session ids if not using stateless JWT. | `id`, `user_id`, `token`, `expires_at`. |

### 1.2 Listings & media

| Table | Purpose | Key fields |
|-------|---------|------------|
| `listings` | Property listings. | `id`, `landlord_id` (FK), `agent_id` (FK, nullable), `type` (apartment \| house \| short_stay), `title`, `description`, `location` / `address`, `price`, `upi` (sensitive), `status` (draft \| pending_verification \| published \| archived \| …), `created_at`, `updated_at`, `published_at`, `verified_by` (admin user id, nullable). |
| `listing_media` | Images/files per listing. | `id`, `listing_id` (FK), `url` or `path`, `sort_order`, `created_at`. (Alternatively store `media` as JSON array of URLs on `listings`.) |

### 1.3 Super Admin — verification & edit requests

| Table | Purpose | Key fields |
|-------|---------|------------|
| `listing_edit_requests` | Landlord request to edit a listing (step 1). | `id`, `listing_id` (FK), `landlord_id` (FK), `status` (pending \| approved \| declined), `reviewed_by` (admin user id), `reviewed_at`, `created_at`. |
| `listing_revisions` | Proposed changes after edit request approved (step 2). | `id`, `edit_request_id` (FK), `listing_id` (FK), snapshot/diff of proposed fields (or full copy), `status` (pending_review \| approved \| rejected), `reviewed_by`, `reviewed_at`, `created_at`. On approve: apply to `listings`, then mark revision and edit request complete. |
| `admin_audit_log` | Optional: who approved/rejected what. | `id`, `admin_user_id`, `action`, `entity_type`, `entity_id`, `reason` (nullable), `created_at`. |

### 1.4 Agents & assignments

| Table | Purpose | Key fields |
|-------|---------|------------|
| `licensed_agents` (or `agent_registry`) | Seed/source of truth for RWAREB-issued agents. | `agent_id` (unique), `first_name`, `last_name`, `region` (e.g. Kimironko, Remera), optionally `created_at`. |
| `listing_assignments` | Landlord assigns agent to listing; agent accepts/declines. | `id`, `listing_id` (FK), `agent_id` (FK), `landlord_id` (FK), `assigned_at`, `status` (pending \| accepted \| declined). One active assignment per listing. |
| `agent_profiles` | Agent profile (bio, phone, image). | `user_id` (FK), `agent_id` (FK to licensed_agents), `first_name`, `last_name`, `profile_image_url`, `bio`, `phone_for_payments`, `languages`, `rating`, `rating_count`, `created_at`, `updated_at`. |
| `agent_reviews` | Reviews for agents. | `id`, `agent_id` (FK), `author_user_id` (FK, optional), `rating` (1–5), `title`, `body`, `created_at`. |

### 1.5 Conversations & messages

| Table | Purpose | Key fields |
|-------|---------|------------|
| `conversations` | Chat threads (expat↔rep, landlord↔agent, etc.). | `id`, `listing_id` (FK, nullable), `created_at`. |
| `conversation_participants` | Who is in each conversation. | `id`, `conversation_id` (FK), `user_id` (FK), `role` (optional). |
| `messages` | All messages; persist full history. | `id`, `conversation_id` (FK), `sender_id` (FK), `content` (text), `payload` (JSON e.g. listing card), `created_at`. Return full history when user opens a conversation. |

### 1.6 Community — feed & bowls

| Table | Purpose | Key fields |
|-------|---------|------------|
| `posts` | Feed posts. | `id`, `author_id` (FK), `content`, `created_at`, `updated_at`, `scope` (e.g. feed \| bowl), `bowl_id` (nullable). |
| `post_comments` | Comments/replies. | `id`, `post_id` (FK), `author_id` (FK), `content`, `created_at`, `parent_comment_id` (nullable), `mentioned_user_ids` (array or junction). |
| `bowls` | Group spaces (country, Job Hunting, Expatriate Life, etc.). | `id`, `name`, `type`, `country_code` (nullable), `created_at`. |
| `bowl_members` | Membership. | `id`, `bowl_id` (FK), `user_id` (FK), `joined_at`. |
| `bowl_messages` | Group chat per bowl. | `id`, `bowl_id` (FK), `sender_id` (FK), `content`, `created_at`. |

### 1.7 Payments (Landlord & Agent)

| Table | Purpose | Key fields |
|-------|---------|------------|
| `commission_slips` | Slips created by agent, paid by landlord. | `id`, `agent_id` (FK), `landlord_id` (FK), `listing_id` (FK, optional), `reference` (e.g. COM-xxx, backend-generated), `amount`, `currency`, `payment_method`, `recipient_phone`, `status` (pending \| agent_confirmation_pending \| confirmed), `created_at`, `paid_at` (nullable). |
| `commission_slip_reports` | Optional: agent reports issue with slip. | `id`, `slip_id` (FK), `reported_by_agent_id`, `reason`, `created_at`. |

### 1.8 User preferences (Translate, etc.)

| Table | Purpose | Key fields |
|-------|---------|------------|
| `user_settings` (or columns on `users`) | Translate, language. | `user_id`, `translate_enabled`, `preferred_language`. Used for UI locale and for translating **received** messages into user’s preferred language. |

---

## 2. APIs to implement

Group by domain; assume auth (JWT or session) and role checks where noted.

### 2.1 Auth (all roles)

- [ ] `POST /auth/register` — body: role, email, password, (expat: legal_name, country_of_citizenship, preferred_language, demographic; agent: agent_id from registry). Create user; send verification.
- [ ] `POST /auth/verify-email` — token in body or query; mark email verified.
- [ ] `POST /auth/login` — email, password; return token/session and user (id, role, preferred_language, …).
- [ ] `POST /auth/logout` — invalidate session/token.
- [ ] `POST /auth/forgot-password` — send reset link/token.
- [ ] `POST /auth/reset-password` — token + new password.

### 2.2 Super Admin (web)

- [ ] `POST /admin/auth/login` — Super Admin login (or reuse `/auth/login` + role check).
- [ ] `GET /admin/listings/pending` — list listings with `status = pending_verification`. Auth: super_admin.
- [ ] `GET /admin/listings/:id` — full listing (for detail view: images, UPI, landlord, etc.). Auth: super_admin.
- [ ] `POST /admin/listings/:id/approve` — set listing status to published; set `verified_by`, `published_at`. Auth: super_admin.
- [ ] `POST /admin/listings/:id/reject` — set status to rejected/draft; optional body `reason`. Auth: super_admin.
- [ ] `GET /admin/edit-requests` — list edit requests (e.g. filter by status: pending for “table 1”; or separate endpoint for “ready for review”). Auth: super_admin.
- [ ] `GET /admin/edit-requests/pending/:id` — full listing for that edit request (for “pending” detail view). Auth: super_admin.
- [ ] `POST /admin/edit-requests/:id/approve` — set edit request status to approved (landlord can then submit changes). Auth: super_admin.
- [ ] `POST /admin/edit-requests/:id/decline` — set status to declined. Auth: super_admin.
- [ ] `GET /admin/revisions/pending` — list revisions with `status = pending_review` (for “table 2” / ready for review). Auth: super_admin.
- [ ] `GET /admin/revisions/:id` — return previous listing snapshot + proposed (updated) snapshot for comparison. Auth: super_admin.
- [ ] `POST /admin/revisions/:id/approve` — apply revision to listing; set revision and edit request complete. Auth: super_admin.
- [ ] `POST /admin/revisions/:id/reject` — set revision status to rejected; optional reason. Auth: super_admin.

### 2.3 Listings (Estates — Expat, Landlord, Agent)

- [ ] `GET /listings` — list published listings; query: search, type, location, price range, etc. Used by Estates search and filters.
- [ ] `GET /listings/:id` — full listing by id (for detail screen). Return representative (landlord or agent name and label) and full data; UPI only for landlord/agent.
- [ ] `POST /listings` — create listing (landlord). Body: type, title, description, location, price, media URLs or upload refs. Set status = pending_verification.
- [ ] `PUT /listings/:id` — update listing (landlord, only when edit request approved and revision approved; or draft). Enforce workflow.
- [ ] `GET /landlord/listings` — list listings for current landlord (my listings).
- [ ] Representative resolution: in `GET /listings/:id` (and list responses), expose representative name and role: if assignment exists with status accepted, use agent name; else landlord name.

### 2.4 Listing media / uploads

- [ ] `POST /listings/:id/media` — upload image(s) for listing; return URLs (or store in `listing_media`). Auth: landlord (owner) or after edit approved.
- [ ] Or: use a generic `POST /upload` that returns URL; client then sends that URL in listing create/update. Ensure URLs are stable and served (e.g. object storage + CDN).

### 2.5 Edit requests (Landlord)

- [ ] `POST /listings/:id/request-edit` — create `listing_edit_requests` row (status pending). Auth: landlord (owner).
- [ ] `GET /landlord/edit-requests` — list edit requests for landlord’s listings (optional; for “my requests” UI).
- [ ] After admin approves edit request: `PUT /listings/:id` or `POST /listings/:id/submit-revision` — landlord submits new data; create `listing_revisions` row (status pending_review).

### 2.6 Agents (Landlord & Agent)

- [ ] `GET /agents` — list agents; query: region, sort by rating. Used by Landlord “Find Agent”. Seed from `licensed_agents` (+ profile/reviews).
- [ ] `GET /agents/:id` — agent profile (for Agent Bio-View and Landlord selection).
- [ ] `POST /agents/validate-id` — validate agent ID (e.g. at sign-up); return first_name, last_name if valid. Used by Agent verification screen.
- [ ] `POST /listing-assignments` — landlord assigns agent to listing. Body: listing_id, agent_id. Create assignment (status pending); create conversation + auto first message with listing card.
- [ ] `GET /agent/assignments` — list assignments for current agent; filter by status (pending \| accepted \| declined).
- [ ] `POST /agent/listings/:id/accept` — set assignment status to accepted.
- [ ] `POST /agent/listings/:id/decline` — set assignment status to declined.
- [ ] `GET /agent/profile`, `PUT /agent/profile` — read/update agent profile (bio, phone, image URL).
- [ ] `GET /agent/reviews` — paginated reviews for current agent.
- [ ] `POST /agent/reviews` — submit review (e.g. from “Tap to Rate”). Update agent aggregate rating/count.

### 2.7 Conversations & messages (all parties)

- [ ] `POST /conversations` — create conversation (e.g. on Inquire: expat + representative; or on assignment: landlord + agent). Optional: listing_id, initial message + listing card payload.
- [ ] `GET /conversations` — list conversations for current user; include last message and listing summary for thread list. Role-aware (expat sees expat threads; landlord sees landlord threads; agent sees agent threads).
- [ ] `GET /conversations/:id/messages` — full message history for conversation (paginated if needed). Persist and return all messages so chat continues from where user left off.
- [ ] `POST /conversations/:id/messages` — send message; body: content, optional payload (e.g. listing card). Store in `messages`; if Translate enabled, optionally store or compute translated copy per recipient preferred_language.

### 2.8 Inquire (Expat)

- [ ] On “Inquire”: ensure conversation exists (expat + representative for that listing); send first message with listing card. Reuse conversations and messages APIs.

### 2.9 Commission slips & payments

- [ ] `POST /agent/commission-slips` — create slip (landlord_id, listing_id, amount, payment_method, recipient_phone, etc.). Backend generates reference (e.g. COM-xxx). Status = pending.
- [ ] `GET /agent/commission-slips` — list slips for current agent (Track tab).
- [ ] `GET /landlord/commission-slips` — list slips for current landlord (Track/Pay tab).
- [ ] `POST /landlord/commission-slips/:id/pay` — mock “pay via Momo”; set status = agent_confirmation_pending, set paid_at.
- [ ] `POST /agent/commission-slips/:id/confirm` — agent confirms payment; set status = confirmed.
- [ ] `POST /agent/commission-slips/:id/report` — record report (optional table); optional status or notify support.

### 2.10 Community — feed & bowls

- [ ] `GET /posts` — paginated feed; optional scope/bowl_id. Include comment count or first N comments.
- [ ] `GET /posts/:id` — single post with full comment tree.
- [ ] `POST /posts` — create post (body: content, scope, bowl_id if bowl).
- [ ] `PUT /posts/:id`, `DELETE /posts/:id` — update/delete own post.
- [ ] `GET /posts/:id/comments` — comments for post (nested if needed).
- [ ] `POST /posts/:id/comments` — add comment (body: content, parent_comment_id, mentioned_user_ids).
- [ ] `GET /bowls` — list bowls (e.g. for current user’s memberships).
- [ ] `GET /bowls/:id/messages` — messages in bowl (from user’s joined_at onward or paginated).
- [ ] `POST /bowls/:id/messages` — send message to bowl.
- [ ] Bowl membership: assign expat to bowls (country + Job Hunting + Expatriate Life) on sign-up or via endpoint.

### 2.11 Rides & Explore (Expat)

- No backend storage required for core flow. Integrate **Google Maps API** (geocode, route, fare) and **Google Places API** (places near listing). “Get a ride” / “Explore Area” pass listing location from client to these flows (query param or client-side).

---

## 3. Directives & business rules

### 3.1 Preferred language (all roles)

- Store `preferred_language` per user. Use for: (a) **full UI translation** (every screen, including auth), and (b) **translation of received messages** into that language when Translate is on.

### 3.2 Listing detail — always from backend

- When any user (Expat, Landlord, Agent) opens a listing detail screen, **load full listing by id** from `GET /listings/:id`. Do not rely only on list/card payload. Ensures up-to-date data and correct representative name.

### 3.3 Representative name

- For each listing: if there is an assignment with status **accepted**, representative = agent (name + “Agent” label). Otherwise representative = landlord (name + “Landlord” label). Expose in listing API response.

### 3.4 Message persistence

- **All** messages in **all** conversations (expat↔rep, landlord↔agent, agent↔landlord) are **persisted**. When a user opens a conversation, return **full message history** so the thread continues from where they left off.

### 3.5 Super Admin scope

- Super Admin **only**: (1) verify new listings (approve/reject), (2) approve/decline edit requests, (3) approve/reject submitted changes (revisions). No agent verification or review moderation in this role; agents are validated against `licensed_agents` (RWAREB seed) at sign-up.

### 3.6 Edit request flow (two steps)

1. Landlord requests edit → `listing_edit_requests` (pending). Super Admin approves or declines.  
2. If approved, landlord submits changes → `listing_revisions` (pending_review). Super Admin approves (apply to listing) or rejects.  
Rejection reason and “can landlord resubmit?” are product decisions to document.

### 3.7 Assignment flow

- One listing → at most one assignment at a time. On assign: create conversation + auto first message with listing card. Only when agent **accepts** does representative switch to agent. Declined assignments are excluded from agent’s lists.

### 3.8 Security

- All admin endpoints: verify authenticated user has role `super_admin`; else 403.
- Listings: UPI and sensitive fields only to authorised roles (landlord, agent, admin).
- Auth: hash passwords; use HTTPS; JWT or session expiry.

### 3.9 File storage

- Listing images and agent profile image: store in object storage (e.g. S3-compatible); expose stable URLs. Upload API returns URL; listing and profile store that URL.

---

## 4. Suggested implementation order

1. **Auth & users** — tables, register/login, verification, roles.  
2. **Listings & media** — tables, CRUD, status, upload/URLs.  
3. **Super Admin APIs** — pending listings, approve/reject; edit requests and revisions (list, detail, approve/decline, approve/reject).  
4. **Agents & assignments** — licensed_agents seed, assignments, accept/decline, representative resolution.  
5. **Conversations & messages** — tables, create conversation (inquire + assignment), send message, list conversations, get full history.  
6. **Community** — posts, comments, bowls, bowl messages.  
7. **Payments** — commission_slips, create/confirm/report, landlord pay (mock).  
8. **Translate** — preferred_language, translate_enabled; message translation (server or client) per product choice.  
9. **Rides / Explore** — Google Maps and Places integration (no new tables).

---

## 5. Document control

- **Purpose**: Single checklist for backend implementation (tables, APIs, directives) for Super Admin and all app roles.  
- **Companion**: See `BACKEND_IMPLEMENTATION_PLAN.md` for full workflow and terminology.  
- **Frontend**: Super Admin web app and Flutter app (Expat, Landlord, Agent) are implemented; they expect these APIs and data shapes to plug in seamlessly.
