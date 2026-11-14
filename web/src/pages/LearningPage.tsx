import { Link, useParams } from 'react-router-dom'
import { BookOpen, ChevronLeft } from 'lucide-react'
import { Card } from '../components/ui/Card'
import { ErrorState } from '../components/ui/States'
import { learningModules } from '../data/learningModules'

export function LearningPage() {
  const { slug } = useParams()
  const module = learningModules.find((item) => item.slug === slug)

  if (slug && !module) {
    return (
      <div className="space-y-4">
        <ErrorState
          title="Materi tidak ditemukan"
          message="Materi yang Anda cari tidak tersedia."
        />
        <Link
          to="/belajar"
          className="inline-flex min-h-11 items-center rounded-md text-sm font-semibold text-[#1D4ED8] hover:text-[#1E3A8A] focus-visible:outline-2 focus-visible:outline-offset-4 focus-visible:outline-[#2563EB] active:text-[#1E3A8A]"
        >
          Kembali ke daftar Belajar
        </Link>
      </div>
    )
  }

  if (module) {
    return (
      <article className="mx-auto max-w-3xl">
        <Link
          to="/belajar"
          className="inline-flex min-h-11 items-center gap-1 rounded-md text-sm font-semibold text-[#1D4ED8] hover:text-[#1E3A8A] focus-visible:outline-2 focus-visible:outline-offset-4 focus-visible:outline-[#2563EB] active:text-[#1E3A8A]"
        >
          <ChevronLeft className="h-4 w-4" aria-hidden="true" />
          Kembali ke Belajar
        </Link>
        <header className="mt-5 border-b border-slate-200 pb-5">
          <p className="text-sm font-semibold text-[#1D4ED8]">{module.topic}</p>
          <h1 className="mt-2 text-2xl font-bold tracking-tight text-slate-900 sm:text-3xl">
            {module.title}
          </h1>
          <p className="mt-3 text-sm leading-6 text-slate-600 sm:text-base">
            {module.summary}
          </p>
        </header>

        <div className="mt-5 space-y-4">
          {module.sections.map((section) => (
            <section key={section.heading} className="rounded-lg border border-slate-200 bg-white p-5 sm:p-6">
              <h2 className="text-base font-bold text-slate-900">{section.heading}</h2>
              <p className="mt-2 text-sm leading-6 text-slate-700">{section.body}</p>
              <ul className="mt-4 space-y-2">
                {section.points.map((point) => (
                  <li key={point} className="flex items-start gap-2 text-sm leading-6 text-slate-700">
                    <span className="mt-2 h-1.5 w-1.5 shrink-0 rounded-full bg-[#2563EB]" aria-hidden="true" />
                    <span>{point}</span>
                  </li>
                ))}
              </ul>
            </section>
          ))}
        </div>
      </article>
    )
  }

  return (
    <div className="space-y-5">
      <header className="max-w-2xl">
        <div className="flex items-center gap-2 text-[#1D4ED8]">
          <BookOpen className="h-5 w-5" aria-hidden="true" />
          <p className="text-sm font-semibold">Panduan usaha sehari-hari</p>
        </div>
        <h1 className="mt-2 text-2xl font-bold tracking-tight text-slate-900">Belajar</h1>
        <p className="mt-1 text-sm leading-6 text-slate-600">
          Materi praktis untuk membantu mencatat, mengelola, dan memahami keuangan UMKM.
        </p>
      </header>

      {learningModules.length === 0 ? (
        <p className="rounded-lg border border-slate-200 bg-white p-5 text-sm text-slate-700">
          Materi belajar belum tersedia.
        </p>
      ) : (
        <div className="grid gap-3 md:grid-cols-2 xl:grid-cols-3">
          {learningModules.map((item) => (
            <Link
              key={item.slug}
              to={`/belajar/${item.slug}`}
              className="group min-h-48 rounded-lg focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[#2563EB]"
            >
              <Card className="flex h-full flex-col p-5 transition-colors group-hover:border-blue-300 group-hover:bg-blue-50/30 group-active:bg-blue-50">
                <p className="text-xs font-semibold text-[#1D4ED8]">{item.topic}</p>
                <h2 className="mt-3 text-base font-bold leading-6 text-slate-900">
                  {item.title}
                </h2>
                <p className="mt-2 flex-1 text-sm leading-6 text-slate-600">
                  {item.summary}
                </p>
                <span className="mt-4 inline-flex min-h-11 items-center text-sm font-semibold text-[#1D4ED8]">
                  Buka materi
                </span>
              </Card>
            </Link>
          ))}
        </div>
      )}
    </div>
  )
}
