import { describe, expect, it } from 'vitest'
import { createReportPdf, type ExportPayload } from '../utils/export'

const payload: ExportPayload = {
  title: 'Laporan Keuangan',
  businessName: 'Warung Contoh',
  periodLabel: '1 Jan 2026 - 31 Jan 2026',
  summaryLines: [
    'Total pemasukan: Rp 100.000 (2 transaksi)',
    'Total pengeluaran: Rp 40.000 (1 transaksi)',
    'Arus kas bersih: Rp 60.000',
  ],
  headers: ['Tanggal', 'Deskripsi', 'Kategori', 'Jenis', 'Metode', 'Nominal', 'Catatan'],
  rows: [
    ['1 Jan 2026', 'Penjualan harian', 'Penjualan', 'Pemasukan', 'Tunai', 100000, ''],
    ['2 Jan 2026', 'Belanja bahan baku', 'Bahan baku', 'Pengeluaran', 'Tunai', -40000, ''],
  ],
  fileName: 'laporan',
}

describe('report PDF paper formats', () => {
  it('creates receipt PDFs at the selected thermal paper width', () => {
    const receipt58 = createReportPdf(payload, 'thermal-58')
    const receipt80 = createReportPdf(payload, 'thermal-80')

    expect(receipt58.internal.pageSize.getWidth()).toBeCloseTo(58)
    expect(receipt80.internal.pageSize.getWidth()).toBeCloseTo(80)
    expect(receipt58.internal.pageSize.getHeight()).toBeGreaterThan(58)
    expect(receipt80.output('arraybuffer').byteLength).toBeGreaterThan(0)
  })

  it('keeps A4 exports on an A4 landscape page', () => {
    const a4 = createReportPdf(payload, 'a4')

    expect(a4.internal.pageSize.getWidth()).toBeGreaterThan(800)
    expect(a4.internal.pageSize.getHeight()).toBeGreaterThan(500)
  })
})
