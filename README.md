# ExpatHomes – Expat Support & Settlement Platform (Rwanda)

ExpatHomes is a mobile-first expat support platform designed to improve the experience of expats, international students, and foreign professionals relocating to Rwanda. The platform focuses on trust, communication, and verified services, addressing common challenges such as housing exploitation, language barriers, arrival logistics, and access to essential local services.

Rather than replacing existing service providers, ExpatHomes acts as a **connection hub**, integrating verified housing listings, real-time multilingual communication, location-based discovery, and trusted transport cost transparency into a single cohesive experience.

---

## Project Description

Relocating to a new country can be overwhelming, particularly for first-time arrivals. Expats often face:
- Unverified housing agents and opaque pricing
- Communication barriers with landlords and service providers
- Difficulty navigating unfamiliar locations
- Fragmented arrival and onboarding experiences
- Limited access to trusted community guidance

ExpatHomes addresses these issues by prioritizing:
- **Verified housing listings**
- **Direct, secure communication**
- **Role-based access control**
- **Lightweight integrations with trusted external services**
- **Community-driven knowledge sharing**

---

## Designs

### Figma Mockups

Design Link: *https://www.figma.com/design/ZzcXrh5VLp93Em9U8tpXK4/Expat?node-id=455-3067&t=Q0yACGkum3N2qMm0-1*

The interactive design prototype demonstrates the full system behavior and user flows, including:

- Community feed and topic-based groups (Bowls)
- Verified estate listings with inquiry-driven interaction
- Secure messaging with live translation
- Arrival support through transport cost estimation
- Location-based discovery via Google Maps
- Role-based interfaces for expats and agents/landlords

The designs are mobile-first and intentionally minimalist, prioritizing clarity, trust, and communication over transactional complexity.

---

## System Diagrams

The following diagrams guide the design and implementation of the system:

### 1. System Architecture Diagram
- Flutter mobile application (UI layer)
- Firebase backend services
  - Authentication
  - Firestore database
  - Cloud Storage
- External API integrations
  - Google Maps & Places API
  - Transport partner API (fare estimation)
- Secure client-to-service communication

### 2. Entity Relationship Diagram (ERD)
- Users (Expats, Agents/Landlords)
- Property Listings
- Inquiries
- Chat Sessions and Messages
- Community Posts

### 3. UML Class Diagram
- Core domain models
- Role inheritance and permissions
- Abstractions for translation and location discovery

*(Diagrams are included in the project documentation and design materials.)*

---

## Deployment Plan (Conceptual)

At the current stage, ExpatHomes focuses on **design, prototyping, and system modeling** rather than full production deployment.

### Planned Architecture
- **Frontend:** Flutter (Android / iOS)
- **Backend:** Firebase
  - Firebase Authentication (role-based access)
  - Cloud Firestore (real-time data storage)
  - Firebase Storage (media uploads)
- **External Services:**
  - Google Maps & Places API (Explore feature)
  - Transport partner API (ride cost estimation)

Production deployment and advanced backend logic are planned as future work beyond the capstone timeline.

---

## Video Demo

🎥 **Video Demo:** *(add link here)*

The demo showcases:
- Project motivation and problem context
- Community feature and Bowl-based interaction
- Verified estate listings and inquiry flow
- Secure messaging with live translation
- Explore feature using location-based discovery
- Rides feature for arrival cost transparency
- Role-based access behavior

---

## Current Project Phase

- ✅ Problem analysis and system requirements
- ✅ UX/UI design and interactive prototyping
- ✅ UML and system architecture modeling
- 🔄 Firebase-backed implementation (planned / in progress)
- 🔄 External API integrations (conceptual / limited scope)

---

## Key Technologies

### Design & Prototyping
- Figma

### Frontend
- Flutter (mobile-first development)

### Backend & Infrastructure
- Firebase Authentication
- Cloud Firestore
- Firebase Storage

### External APIs
- Google Maps & Places API
- Transport partner API (fare estimation only)

---

## Author

**Somtochukwu Nelson**  
**Email:** m.nelson@alustudent.com
**Supervisor:** Pelin Mutanguha
Project: ExpatHomes
