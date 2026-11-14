import { jsPDF } from 'jspdf'
import autoTable from 'jspdf-autotable'
import ExcelJS from 'exceljs'

export interface ExportPayload {
  title: string
  businessName: string
  periodLabel: string
  summaryLines: string[]
  headers: string[]
  rows: Array<Array<string | number>>
  fileName: string
}

export type ReportPaperFormat = 'a4' | 'thermal-58' | 'thermal-80'

function downloadBlob(blob: Blob, fileName: string) {
  const url = URL.createObjectURL(blob)
  const anchor = document.createElement('a')
  anchor.href = url
  anchor.download = fileName
  document.body.appendChild(anchor)
  anchor.click()
  anchor.remove()
  URL.revokeObjectURL(url)
}

export function exportReportPdf(
  payload: ExportPayload,
  paperFormat: ReportPaperFormat = 'a4',
) {
  const doc = createReportPdf(payload, paperFormat)
  const suffix = paperFormat === 'a4' ? '' : `-${paperFormat}`
  doc.save(`${payload.fileName}${suffix}.pdf`)
}

export function createReportPdf(
  payload: ExportPayload,
  paperFormat: ReportPaperFormat = 'a4',
) {
  if (paperFormat !== 'a4') return createReceiptPdf(payload, paperFormat)
  const doc = new jsPDF({ orientation: 'landscape', unit: 'pt', format: 'a4' })
  const pageWidth = doc.internal.pageSize.getWidth()

  doc.setFillColor(37, 99, 235)
  doc.rect(0, 0, pageWidth, 64, 'F')
  doc.setTextColor(255, 255, 255)
  doc.setFontSize(18)
  doc.setFont('helvetica', 'bold')
  doc.text('CatatUang', 40, 28)
  doc.setFontSize(10)
  doc.setFont('helvetica', 'normal')
  doc.text('Kelola Uang, Kembangkan Usaha.', 40, 46)
  doc.setFontSize(12)
  doc.setFont('helvetica', 'bold')
  doc.text(payload.title, pageWidth - 40, 30, { align: 'right' })
  doc.setFontSize(9)
  doc.setFont('helvetica', 'normal')
  doc.text(payload.businessName, pageWidth - 40, 46, { align: 'right' })

  doc.setTextColor(15, 23, 42)
  let cursorY = 88
  doc.setFontSize(10)
  doc.setFont('helvetica', 'bold')
  doc.text(`Periode: ${payload.periodLabel}`, 40, cursorY)
  cursorY += 18
  doc.setFont('helvetica', 'normal')
  for (const line of payload.summaryLines) {
    doc.text(line, 40, cursorY)
    cursorY += 14
  }

  autoTable(doc, {
    head: [payload.headers],
    body: payload.rows.map((row) => row.map((cell) => String(cell))),
    startY: cursorY + 10,
    margin: { left: 40, right: 40 },
    styles: { fontSize: 8, cellPadding: 5, textColor: [30, 41, 59] },
    headStyles: { fillColor: [37, 99, 235], textColor: 255, fontStyle: 'bold' },
    alternateRowStyles: { fillColor: [248, 250, 252] },
    didDrawPage: (data) => {
      const height = doc.internal.pageSize.getHeight()
      doc.setFontSize(8)
      doc.setTextColor(100, 116, 139)
      doc.text(
        `Dicetak ${new Date().toLocaleString('id-ID')} · Halaman ${data.pageNumber}`,
        40,
        height - 24,
      )
    },
  })

  return doc
}

function createReceiptPdf(
  payload: ExportPayload,
  paperFormat: Exclude<ReportPaperFormat, 'a4'>,
) {
  const width = paperFormat === 'thermal-58' ? 58 : 80
  const contentWidth = width - 10
  const measureDoc = new jsPDF({
    orientation: 'portrait',
    unit: 'mm',
    format: [width, 1000],
  })
  const entries: Array<{
    text: string
    size: number
    bold?: boolean
    align?: 'left' | 'center'
    gapBefore?: number
  }> = [
    { text: 'CatatUang', size: 12, bold: true, align: 'center' },
    { text: payload.title, size: 9, bold: true, align: 'center', gapBefore: 1 },
    { text: payload.businessName, size: 8, align: 'center', gapBefore: 1 },
    { text: `Periode: ${payload.periodLabel}`, size: 7, align: 'center', gapBefore: 1 },
    { text: '--------------------------------', size: 7, align: 'center', gapBefore: 2 },
    ...payload.summaryLines.map((text) => ({
      text,
      size: 7.5,
      gapBefore: 1,
    })),
    { text: '--------------------------------', size: 7, align: 'center', gapBefore: 2 },
    { text: `RINCIAN TRANSAKSI (${payload.rows.length})`, size: 8, bold: true, gapBefore: 2 },
  ]

  for (const row of payload.rows) {
    const date = String(row[0] ?? '')
    const description = String(row[1] || 'Transaksi')
    const category = String(row[2] ?? '')
    const type = String(row[3] ?? '')
    const amount = Number(row[5] ?? 0)
    const amountLabel = Number.isFinite(amount)
      ? `${amount < 0 ? '-' : '+'}${new Intl.NumberFormat('id-ID', {
          style: 'currency',
          currency: 'IDR',
          maximumFractionDigits: 0,
        }).format(Math.abs(amount))}`
      : String(row[5] ?? '')
    entries.push(
      { text: `${date}  ${type}`, size: 7, bold: true, gapBefore: 2 },
      { text: description, size: 8 },
      { text: `${category}  ${amountLabel}`, size: 7 },
      { text: '--------------------------------', size: 6, align: 'center', gapBefore: 1 },
    )
  }

  entries.push({
    text: `Dicetak ${new Date().toLocaleString('id-ID')}`,
    size: 6.5,
    align: 'center',
    gapBefore: 2,
  })

  let contentHeight = 8
  for (const entry of entries) {
    measureDoc.setFont('helvetica', entry.bold ? 'bold' : 'normal')
    measureDoc.setFontSize(entry.size)
    const lines = measureDoc.splitTextToSize(entry.text, contentWidth)
    contentHeight += (entry.gapBefore ?? 0) + lines.length * (entry.size * 0.42 + 0.5)
  }
  contentHeight += 5

  const doc = new jsPDF({
    orientation: 'portrait',
    unit: 'mm',
    format: [width, contentHeight],
  })
  let cursorY = 5
  for (const entry of entries) {
    doc.setFont('helvetica', entry.bold ? 'bold' : 'normal')
    doc.setFontSize(entry.size)
    doc.setTextColor(15, 23, 42)
    cursorY += entry.gapBefore ?? 0
    const lines = doc.splitTextToSize(entry.text, contentWidth)
    const x = entry.align === 'center' ? width / 2 : 5
    for (const line of lines) {
      doc.text(line, x, cursorY, { align: entry.align ?? 'left' })
      cursorY += entry.size * 0.42 + 0.5
    }
  }

  return doc
}

export async function exportReportExcel(payload: ExportPayload) {
  const workbook = new ExcelJS.Workbook()
  workbook.creator = 'CatatUang'
  workbook.created = new Date()
  const sheet = workbook.addWorksheet('Laporan', {
    views: [{ state: 'frozen', ySplit: payload.summaryLines.length + 5 }],
  })

  sheet.mergeCells(1, 1, 1, payload.headers.length)
  const titleCell = sheet.getCell(1, 1)
  titleCell.value = `CatatUang · ${payload.title}`
  titleCell.font = { size: 16, bold: true, color: { argb: 'FF2563EB' } }
  titleCell.alignment = { vertical: 'middle' }

  sheet.mergeCells(2, 1, 2, payload.headers.length)
  sheet.getCell(2, 1).value = payload.businessName
  sheet.getCell(2, 1).font = { size: 12, bold: true, color: { argb: 'FF123B70' } }

  sheet.mergeCells(3, 1, 3, payload.headers.length)
  sheet.getCell(3, 1).value = `Periode: ${payload.periodLabel}`

  payload.summaryLines.forEach((line, index) => {
    sheet.mergeCells(4 + index, 1, 4 + index, payload.headers.length)
    sheet.getCell(4 + index, 1).value = line
  })

  const headerRowIndex = 4 + payload.summaryLines.length + 1
  const headerRow = sheet.getRow(headerRowIndex)
  headerRow.values = payload.headers
  headerRow.font = { bold: true, color: { argb: 'FFFFFFFF' } }
  headerRow.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FF2563EB' } }
  headerRow.alignment = { vertical: 'middle' }

  payload.rows.forEach((row, rowIndex) => {
    const excelRow = sheet.getRow(headerRowIndex + 1 + rowIndex)
    excelRow.values = row
  })

  sheet.columns.forEach((column, index) => {
    const header = payload.headers[index] || ''
    column.width = Math.max(14, Math.min(40, header.length + 8))
  })

  const buffer = await workbook.xlsx.writeBuffer()
  downloadBlob(
    new Blob([buffer as BlobPart], {
      type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    }),
    `${payload.fileName}.xlsx`,
  )
}
