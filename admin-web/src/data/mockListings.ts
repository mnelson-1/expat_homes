// Shared types and mock data for admin flows

export interface Listing {
  id: string
  title: string
  address: string
  landlord: string
  landlordPhone?: string
  submittedAt: string
  upi?: string
  description?: string
  images: string[]
  price?: string
  bedrooms?: number
  bathrooms?: number
}

// Pending verification (new listings)
export const MOCK_PENDING_LISTINGS: Listing[] = [
  {
    id: 'pv1',
    title: 'Charm Nest Apartments',
    address: 'Kiyovu, Kigali',
    landlord: 'Jean Claude',
    landlordPhone: '+250 788 123 456',
    submittedAt: '2025-02-20',
    upi: 'RWA-2025-KGL-001',
    description: 'Spacious modern apartment with city views.',
    images: ['/images/1.jpg', '/images/2.jpg', '/images/3.jpg'],
    price: '1,200,000 RWF/mo',
    bedrooms: 2,
    bathrooms: 2,
  },
  {
    id: 'pv2',
    title: 'Green View Villa',
    address: 'Nyarutarama, Kigali',
    landlord: 'Marie Uwera',
    landlordPhone: '+250 789 654 321',
    submittedAt: '2025-02-19',
    upi: 'RWA-2025-KGL-002',
    description: 'Quiet villa with garden and parking.',
    images: ['/images/2.jpg', '/images/4.jpg'],
    price: '2,500,000 RWF/mo',
    bedrooms: 4,
    bathrooms: 3,
  },
]

// Edit request: pending (request to edit not yet approved)
export interface EditRequestPending {
  id: string
  listingId: string
  listing: Listing
  requestedAt: string
  reason?: string
}

// Edit request: ready for review (landlord has submitted changes)
export interface EditRequestReview {
  id: string
  listingId: string
  previous: Listing
  updated: Listing
  submittedAt: string
}

export const MOCK_EDIT_PENDING: EditRequestPending[] = [
  {
    id: 'erp1',
    listingId: 'pv1',
    requestedAt: '2025-02-21',
    reason: 'Update price and add one more photo',
    listing: {
      id: 'pv1',
      title: 'Charm Nest Apartments',
      address: 'Kiyovu, Kigali',
      landlord: 'Jean Claude',
      submittedAt: '2025-02-20',
      upi: 'RWA-2025-KGL-001',
      description: 'Spacious modern apartment with city views.',
      images: ['/images/1.jpg', '/images/2.jpg', '/images/3.jpg'],
      price: '1,200,000 RWF/mo',
      bedrooms: 2,
      bathrooms: 2,
    },
  },
]

export const MOCK_EDIT_REVIEW: EditRequestReview[] = [
  {
    id: 'err1',
    listingId: 'legacy1',
    submittedAt: '2025-02-22',
    previous: {
      id: 'legacy1',
      title: 'Sunset Heights',
      address: 'Remera, Kigali',
      landlord: 'Patrick Niyonsenga',
      submittedAt: '2025-01-15',
      upi: 'RWA-2024-KGL-010',
      description: 'Family-friendly house with yard.',
      images: ['/images/3.jpg'],
      price: '1,800,000 RWF/mo',
      bedrooms: 3,
      bathrooms: 2,
    },
    updated: {
      id: 'legacy1',
      title: 'Sunset Heights',
      address: 'Remera, Kigali',
      landlord: 'Patrick Niyonsenga',
      submittedAt: '2025-02-22',
      upi: 'RWA-2024-KGL-010',
      description: 'Family-friendly house with yard and new fencing.',
      images: ['/images/3.jpg', '/images/4.jpg'],
      price: '1,950,000 RWF/mo',
      bedrooms: 3,
      bathrooms: 2,
    },
  },
]
