export function isDeveloperEmail(email: string | null | undefined): boolean {
  if (!email) return false
  const configured = (import.meta.env.VITE_DEVELOPER_EMAILS || '')
    .split(',')
    .map((value: string) => value.trim().toLowerCase())
    .filter(Boolean)
  return configured.includes(email.toLowerCase())
}
