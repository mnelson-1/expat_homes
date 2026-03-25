# ExpatHomes – Expat Support & Settlement Platform (Rwanda)
-----

ExpatHomes is a mobile-first expat support platform designed to improve the experience of expats, international students, and foreign professionals relocating to Rwanda. The platform focuses on trust, communication, and verified services, addressing common challenges such as housing exploitation, language barriers, arrival logistics, and access to essential local services.

Rather than replacing existing service providers, ExpatHomes acts as a **connection hub**, integrating verified housing listings, real-time multilingual communication, location-based discovery, and trusted transport cost transparency into a single cohesive experience.

---

## Project Description

Relocating to a new country can be overwhelming, particularly for first-time arrivals. In Kigali’s evolving real estate market, expatriates often encounter:

- Unverified housing listings and informal brokerage practices
- Opaque agent commission structures and inconsistent pricing
- Limited visibility into agent credentials
- Communication barriers between landlords, agents, and international tenants
- Fragmented arrival and neighbourhood discovery experiences
- Lack of structured accountability in property negotiations

ExpatHomes addresses these issues by prioritising:

- Verified property listings (admin-reviewed ownership validation before publication)
- Licensed agent verification workflow (credential-based access control before platform entry)
- Exclusive agent delegation model (one verified agent per property)
- Structured commission tracking system using internal reference IDs
- Landlord-uploaded rental contracts for transparency and documentation
- Role-based access control (Expat, Landlord, Agent, Admin)
- Secure in-app messaging with multilingual support and live translation
- Neighbourhood intelligence (“Explore”) powered by location services
- Arrival mobility support (“Rides”) integration concept
- Community-driven peer knowledge sharing and feedback features

This Link will lead you to the Final Version of the Product Solution - (https://drive.google.com/drive/u/0/folders/1_AMhxyJX8jGhNmvqjKVwZOvtTcxecxAB)

---

## Final version of the product/solution

Video has been uploaded to the directory

Installation Process...
to run this project you must have flutter sdk and react on your pc

1. Download Zip file
2. Change Directory to expat_app [cd expat_homes\expat_app]

- Run the command [flutter pub get] - to install and fetch all dependencies
- Run the command [flutter run] - to get the app running.

3. Go back to the root directory, and then go into the admin-web directory of the root

- cd expat_homes\admin-web
- Run the command [npm install] - to install dependencies
- Run the command [npm run dev] - to get the web app running.

4. While the webapp for the superadmin is running please use this credentials to log in:
   email: admin@expathomes.rw
   pssd: admin123
5. Now you can test the full functioning solution...

---

## Designs

### Figma Mockups

Design Link: *https://www.figma.com/design/ZzcXrh5VLp93Em9U8tpXK4/Expat?node-id=455-3067&t=Q0yACGkum3N2qMm0-1*

The interactive design prototype demonstrates the full system behaviour and user flows, including:

- Community feed and topic-based groups (Bowls)
- Verified estate listings with inquiry-driven interaction
- Secure messaging with live translation
- Arrival support through transport cost estimation
- Location-based discovery via Google Maps
- Role-based interfaces for expats, agents, and landlords
- Mock Payment workflows
- Commission and payment status tracker
- Agent Rating and Allocation
- Landlord Assignment

The designs are mobile-first and intentionally minimalist, prioritising clarity, trust, and communication over transactional complexity.

<div align="center">
  <img src="png_directory/figma_mockups/Welcome Screen.png">
  <img src="png_directory/figma_mockups/Community Page 1_Feed.png">
  <img src="png_directory/figma_mockups/Estate Page 3.png">
  <img src="png_directory/figma_mockups/Messages Epat Interface 2.png">
  <img src="png_directory/figma_mockups/Landlord Interface 2.png">
  <img src="png_directory/figma_mockups/Rides Interface 2.png">
  <img src="png_directory/figma_mockups/Rides Interface 3.png">
</div>
---

## System Diagrams

The following diagrams guide the design and implementation of the system:

### 1. System Architecture Diagram

The system architecture illustrates how ExpatHomes is structured as a mobile-first platform backed by Firebase services and external APIs. The mobile application serves as the primary interface for all users (Expats, Agents/Landlords, and Service Providers), while Firebase handles backend responsibilities such as authentication, data storage, and real-time communication. External services such as Google Maps and partner transport providers (e.g., Move) are integrated to support location discovery and ride cost estimation without replicating existing third-party solutions.

<div align="center">
  <img src="png_directory/sys_dir/SYS ARCH.png" alt="SYS Diagram">
</div>

### 2. Entity Relationship Diagram (ERD)

The ERD provides a database-level view of how data is structured and related within Firestore. It focuses on persistence concerns such as ownership, foreign-key–like references, and cardinality between users, listings, inquiries, chats, and messages. The ERD ensures data consistency, scalability, and clarity in how information flows through the system.

<div align="center">
  <img src="png_directory/sys_dir/ERD.png" alt="SYS Diagram">
</div>

### 3. UML Use Case

The use case diagram captures how different actors interact with the system and clarifies role-based access across the platform. Expats are the primary users, engaging with listings, community features, messaging, exploration tools, and arrival support. Agents and landlords focus on managing listings and communicating with expats, while administrators oversee verification and moderation. This diagram ensures functional boundaries are clearly defined and aligned with trust and transparency goals.

<div align="center">
  <img src="png_directory/sys_dir/Use Case.png" alt="SYS Diagram">
</div>

### 4. UML Class Diagram

The class diagram represents the core domain entities of ExpatHomes and their relationships. Central to the model is the `User` entity, which is extended through roles such as Expat, Agent, and Landlord. Supporting entities include Property Listings, Inquiries, Chat Sessions, Messages, and Community Posts. This diagram informed both the Firestore data structure and the UI component logic within the mobile application.

<div align="center">
  <img src="png_directory/sys_dir/Class.png" alt="SYS Diagram">
</div>

---

## Deployment Plan

At this stage, ExpatHomes focuses on design, prototyping, and system modelling rather than full production deployment.

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

🎥 **Video Demo:** *https://drive.google.com/drive/folders/1YhtUzBrgGVvE0uT6gy-Anae2fN02YtvV?usp=sharing*

The demo showcases:

- Project motivation and problem context
- Community feature and Bowl-based interaction
- Verified estate listings and inquiry flow
- Secure messaging with live translation
- Explore feature using location-based discovery
- Rides feature for arrival cost transparency
- Role-based access behaviour

---

## Current Project Phase

- ✅ Problem analysis and system requirements
- ✅ UX/UI design and interactive prototyping
- ✅ UML and system architecture modelling
- 🔄 Firebase-backed implementation (planned / in progress)
- 🔄 External API integrations

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
