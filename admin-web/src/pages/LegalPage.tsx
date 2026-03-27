import { Link } from 'react-router-dom'
import {
  EULA,
  LEGAL_DOCUMENTS_VERSION,
  NONDISCRIMINATION,
  PAYMENTS_TERMS,
  PRIVACY_POLICY,
} from '../legal/legalContent'

export type LegalVariant = 'privacy' | 'eula' | 'payments' | 'nondiscrimination'

const titles: Record<LegalVariant, string> = {
  privacy: 'Privacy Policy',
  eula: 'Terms of Service (EULA)',
  payments: 'Payments Terms of Service',
  nondiscrimination: 'Nondiscrimination Policy',
}

const bodies: Record<LegalVariant, string> = {
  privacy: PRIVACY_POLICY,
  eula: EULA,
  payments: PAYMENTS_TERMS,
  nondiscrimination: NONDISCRIMINATION,
}

export function LegalPage({ variant }: { variant: LegalVariant }) {
  return (
    <div style={{ minHeight: '100vh', background: '#fff', color: '#1a2e35' }}>
      <header
        style={{
          padding: '16px 24px',
          borderBottom: '1px solid #e0e0e0',
          background: '#1a2e35',
        }}
      >
        <Link to="/admin/login" style={{ color: '#8ed966', textDecoration: 'none' }}>
          ← Back to sign in
        </Link>
      </header>
      <article
        style={{
          maxWidth: 720,
          margin: '0 auto',
          padding: '24px 20px 48px',
        }}
      >
        <h1 style={{ fontSize: 22, marginBottom: 8 }}>{titles[variant]}</h1>
        <p style={{ fontSize: 12, color: '#666', marginBottom: 24 }}>
          Document version {LEGAL_DOCUMENTS_VERSION}
        </p>
        <pre
          style={{
            whiteSpace: 'pre-wrap',
            fontFamily: 'system-ui, -apple-system, sans-serif',
            fontSize: 14,
            lineHeight: 1.55,
            margin: 0,
          }}
        >
          {bodies[variant]}
        </pre>
      </article>
    </div>
  )
}
