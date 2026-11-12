import type { ReactNode } from 'react'
import { AlertTriangle, Inbox, Loader2, RefreshCw } from 'lucide-react'
import { Button } from './Button'

export function LoadingState({ message = 'Memuat data...' }: { message?: string }) {
  return (
    <div className="flex min-h-40 flex-col items-center justify-center gap-3 rounded-2xl border border-slate-200 bg-white p-8 text-center">
      <Loader2 className="h-7 w-7 animate-spin text-[#2563EB]" />
      <p className="text-sm text-slate-500">{message}</p>
    </div>
  )
}

export function ErrorState({
  message,
  onRetry,
  title = 'Gagal memuat data',
}: {
  message: string
  onRetry?: () => void
  title?: string
}) {
  return (
    <div role="alert" className="flex flex-col gap-4 rounded-2xl border border-rose-200 bg-rose-50 p-5 sm:flex-row sm:items-center sm:justify-between">
      <div className="flex items-start gap-3">
        <AlertTriangle className="mt-0.5 h-5 w-5 shrink-0 text-rose-600" />
        <div>
          <p className="text-sm font-semibold text-rose-900">{title}</p>
          <p className="mt-1 text-xs text-rose-700">{message}</p>
        </div>
      </div>
      {onRetry && (
        <Button variant="secondary" size="sm" icon={<RefreshCw className="h-3.5 w-3.5" />} onClick={onRetry}>
          Coba lagi
        </Button>
      )}
    </div>
  )
}

export function EmptyState({
  title,
  description,
  action,
  icon,
}: {
  title: string
  description?: string
  action?: ReactNode
  icon?: ReactNode
}) {
  return (
    <div className="flex min-h-48 flex-col items-center justify-center gap-3 rounded-2xl border border-dashed border-slate-300 bg-slate-50/60 p-8 text-center">
      <div className="flex h-12 w-12 items-center justify-center rounded-2xl bg-white text-slate-400 shadow-sm">
        {icon || <Inbox className="h-6 w-6" />}
      </div>
      <div>
        <p className="text-sm font-semibold text-slate-800">{title}</p>
        {description && <p className="mt-1 max-w-md text-xs text-slate-500">{description}</p>}
      </div>
      {action}
    </div>
  )
}
