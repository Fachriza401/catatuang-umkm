export interface AppPreferences {
  timezone: string
  compactSidebar: boolean
}

const STORAGE_KEY = 'catatuang_web_preferences'

export const defaultPreferences: AppPreferences = {
  timezone: Intl.DateTimeFormat().resolvedOptions().timeZone || 'Asia/Jakarta',
  compactSidebar: false,
}

export function loadPreferences(): AppPreferences {
  try {
    const raw = localStorage.getItem(STORAGE_KEY)
    if (!raw) return defaultPreferences
    const parsed = JSON.parse(raw) as Partial<AppPreferences>
    return { ...defaultPreferences, ...parsed }
  } catch {
    return defaultPreferences
  }
}

export function savePreferences(preferences: AppPreferences): void {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(preferences))
  window.dispatchEvent(new Event('catatuang-preferences-updated'))
}

export function getTimezone(): string {
  return loadPreferences().timezone
}
