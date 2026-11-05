import { describe, it, expect, vi, beforeEach } from 'vitest'
import { authService } from '../services/auth.service'
import { supabase } from '../lib/supabase'

vi.mock('../lib/supabase', () => ({
  supabase: {
    auth: {
      signInWithPassword: vi.fn(),
      signUp: vi.fn(),
      signOut: vi.fn(),
      getSession: vi.fn(),
      getUser: vi.fn(),
      onAuthStateChange: vi.fn(() => ({
        data: { subscription: { unsubscribe: vi.fn() } },
      })),
    },
    rpc: vi.fn(),
  },
}))

describe('authService', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('melakukan login dengan kredensial yang valid', async () => {
    const mockUser = { id: 'user-123', email: 'owner@warung.com' }
    const mockSession = { user: mockUser, access_token: 'fake-jwt' }

    vi.mocked(supabase.auth.signInWithPassword).mockResolvedValueOnce({
      data: { user: mockUser as any, session: mockSession as any },
      error: null,
    })

    const result = await authService.login({
      email: 'owner@warung.com',
      password: 'Password123!',
    })

    expect(supabase.auth.signInWithPassword).toHaveBeenCalledWith({
      email: 'owner@warung.com',
      password: 'Password123!',
    })
    expect(result.user?.id).toBe('user-123')
  })

  it('melempar error jika login gagal (invalid credentials)', async () => {
    vi.mocked(supabase.auth.signInWithPassword).mockResolvedValueOnce({
      data: { user: null, session: null },
      error: new Error('Invalid login credentials') as any,
    })

    await expect(
      authService.login({
        email: 'wrong@warung.com',
        password: 'wrongpassword',
      })
    ).rejects.toThrow('Invalid login credentials')
  })

  it('melakukan logout akun dan membersihkan sesi', async () => {
    vi.mocked(supabase.auth.signOut).mockResolvedValueOnce({
      error: null,
    })

    await authService.logout()
    expect(supabase.auth.signOut).toHaveBeenCalled()
  })
})

