require "test_helper"

class DocumentTemplateTest < ActiveSupport::TestCase
  setup do
    @tenant = Tenant.create!(
      name: "テスト会社",
      code: "dt-test",
      subdomain: "dt-test",
      plan: "standard",
      status: "active",
      billing_email: "owner@dt-test.example.com"
    )
  end

  test "for_tenant_and_type creates default template when none exists" do
    assert_difference "DocumentTemplate.count", 1 do
      template = DocumentTemplate.for_tenant_and_type(@tenant, "invoice")
      assert_equal "invoice", template.document_type
      assert_equal @tenant, template.tenant
    end
  end

  test "for_tenant_and_type returns existing template on second call" do
    DocumentTemplate.for_tenant_and_type(@tenant, "invoice")
    assert_no_difference "DocumentTemplate.count" do
      DocumentTemplate.for_tenant_and_type(@tenant, "invoice")
    end
  end

  test "default settings have all rows visible" do
    template = DocumentTemplate.for_tenant_and_type(@tenant, "invoice")
    assert template.row_visible?("customer_payment")
    assert template.row_visible?("remarks")
  end

  test "row_visible? returns false when set to false" do
    template = DocumentTemplate.for_tenant_and_type(@tenant, "invoice")
    settings = template.settings.merge("row_visibility" => { "remarks" => false })
    template.update!(settings: settings)

    assert_not template.row_visible?("remarks")
    assert template.row_visible?("customer_payment")
  end

  test "item_column_label returns custom label when set" do
    template = DocumentTemplate.for_tenant_and_type(@tenant, "invoice")
    settings = template.settings.merge("item_column_labels" => { "description" => "品名" })
    template.update!(settings: settings)

    assert_equal "品名", template.item_column_label("description", "内容")
    assert_equal "数量", template.item_column_label("quantity", "数量")
  end

  test "item_column_label returns default when custom label is blank" do
    template = DocumentTemplate.for_tenant_and_type(@tenant, "invoice")
    assert_equal "内容", template.item_column_label("description", "内容")
  end

  test "resolved_column_widths returns stored widths when valid" do
    template = DocumentTemplate.for_tenant_and_type(@tenant, "invoice")
    custom_widths = [ 30, 12, 14, 14, 14, 18 ]
    settings = template.settings.merge("column_widths" => custom_widths)
    template.update!(settings: settings)

    assert_equal custom_widths, template.resolved_column_widths
  end

  test "resolved_column_widths falls back to defaults when size mismatch" do
    template = DocumentTemplate.for_tenant_and_type(@tenant, "invoice")
    settings = template.settings.merge("column_widths" => [ 30, 12 ])
    template.update!(settings: settings)

    assert_equal DocumentTemplate::DEFINITIONS["invoice"][:column_widths], template.resolved_column_widths
  end

  test "company_header_enabled? returns false by default" do
    template = DocumentTemplate.for_tenant_and_type(@tenant, "invoice")
    assert_not template.company_header_enabled?
  end

  test "company_header_enabled? returns true when set" do
    template = DocumentTemplate.for_tenant_and_type(@tenant, "invoice")
    settings = template.settings.merge("company_header_enabled" => true, "company_name" => "テスト株式会社")
    template.update!(settings: settings)

    assert template.company_header_enabled?
    assert_equal "テスト株式会社", template.company_name
  end

  test "definition returns correct definition for each document type" do
    DocumentTemplate::DOCUMENT_TYPES.each do |doc_type|
      template = DocumentTemplate.for_tenant_and_type(@tenant, doc_type)
      assert template.definition.present?, "#{doc_type} の定義が空です"
      assert template.definition[:title].present?, "#{doc_type} のタイトルが空です"
      assert template.definition[:column_widths].present?, "#{doc_type} の列幅が空です"
    end
  end

  test "validates document_type inclusion" do
    template = DocumentTemplate.new(tenant: @tenant, document_type: "invalid_type")
    assert_not template.valid?
    assert_includes template.errors[:document_type], "は一覧にありません"
  end

  test "validates uniqueness of document_type per tenant" do
    DocumentTemplate.for_tenant_and_type(@tenant, "invoice")
    duplicate = DocumentTemplate.new(tenant: @tenant, document_type: "invoice", settings: {})
    assert_not duplicate.valid?
  end
end
