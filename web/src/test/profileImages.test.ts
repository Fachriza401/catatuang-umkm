import { describe, expect, it } from 'vitest'
import {
  profileImageMaxBytes,
  profileImageValidationError,
} from '../services/profile.service'

describe('profile image validation', () => {
  it('accepts supported image formats within the size limit', () => {
    for (const [type, extension] of [
      ['image/jpeg', 'jpg'],
      ['image/png', 'png'],
      ['image/webp', 'webp'],
    ]) {
      const file = new File(['image'], `logo.${extension}`, { type })
      expect(profileImageValidationError(file)).toBeNull()
    }
  })

  it('rejects unsupported formats and files larger than 5 MB', () => {
    const unsupported = new File(['image'], 'logo.gif', { type: 'image/gif' })
    const oversized = new File(
      [new Uint8Array(profileImageMaxBytes + 1)],
      'logo.png',
      { type: 'image/png' },
    )

    expect(profileImageValidationError(unsupported)).toBe(
      'Pilih gambar berformat JPG, PNG, atau WebP.',
    )
    expect(profileImageValidationError(oversized)).toBe(
      'Ukuran gambar maksimal 5 MB.',
    )
  })
})
