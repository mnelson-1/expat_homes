/** Keep in sync with `expat_app/lib/legal/legal_version.dart` and `legal_documents.dart`. */
export const LEGAL_DOCUMENTS_VERSION = '2026-03-27-v1'

export const PRIVACY_POLICY = `
EXPAT HOMES — PRIVACY POLICY
Effective date: March 27, 2026 • Document version: ${LEGAL_DOCUMENTS_VERSION}

Who we are
ExpatHomes (“we”, “us”, “the platform”) connects expats, landlords, licensed agents, and administrators to discover housing, communicate, and coordinate property-related workflows in a trust-centered way. This policy explains what we collect, why we use it, how we protect it, and your choices.

1. DATA WE COLLECT

Account and profile
• Identity and contact: email address, display name, legal name where required for verification, date of birth where collected, country of citizenship (expats), preferred language, role (expat, landlord, agent, or admin), and optional profile details such as a short bio or phone when you provide them.
• Authentication: we use Firebase Authentication to manage sign-in credentials securely.

Property and marketplace data
• Listings you create or manage: descriptions, photos, pricing, location fields, verification status, and moderation history as needed for trust and safety.
• Assignments and coordination: which agent is linked to which listing, commission-related records you confirm in the app, and similar workflow metadata.

Messaging and communications
• Message content and attachment metadata stored in our database so conversations work reliably. Optional on-device translation may process message text on your device to show you content in your preferred language; we do not rely on third-party translation servers for that on-device path.

Technical data
• Device and app diagnostics typical of mobile apps (e.g. crash logs through platform tooling), and usage data needed to operate Firebase services.

Storage (Firebase)
• User profiles, listings, messages, and related metadata are stored in Google Cloud Firestore.
• Images and files you upload may be stored in Firebase Storage.
• Firebase security rules and role-based access restrict who can read or write what—see Security below.

2. HOW WE USE DATA

We use data to:
• Create and maintain your account and enforce role-appropriate features (e.g. agent workflows vs expat browsing).
• Show listings, process admin verification, and display accurate property information.
• Enable messaging, optional translation, and notifications essential to the service.
• Track commissions and confirmations you enter, so landlords and agents can align on completed steps (payments themselves occur outside the app, e.g. via mobile money, as you arrange).
• Improve trust: detect abuse, respond to reports, and support lawful requests where required.

We use data in line with this policy and only for legitimate platform purposes—not for selling personal message content to advertisers.

3. SHARING AND THIRD PARTIES

We do not sell your personal information.

Limited sharing and processors
• Google Firebase (Authentication, Firestore, Storage, and related infrastructure) processes data on our behalf under Google’s terms and security practices.
• Maps and places: when you use location or map features, Google Maps / Places may process location or query data under Google’s policies.
• Translation: where on-device ML translation is used, processing stays on your device for that feature path. If we introduce cloud translation in the future, we will update this policy.

We do not share message contents with unrelated third parties for marketing. We may disclose information if required by law or to protect users and the integrity of the platform.

4. SECURITY

• Access is enforced with Firebase security rules and role-based permissions (expat, landlord, agent, admin).
• We use industry-standard transport encryption for data in transit to Google services.
• No system is perfect. ExpatHomes is under active development; treat sensitive information thoughtfully and avoid sharing passwords or financial details in chat.

5. YOUR RIGHTS AND CHOICES

Depending on where you live, you may have rights to access, correct, export, or delete personal data we hold about you, subject to legal exceptions.

In the app you can update much of your profile directly. You may request account deletion or additional help by contacting support through channels we publish. We will verify your identity before acting on sensitive requests.

6. ETHICAL USE AND FAIRNESS

• Listing verification exists to reduce fraud and protect renters; it is not a guarantee that every listing is suitable for you—always exercise judgment.
• We expect fair dealing between landlords and agents. The platform provides coordination tools; it does not replace good faith negotiation or compliance with local housing and anti-discrimination laws.
• Messages should be respectful. Harassment, discrimination, or attempts to defraud others may lead to suspension or removal.

7. CHILDREN

ExpatHomes is not intended for children under the age required to enter a binding contract in your jurisdiction (typically 18). We do not knowingly collect data from children.

8. CHANGES

We may update this policy. We will post the new version in the app and note the effective date. Continued use after changes means you accept the updated policy where permitted by law.

9. CONTACT

For privacy questions about ExpatHomes, contact us through the support options provided in the app or on our official website.
`.trim()

export const EULA = `
EXPAT HOMES — TERMS OF SERVICE (EULA)
Effective date: March 27, 2026 • Document version: ${LEGAL_DOCUMENTS_VERSION}

Please read these terms carefully. By creating an account or using ExpatHomes, you agree to them.

1. THE SERVICE

ExpatHomes provides software to browse housing listings, communicate with other users, and coordinate certain workflows (including agent assignment and commission confirmations). The service may change as we improve the product.

2. ACCEPTABLE USE

You agree to:
• Provide accurate registration information and keep your account secure.
• Use the platform only for lawful housing-related purposes in good faith.
• Not post fraudulent listings, impersonate others, scrape data to harm users, or attempt to bypass security or quotas.
• Not use the service to discriminate unlawfully against protected classes where applicable law applies.

We may suspend or terminate accounts that violate these rules or put others at risk.

3. PLATFORM RESPONSIBILITIES AND LIMITS

• Verification: where we mark listings or users as verified, that reflects our internal checks—not a guarantee of habitability, legal compliance of the lease, or suitability for your situation.
• Outcomes: we do not guarantee that you will find housing, earn commissions, or complete any transaction.
• Payments: rent, deposits, and agent payments are arranged between you and other parties (e.g. via mobile money or bank transfer). ExpatHomes is not a bank or escrow service unless we explicitly say otherwise in a future feature. You are responsible for confirming amounts and recipients outside the app’s record-keeping features.

4. USER RESPONSIBILITY

You are responsible for your interactions, agreements, and decisions with other users. Read listings carefully, inspect properties when possible, and seek independent advice for legal or financial matters.

5. LIMITATION OF LIABILITY

To the maximum extent permitted by law, ExpatHomes and its operators are not liable for indirect, incidental, or consequential damages arising from use of the service, including disputes between users or issues with third-party payment providers.

The platform is provided “as is” during its development (MVP / prototype phases). We do not warrant uninterrupted or error-free operation.

6. ACCOUNTS AND ROLES

• Expats use the service to discover housing and message representatives.
• Landlords list properties and cooperate with verification.
• Agents act under their licensed credentials and institutional rules; misuse of agent features may affect your license relationship outside the app.
• Admins perform moderation and operational tasks under internal policies.

You must use features only for the role assigned to you.

7. INTELLECTUAL PROPERTY

The app, branding, and content we provide are owned by ExpatHomes or its licensors. You retain rights to content you upload; you grant us a license to host and display it to operate the service.

8. TERMINATION

You may stop using the service at any time. We may suspend or terminate access for breach of these terms or risk to the community.

9. GOVERNING LAW

These terms are intended for general use; mandatory consumer protections in your country may still apply.

10. CONTACT

Questions about these terms may be directed through in-app support or official contact channels.
`.trim()

export const PAYMENTS_TERMS = `
EXPAT HOMES — PAYMENTS TERMS OF SERVICE
Effective date: March 27, 2026 • Document version: ${LEGAL_DOCUMENTS_VERSION}

1. NO IN-APP PAYMENT PROCESSOR (CURRENT STATE)

Today, ExpatHomes does not process rent, deposits, or commissions inside the app as a payment institution. Users typically arrange transfers through external methods such as mobile money (e.g. MTN MoMo, Airtel Money) or banks, as they agree privately.

2. RECORDS IN THE APP

Features may let you record or confirm that a payment step was completed for coordination between landlords and agents. Those records are for your convenience and do not replace bank statements or official receipts.

3. YOUR RESPONSIBILITIES

• Verify payee details before sending money.
• Keep proof of payment outside the app.
• Understand fees charged by your mobile money or bank provider.

4. DISPUTES

Payment disputes are primarily between you and the other party (and your financial institution). ExpatHomes is not a party to your payment contract. We may assist with account-level issues (e.g. misuse of the platform) but cannot reverse third-party transfers.

5. FUTURE CHANGES

If we introduce integrated payments later, we will update these terms and obtain any required consents.
`.trim()

export const NONDISCRIMINATION = `
EXPAT HOMES — NONDISCRIMINATION POLICY
Effective date: March 27, 2026 • Document version: ${LEGAL_DOCUMENTS_VERSION}

1. OUR COMMITMENT

ExpatHomes is built around trust and respect. We expect listings, messages, and professional conduct to comply with applicable anti-discrimination and fair housing principles, including where Rwandan law and international norms protect equal treatment in housing and services.

2. PROHIBITED CONDUCT

Users must not use the platform to:
• Advertise or deny housing or services based on race, ethnicity, religion, national origin, disability, gender, family status, or other protected grounds where the law applies.
• Harass, threaten, or intimidate others.
• Imply unlawful preferences in listing text, photos, or chat.

3. AGENTS AND LANDLORDS

Agents and landlords must represent properties fairly and avoid steering or exclusionary practices. Commission discussions should remain professional and transparent.

4. REPORTING

If you see discriminatory content or behavior, report it through channels we provide. We may remove content, warn users, or suspend accounts to protect the community.

5. EDUCATION

We may share guidance to help users understand fair practices. This policy does not create private rights of action; it expresses our community standards and operational intent.
`.trim()
