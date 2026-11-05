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
  selectBusiness: (business: UserBusinessOption) => void
  refreshBusinessAccess: () => Promise<void>
  logout: () => Promise<void>
}

const AuthContext = createContext<AuthContextType | undefined>(undefined)

const SELECTED_BUSINESS_KEY = 'catatuang_selected_business_id'

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

      const savedBusinessId = localStorage.getItem(SELECTED_BUSINESS_KEY)
      let selected: UserBusinessOption | null = null

      if (savedBusinessId) {
        selected = businesses.find((b) => b.business_id === savedBusinessId) || null
      }

      if (!selected && businesses.length > 0) {
        selected = businesses[0]
      }

      setCurrentBusiness(selected)
      if (selected) {
        localStorage.setItem(SELECTED_BUSINESS_KEY, selected.business_id)
        try {
          const access = await businessService.getMyBusinessAccess()
          setBusinessAccess(access)
        } catch {
          // If RPC fails (e.g. mock or network), fallback to selected role
          setBusinessAccess(null)
        }
      } else {
        localStorage.removeItem(SELECTED_BUSINESS_KEY)
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
        localStorage.removeItem(SELECTED_BUSINESS_KEY)
      }
      setIsLoading(false)
    })

    return () => {
      mounted = false
      unsubscribe()
    }
  }, [])

  const selectBusiness = (business: UserBusinessOption) => {
    setCurrentBusiness(business)
    localStorage.setItem(SELECTED_BUSINESS_KEY, business.business_id)
    businessService.getMyBusinessAccess()
      .then((access) => setBusinessAccess(access))
      .catch((err) => console.error('Failed refreshing access:', err))
  }

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
    localStorage.removeItem(SELECTED_BUSINESS_KEY)
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
        selectBusiness,
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
