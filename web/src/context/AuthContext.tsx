import { createContext, useContext, useEffect, useState, useMemo, type ReactNode } from 'react'
import type { Session, User } from '@supabase/supabase-js'
import { authService } from '../services/auth.service'
import { businessService, type UserBusinessOption } from '../services/business.service'
import type { GetMyBusinessAccessResult } from '../types/database.types'
import { computePermissions, type Permissions } from '../hooks/usePermissions'

interface AuthContextType {
  user: User | null
  session: Session | null
  currentBusiness: UserBusinessOption | null
  businessAccess: GetMyBusinessAccessResult | null
  userBusinesses: UserBusinessOption[]
  permissions: Permissions
  isLoading: boolean
  isBusinessLoading: boolean
  refreshBusinessAccess: () => Promise<void>
  logout: () => Promise<void>
}

const AuthContext = createContext<AuthContextType | undefined>(undefined)

export function AuthProvider({ children }: { children: ReactNode }) {
  const [session, setSession] = useState<Session | null>(null)
  const [user, setUser] = useState<User | null>(null)
  const [isLoading, setIsLoading] = useState(true)
  const [isBusinessLoading, setIsBusinessLoading] = useState(false)
  const [userBusinesses, setUserBusinesses] = useState<UserBusinessOption[]>([])
  const [currentBusiness, setCurrentBusiness] = useState<UserBusinessOption | null>(null)
  const [businessAccess, setBusinessAccess] = useState<GetMyBusinessAccessResult | null>(null)

  const permissions = useMemo(() => {
    return computePermissions(currentBusiness?.role || businessAccess?.role)
  }, [currentBusiness?.role, businessAccess?.role])

  const loadBusinessData = async (activeUser: User) => {
    setIsBusinessLoading(true)
    try {
      const businesses = await businessService.listUserBusinesses(activeUser.id)
      setUserBusinesses(businesses)
      const selected = businesses[0] ?? null

      setCurrentBusiness(selected)
      if (selected) {
        try {
          const access = await businessService.getMyBusinessAccess()
          setBusinessAccess(access)
        } catch {
          setBusinessAccess(null)
        }
      } else {
        setBusinessAccess(null)
      }
    } catch (err) {
      console.error('Error loading business access:', err)
    } finally {
      setIsBusinessLoading(false)
    }
  }

  useEffect(() => {
    let mounted = true

    authService.getSession().then((initialSession) => {
      if (!mounted) return
      setSession(initialSession)
      setUser(initialSession?.user ?? null)
      if (initialSession?.user) {
        loadBusinessData(initialSession.user)
      }
      setIsLoading(false)
    }).catch((err) => {
      console.error('Error fetching session:', err)
      if (mounted) setIsLoading(false)
    })

    const unsubscribe = authService.onAuthStateChange((newSession) => {
      if (!mounted) return
      setSession(newSession)
      setUser(newSession?.user ?? null)
      if (newSession?.user) {
        loadBusinessData(newSession.user)
      } else {
        setUserBusinesses([])
        setCurrentBusiness(null)
        setBusinessAccess(null)
      }
      setIsLoading(false)
    })

    return () => {
      mounted = false
      unsubscribe()
    }
  }, [])

  const refreshBusinessAccess = async () => {
    if (!user) return
    await loadBusinessData(user)
  }

  const logout = async () => {
    await authService.logout()
    setSession(null)
    setUser(null)
    setCurrentBusiness(null)
    setBusinessAccess(null)
    setUserBusinesses([])
  }

  return (
    <AuthContext.Provider
      value={{
        user,
        session,
        currentBusiness,
        businessAccess,
        userBusinesses,
        permissions,
        isLoading,
        isBusinessLoading,
        refreshBusinessAccess,
        logout,
      }}
    >
      {children}
    </AuthContext.Provider>
  )
}

// oxlint-disable-next-line react/only-export-components
export function useAuth(): AuthContextType {
  const context = useContext(AuthContext)
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider')
  }
  return context
}
