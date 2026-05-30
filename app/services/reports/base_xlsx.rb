require "builder"
require "zip"

module Reports
  # Excel 帳票サービスの基底クラス。各帳票サービスはこのクラスを継承して #call を実装する。
  class BaseXlsx
    MIME_TYPE = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet".freeze
    DEFAULT_COLUMN_WIDTHS = [ 18, 28, 12, 14, 14, 16 ].freeze

    def self.call(**kwargs)
      new(**kwargs).call
    end

    attr_reader :template

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

    def document_title
      raise NotImplementedError
    end

    def document_number
      raise NotImplementedError
    end

    def document_timestamp
      raise NotImplementedError
    end

    def build_rows
      raise NotImplementedError
    end

    def column_widths
      return DEFAULT_COLUMN_WIDTHS unless template
      template.resolved_column_widths.presence || DEFAULT_COLUMN_WIDTHS
    end

    def worksheet_name
      sanitize_sheet_name(document_title)
    end

    def row_visible?(key)
      return true unless template
      template.row_visible?(key)
    end

    def item_col_label(key, default_label)
      return default_label unless template
      template.item_column_label(key, default_label)
    end

    def company_header_rows
      return [] unless template&.company_header_enabled?

      rows = []
      rows << full_width_value_row("会社名", template.company_name, columns: column_widths.size) if template.company_name.present?
      rows << full_width_value_row("郵便番号・住所", [ template.company_postal_code, template.company_address ].select(&:present?).join(" "), columns: column_widths.size) if template.company_postal_code.present? || template.company_address.present?
      rows << full_width_value_row("電話番号", template.company_tel, columns: column_widths.size) if template.company_tel.present?
      rows << full_width_value_row("メール", template.company_email, columns: column_widths.size) if template.company_email.present?
      rows << blank_row unless rows.empty?
      rows
    end

    def title_row(value = document_title)
      [ string_cell(value, style: 1) ]
    end

    def blank_row
      []
    end

    def section_row(label, columns: column_widths.size)
      [ header_cell(label) ] + blank_cells(columns - 1)
    end

    def label_value_row(*values)
      values.each_slice(2).flat_map do |label, value|
        [ header_cell(label), body_cell(value) ]
      end
    end

    def full_width_value_row(label, value, columns: column_widths.size)
      [ header_cell(label), body_cell(value) ] + blank_cells(columns - 2)
    end

    def total_row(label, amount, leading_blank_columns:, trailing_blank_columns: 0)
      blank_cells(leading_blank_columns) + [ total_label_cell(label), total_value_cell(amount) ] + blank_cells(trailing_blank_columns)
    end

    def blank_cells(count, style: 3)
      Array.new([ count, 0 ].max) { string_cell("", style: style) }
    end

    def string_cell(value, style: 3)
      { value: value, type: :string, style: style }
    end

    def number_cell(value, style: 4)
      { value: value, type: :number, style: style }
    end

    def header_cell(value)
      string_cell(value, style: 2)
    end

    def body_cell(value)
      string_cell(value, style: 3)
    end

    def total_label_cell(value)
      string_cell(value, style: 5)
    end

    def total_value_cell(value)
      number_cell(value, style: 6)
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

    def sanitize_sheet_name(value, default: document_title)
      name = value.to_s.gsub(/[\\\/\?\*\[\]:]/, "_").strip
      name = default if name.blank?
      name.first(31)
    end

    def jp_date(value)
      value.present? ? value.strftime("%Y/%m/%d") : "-"
    end

    def tax_category_label(value)
      {
        "taxable_10" => "課税 10%",
        "taxable_8" => "軽減税率 8%",
        "non_taxable" => "非課税"
      }.fetch(value.to_s, fallback_label(value))
    end

    def payment_method_label(value)
      {
        "bank_transfer" => "銀行振込",
        "direct_debit" => "口座振替",
        "cash" => "現金",
        "other" => "その他"
      }.fetch(value.to_s, fallback_label(value))
    end

    def invoice_delivery_method_label(value)
      {
        "email" => "メール",
        "postal" => "郵送",
        "hand" => "手渡し"
      }.fetch(value.to_s, fallback_label(value))
    end

    def payment_due_rule_label(value)
      {
        "end_of_month" => "当月末",
        "next_month_end" => "翌月末",
        "next_two_month_end" => "翌々月末",
        "custom" => "個別設定"
      }.fetch(value.to_s, fallback_label(value))
    end

    def order_status_label(value)
      {
        "draft" => "下書き",
        "sent" => "送信済",
        "accepted" => "受注済",
        "allocated" => "在庫確保済",
        "delivered" => "納品済",
        "billed" => "請求済",
        "cancelled" => "取消"
      }.fetch(value.to_s, fallback_label(value))
    end

    def order_item_status_label(value)
      {
        "pending" => "未処理",
        "allocated" => "在庫確保済",
        "delivered" => "納品済",
        "billed" => "請求済",
        "cancelled" => "取消"
      }.fetch(value.to_s, fallback_label(value))
    end

    def delivery_status_label(value)
      {
        "issued" => "発行済",
        "billed" => "請求済",
        "cancelled" => "取消"
      }.fetch(value.to_s, fallback_label(value))
    end

    def invoice_status_label(value)
      {
        "issued" => "未入金",
        "partially_paid" => "一部入金",
        "paid" => "入金済",
        "cancelled" => "取消"
      }.fetch(value.to_s, fallback_label(value))
    end

    def purchase_order_status_label(value)
      {
        "draft" => "下書き",
        "sent" => "発注済",
        "partially_received" => "一部入荷",
        "received" => "入荷完了",
        "cancelled" => "取消"
      }.fetch(value.to_s, fallback_label(value))
    end

    def purchase_order_item_status_label(value)
      {
        "pending" => "未入荷",
        "partially_received" => "一部入荷",
        "received" => "入荷済",
        "cancelled" => "取消"
      }.fetch(value.to_s, fallback_label(value))
    end

    def purchase_receipt_status_label(value)
      {
        "issued" => "入荷済",
        "cancelled" => "取消"
      }.fetch(value.to_s, fallback_label(value))
    end

    def purchase_adjustment_type_label(value)
      {
        "purchase_return" => "返品",
        "discount" => "値引き"
      }.fetch(value.to_s, fallback_label(value))
    end

    def purchase_bill_status_label(value)
      {
        "issued" => "未払",
        "partially_paid" => "一部支払",
        "paid" => "支払済",
        "credit" => "差引超過",
        "cancelled" => "取消"
      }.fetch(value.to_s, fallback_label(value))
    end

    def fallback_label(value)
      value.to_s.presence || "-"
    end

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
      timestamp = (document_timestamp || Time.current).utc.iso8601

      build_xml do |xml|
        xml.tag!(
          "cp:coreProperties",
          "xmlns:cp" => "http://schemas.openxmlformats.org/package/2006/metadata/core-properties",
          "xmlns:dc" => "http://purl.org/dc/elements/1.1/",
          "xmlns:dcterms" => "http://purl.org/dc/terms/",
          "xmlns:dcmitype" => "http://purl.org/dc/dcmitype/",
          "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance"
        ) do
          xml.tag!("dc:title", document_number)
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
            column_widths.each_with_index do |width, index|
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
  end
end
