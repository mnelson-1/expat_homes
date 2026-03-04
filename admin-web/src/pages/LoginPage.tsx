import { useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'

import slide1 from '/images/1.jpg'
import slide2 from '/images/2.jpg'
import slide3 from '/images/3.jpg'
import slide4 from '/images/4.jpg'

const PLACEHOLDER_EMAIL = 'admin@expathomes.rw'
const PLACEHOLDER_PASSWORD = 'admin123'
const CAROUSEL_INTERVAL_MS = 7000

const SLIDES = [
  {
    image: slide1,
    title: '',
    subtitle: 'Escape your ordinary. Discover new luxury, where fine finishes for a new stylish lifestyle.',
  },
  {
    image: slide2,
    title: '',
    subtitle: 'Find your ideal space to daily commute to work, we provide you the most convenient and spacious for the office to commute and everywhere.',
  },
  {
    image: slide3,
    title: '',
    subtitle: "Don't just find a house, find your community. We offer you a new lifestyle and social connection.",
  },
  {
    image: slide4,
    title: '',
    subtitle: 'Come and find your true home, and we will offer you the most comfortable living experience for the office to commute and everywhere.',
  },
]

export function LoginPage() {
  const navigate = useNavigate()
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState('')
  const [currentSlide, setCurrentSlide] = useState(0)

  useEffect(() => {
    const id = window.setInterval(() => {
      setCurrentSlide((prev) => (prev + 1) % SLIDES.length)
    }, CAROUSEL_INTERVAL_MS)

    return () => {
      window.clearInterval(id)
    }
  }, [])

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    setError('')
    if (email.trim().toLowerCase() !== PLACEHOLDER_EMAIL || password !== PLACEHOLDER_PASSWORD) {
      setError('Invalid email or password.')
      return
    }
    navigate('/admin/listings/pending')
  }

  const activeSlide = SLIDES[currentSlide]

  return (
    <div className="login-page">
      <div className="login-card">
        <div className="login-carousel">
          <img
            src={activeSlide.image}
            alt=""
            className="login-carousel-image"
          />
          <div className="login-carousel-overlay">
            {activeSlide.title ? (
              <h2 className="login-carousel-title">{activeSlide.title}</h2>
            ) : null}
            <p className="login-carousel-subtitle">{activeSlide.subtitle}</p>
          </div>
          <div className="login-carousel-dots">
            {SLIDES.map((_, index) => (
              <button
                key={index}
                type="button"
                className={index === currentSlide ? 'login-carousel-dot active' : 'login-carousel-dot'}
                onClick={() => setCurrentSlide(index)}
                aria-label={`Go to slide ${index + 1}`}
              />
            ))}
          </div>
        </div>

        <div className="login-form-wrapper">
          <div className="login-form-inner">
            <h1 className="login-title">Administrator<br />Portal</h1>
            <p className="login-subtitle">
              Sign in to access your admin dashboard and manage your system securely.
            </p>
            <form onSubmit={handleSubmit} className="login-form">
              <label className="login-label">
                Email address
                <input
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  className="login-input"
                  placeholder="johndoe@gmail.com"
                  required
                />
              </label>
              <label className="login-label">
                Password
                <input
                  type="password"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  className="login-input"
                  placeholder="password"
                  required
                />
              </label>
              {error && (
                <p className="login-error" role="alert">
                  {error}
                </p>
              )}
              <button type="submit" className="login-submit">
                Sign in
              </button>
            </form>
            <p className="login-subtitle login-subtitle-bottom">
              Sign in to access your admin dashboard and manage your system securely.
            </p>
          </div>
        </div>
      </div>
    </div>
  )
}
