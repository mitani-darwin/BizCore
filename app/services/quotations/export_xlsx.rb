require "builder"
require "zip"

module Quotations
  class ExportXlsx
    STATUS_LABELS = {
      "draft" => "下書き",
      "sent" => "提示済",
      "accepted" => "採用",
      "converted" => "注文変換済",
      "cancelled" => "取消"
    }.freeze
    COLUMN_WIDTHS = [18, 28, 12, 14, 14, 16].freeze

    def self.call(quotation:)
      new(quotation:).call
    end

    def initialize(quotation:)
      @quotation = quotation
    end

    def call
      buffer = Zip::OutputStream.write_buffer do |zip|
        write_entry(zip, "[Content_Types].xml", content_types_xml)
        write_entry(zip, "_rels/.rels", root_rels_xml)
        write_entry(zip, "docProps/app.xml", app_xml)
        write_entry(zip, "docProps/core.xml", core_xml)
        write_entry(zip, "xl/workbook.xml", workbook_xml)
        write_entry(zip, "xl/_rels/workbook.xml.rels", workbook_rels_xml)
        write_entry(zip, "xl/styles.xml", styles_xml)
        write_entry(zip, "xl/worksheets/sheet1.xml", worksheet_xml)
      end

      buffer.string
    end

    private

    attr_reader :quotation

    def write_entry(zip, path, content)
      zip.put_next_entry(path)
      zip.write(content)
    end

    def content_types_xml
      build_xml do |xml|
        xml.Types("xmlns" => "http://schemas.openxmlformats.org/package/2006/content-types") do
          xml.Default("Extension" => "rels", "ContentType" => "application/vnd.openxmlformats-package.relationships+xml")
          xml.Default("Extension" => "xml", "ContentType" => "application/xml")
          xml.Override("PartName" => "/xl/workbook.xml", "ContentType" => "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml")
          xml.Override("PartName" => "/xl/worksheets/sheet1.xml", "ContentType" => "application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml")
          xml.Override("PartName" => "/xl/styles.xml", "ContentType" => "application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml")
          xml.Override("PartName" => "/docProps/core.xml", "ContentType" => "application/vnd.openxmlformats-package.core-properties+xml")
          xml.Override("PartName" => "/docProps/app.xml", "ContentType" => "application/vnd.openxmlformats-officedocument.extended-properties+xml")
        end
      end
    end

    def root_rels_xml
      build_xml do |xml|
        xml.Relationships("xmlns" => "http://schemas.openxmlformats.org/package/2006/relationships") do
          xml.Relationship("Id" => "rId1", "Type" => "http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument", "Target" => "xl/workbook.xml")
          xml.Relationship("Id" => "rId2", "Type" => "http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties", "Target" => "docProps/core.xml")
          xml.Relationship("Id" => "rId3", "Type" => "http://schemas.openxmlformats.org/officeDocument/2006/relationships/extended-properties", "Target" => "docProps/app.xml")
        end
      end
    end

    def app_xml
      build_xml do |xml|
        xml.Properties(
          "xmlns" => "http://schemas.openxmlformats.org/officeDocument/2006/extended-properties",
          "xmlns:vt" => "http://schemas.openxmlformats.org/officeDocument/2006/docPropsVTypes"
        ) do
          xml.Application("BizCore")
          xml.HeadingPairs do
            xml.tag!("vt:vector", "size" => "2", "baseType" => "variant") do
              xml.tag!("vt:variant") { xml.tag!("vt:lpstr", "Worksheets") }
              xml.tag!("vt:variant") { xml.tag!("vt:i4", "1") }
            end
          end
          xml.TitlesOfParts do
            xml.tag!("vt:vector", "size" => "1", "baseType" => "lpstr") do
              xml.tag!("vt:lpstr", worksheet_name)
            end
          end
        end
      end
    end

    def core_xml
      timestamp = (quotation.updated_at || quotation.created_at || Time.current).utc.iso8601

      build_xml do |xml|
        xml.tag!(
          "cp:coreProperties",
          "xmlns:cp" => "http://schemas.openxmlformats.org/package/2006/metadata/core-properties",
          "xmlns:dc" => "http://purl.org/dc/elements/1.1/",
          "xmlns:dcterms" => "http://purl.org/dc/terms/",
          "xmlns:dcmitype" => "http://purl.org/dc/dcmitype/",
          "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance"
        ) do
          xml.tag!("dc:title", quotation.quotation_number)
          xml.tag!("dc:creator", "BizCore")
          xml.tag!("cp:lastModifiedBy", "BizCore")
          xml.tag!("dcterms:created", timestamp, "xsi:type" => "dcterms:W3CDTF")
          xml.tag!("dcterms:modified", timestamp, "xsi:type" => "dcterms:W3CDTF")
        end
      end
    end

    def workbook_xml
      build_xml do |xml|
        xml.workbook(
          "xmlns" => "http://schemas.openxmlformats.org/spreadsheetml/2006/main",
          "xmlns:r" => "http://schemas.openxmlformats.org/officeDocument/2006/relationships"
        ) do
          xml.bookViews do
            xml.workbookView("xWindow" => "0", "yWindow" => "0", "windowWidth" => "24000", "windowHeight" => "14000")
          end
          xml.sheets do
            xml.sheet("name" => worksheet_name, "sheetId" => "1", "r:id" => "rId1")
          end
        end
      end
    end

    def workbook_rels_xml
      build_xml do |xml|
        xml.Relationships("xmlns" => "http://schemas.openxmlformats.org/package/2006/relationships") do
          xml.Relationship("Id" => "rId1", "Type" => "http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet", "Target" => "worksheets/sheet1.xml")
          xml.Relationship("Id" => "rId2", "Type" => "http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles", "Target" => "styles.xml")
        end
      end
    end

    def styles_xml
      build_xml do |xml|
        xml.styleSheet("xmlns" => "http://schemas.openxmlformats.org/spreadsheetml/2006/main") do
          xml.fonts("count" => "3") do
            xml.font { xml.sz("val" => "10"); xml.name("val" => "Yu Gothic UI") }
            xml.font { xml.b; xml.sz("val" => "16"); xml.name("val" => "Yu Gothic UI") }
            xml.font { xml.b; xml.sz("val" => "10"); xml.name("val" => "Yu Gothic UI") }
          end

          xml.fills("count" => "4") do
            xml.fill { xml.patternFill("patternType" => "none") }
            xml.fill { xml.patternFill("patternType" => "gray125") }
            xml.fill { xml.patternFill("patternType" => "solid") { xml.fgColor("rgb" => "FFF8FAFC"); xml.bgColor("indexed" => "64") } }
            xml.fill { xml.patternFill("patternType" => "solid") { xml.fgColor("rgb" => "FFE0F2FE"); xml.bgColor("indexed" => "64") } }
          end

          xml.borders("count" => "2") do
            xml.border { xml.left; xml.right; xml.top; xml.bottom; xml.diagonal }
            xml.border do
              %w[left right top bottom].each { |edge| xml.tag!(edge, "style" => "thin") }
              xml.diagonal
            end
          end

          xml.cellStyleXfs("count" => "1") do
            xml.xf("numFmtId" => "0", "fontId" => "0", "fillId" => "0", "borderId" => "0")
          end

          xml.cellXfs("count" => "7") do
            xml.xf("numFmtId" => "0", "fontId" => "0", "fillId" => "0", "borderId" => "0", "xfId" => "0")
            xml.xf("numFmtId" => "0", "fontId" => "1", "fillId" => "0", "borderId" => "0", "xfId" => "0", "applyFont" => "1")
            xml.xf("numFmtId" => "0", "fontId" => "2", "fillId" => "2", "borderId" => "1", "xfId" => "0", "applyFont" => "1", "applyFill" => "1", "applyBorder" => "1")
            xml.xf("numFmtId" => "0", "fontId" => "0", "fillId" => "0", "borderId" => "1", "xfId" => "0", "applyBorder" => "1")
            xml.xf("numFmtId" => "3", "fontId" => "0", "fillId" => "0", "borderId" => "1", "xfId" => "0", "applyBorder" => "1", "applyNumberFormat" => "1")
            xml.xf("numFmtId" => "0", "fontId" => "2", "fillId" => "3", "borderId" => "1", "xfId" => "0", "applyFont" => "1", "applyFill" => "1", "applyBorder" => "1")
            xml.xf("numFmtId" => "3", "fontId" => "2", "fillId" => "3", "borderId" => "1", "xfId" => "0", "applyFont" => "1", "applyFill" => "1", "applyBorder" => "1", "applyNumberFormat" => "1")
          end

          xml.cellStyles("count" => "1") do
            xml.cellStyle("name" => "Normal", "xfId" => "0", "builtinId" => "0")
          end
        end
      end
    end

    def worksheet_xml
      build_xml do |xml|
        xml.worksheet("xmlns" => "http://schemas.openxmlformats.org/spreadsheetml/2006/main") do
          xml.sheetViews do
            xml.sheetView("workbookViewId" => "0")
          end

          xml.cols do
            COLUMN_WIDTHS.each_with_index do |width, index|
              xml.col("min" => index + 1, "max" => index + 1, "width" => width, "customWidth" => "1")
            end
          end

          xml.sheetData do
            build_rows.each_with_index do |cells, row_number|
              xml.row("r" => row_number + 1) do
                cells.each_with_index do |cell, column_index|
                  build_cell(xml, row_number + 1, column_index + 1, cell)
                end
              end
            end
          end

          xml.pageMargins("left" => "0.3", "right" => "0.3", "top" => "0.5", "bottom" => "0.5", "header" => "0.3", "footer" => "0.3")
        end
      end
    end

    def build_rows
      rows = []
      rows << [{ value: "見積書", type: :string, style: 1 }]
      rows << []
      rows << label_value_row("見積番号", quotation.quotation_number, "状態", status_label, "見積日", jp_date(quotation.quotation_date))
      rows << label_value_row("得意先", quotation.customer.name, "有効期限", jp_date(quotation.expiration_date), "社内担当者", quotation.quoted_by_name.presence || "-")
      rows << [{ value: "件名", type: :string, style: 2 }, { value: quotation.subject.presence || "-", type: :string, style: 3 }]
      rows << label_value_row("得意先担当者", quotation.customer.primary_contact.presence || "-", "メール", quotation.customer.contact_person_email.presence || quotation.customer.email.presence || "-", "電話", quotation.customer.contact_person_tel.presence || quotation.customer.tel.presence || "-")
      rows << [{ value: "備考", type: :string, style: 2 }, { value: quotation.remarks.presence || "-", type: :string, style: 3 }]
      rows << []
      rows << [{ value: "見積明細", type: :string, style: 2 }]
      rows << [
        { value: "商品コード", type: :string, style: 2 },
        { value: "商品名", type: :string, style: 2 },
        { value: "数量", type: :string, style: 2 },
        { value: "単価", type: :string, style: 2 },
        { value: "税額", type: :string, style: 2 },
        { value: "金額", type: :string, style: 2 }
      ]

      quotation.quotation_items.order(:line_no).each do |item|
        rows << [
          { value: item.product_code_snapshot, type: :string, style: 3 },
          { value: item.product_name_snapshot, type: :string, style: 3 },
          { value: item.quantity, type: :number, style: 4 },
          { value: item.unit_price.to_i, type: :number, style: 4 },
          { value: item.tax_amount.to_i, type: :number, style: 4 },
          { value: item.amount.to_i, type: :number, style: 4 }
        ]
      end

      rows << total_row("小計", quotation.subtotal_amount.to_i)
      rows << total_row("税額", quotation.tax_amount.to_i)
      rows << total_row("合計", quotation.total_amount.to_i)
      rows
    end

    def label_value_row(*values)
      values.each_slice(2).flat_map do |label, value|
        [
          { value: label, type: :string, style: 2 },
          { value: value, type: :string, style: 3 }
        ]
      end
    end

    def total_row(label, amount)
      [
        { value: "", type: :string, style: 3 },
        { value: label, type: :string, style: 5 },
        { value: amount, type: :number, style: 6 }
      ]
    end

    def build_cell(xml, row_number, column_number, cell)
      reference = "#{column_name(column_number)}#{row_number}"
      attrs = { "r" => reference, "s" => cell.fetch(:style, 0) }

      if cell[:type] == :number
        xml.c(attrs) { xml.v(cell[:value].to_s) }
      else
        xml.c(attrs.merge("t" => "inlineStr")) do
          xml.is { xml.t(cell[:value].to_s, "xml:space" => "preserve") }
        end
      end
    end

    def column_name(index)
      name = +""
      current = index

      while current.positive?
        current -= 1
        name.prepend((65 + (current % 26)).chr)
        current /= 26
      end

      name
    end

    def build_xml
      xml = ::Builder::XmlMarkup.new(indent: 2)
      xml.instruct!(:xml, version: "1.0", encoding: "UTF-8")
      yield(xml)
      xml.target!
    end

    def worksheet_name
      base = quotation.customer.name.to_s.gsub(/[\\\/\?\*\[\]:]/, "_")
      base = "見積書" if base.blank?
      base.first(31)
    end

    def status_label
      STATUS_LABELS.fetch(quotation.status, quotation.status.to_s)
    end

    def jp_date(value)
      value.present? ? value.strftime("%Y/%m/%d") : "-"
    end
  end
end
