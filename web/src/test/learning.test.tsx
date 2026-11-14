import { fireEvent, render, screen } from '@testing-library/react'
import { MemoryRouter, Route, Routes } from 'react-router-dom'
import { learningModules } from '../data/learningModules'
import { LearningPage } from '../pages/LearningPage'

function renderLearningPage(path = '/belajar') {
  return render(
    <MemoryRouter initialEntries={[path]}>
      <Routes>
        <Route path="/belajar" element={<LearningPage />} />
        <Route path="/belajar/:slug" element={<LearningPage />} />
      </Routes>
    </MemoryRouter>,
  )
}

describe('LearningPage', () => {
  it('opens each guide and returns to the module list', () => {
    renderLearningPage()

    for (const module of learningModules) {
      fireEvent.click(screen.getByRole('link', { name: new RegExp(module.title) }))
      expect(screen.getByRole('heading', { level: 1, name: module.title })).toBeInTheDocument()
      expect(screen.getByRole('heading', { level: 2, name: module.sections[0].heading })).toBeInTheDocument()
      fireEvent.click(screen.getByRole('link', { name: 'Kembali ke Belajar' }))
      expect(screen.getByRole('heading', { level: 1, name: 'Belajar' })).toBeInTheDocument()
    }
  })

  it('shows an explicit state for an unknown guide', () => {
    renderLearningPage('/belajar/materi-tidak-ada')

    expect(screen.getByRole('alert')).toHaveTextContent('Materi yang Anda cari tidak tersedia.')
    fireEvent.click(screen.getByRole('link', { name: 'Kembali ke daftar Belajar' }))
    expect(screen.getByRole('heading', { level: 1, name: 'Belajar' })).toBeInTheDocument()
  })
})
