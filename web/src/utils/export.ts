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

export function exportReportPdf(payload: ExportPayload) {
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

  doc.save(`${payload.fileName}.pdf`)
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
