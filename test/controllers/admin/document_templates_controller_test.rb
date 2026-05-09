require "test_helper"

class Admin::DocumentTemplatesControllerTest < ActionDispatch::IntegrationTest
  setup do
    Permissions::Catalog.seed_admin!

    @tenant = Tenant.create!(
      name: "テンプレートテナント",
      code: "tmpl-tenant",
      subdomain: "tmpl",
      plan: "standard",
      status: "active",
      billing_email: "owner@tmpl.example.com"
    )
    @owner = User.create!(
      tenant: @tenant,
      name: "オーナー",
      email: "owner@tmpl.example.com",
      password: "Password123!",
      password_confirmation: "Password123!",
      locale: "ja",
      time_zone: "Asia/Tokyo",
      is_owner: true
    )
    sign_in @owner
  end

  test "index lists all 7 document types" do
    get admin_document_templates_path
    assert_response :success
    assert_equal 7, DocumentTemplate.where(tenant: @tenant).count
  end

  test "edit renders the template form" do
    get edit_admin_document_template_path("invoice")
    assert_response :success
  end

  test "edit returns 404 for unknown document type" do
    get edit_admin_document_template_path("unknown_type")
    assert_response :not_found
  end

  test "update saves company header settings" do
    patch admin_document_template_path("invoice"), params: {
      document_template: {
        settings: {
          company_header_enabled: "1",
          company_name: "サンプル株式会社",
          company_postal_code: "100-0001",
          company_address: "東京都千代田区",
          company_tel: "03-0000-0000",
          company_email: "info@sample.example.com"
        }
      }
    }
    assert_redirected_to admin_document_templates_path

    template = DocumentTemplate.find_by(tenant: @tenant, document_type: "invoice")
    assert template.company_header_enabled?
    assert_equal "サンプル株式会社", template.company_name
    assert_equal "100-0001", template.company_postal_code
  end

  test "update saves row visibility settings" do
    patch admin_document_template_path("invoice"), params: {
      document_template: {
        settings: {
          company_header_enabled: "0",
          row_visibility: { "remarks" => "0", "customer_payment" => "1" }
        }
      }
    }
    assert_redirected_to admin_document_templates_path

    template = DocumentTemplate.find_by(tenant: @tenant, document_type: "invoice")
    assert_not template.row_visible?("remarks")
    assert template.row_visible?("customer_payment")
  end

  test "update saves custom column labels" do
    patch admin_document_template_path("invoice"), params: {
      document_template: {
        settings: {
          company_header_enabled: "0",
          item_column_labels: { "description" => "品名", "quantity" => "個数" }
        }
      }
    }
    assert_redirected_to admin_document_templates_path

    template = DocumentTemplate.find_by(tenant: @tenant, document_type: "invoice")
    assert_equal "品名", template.item_column_label("description", "内容")
    assert_equal "個数", template.item_column_label("quantity", "数量")
  end

  test "update saves column widths" do
    patch admin_document_template_path("invoice"), params: {
      document_template: {
        settings: {
          company_header_enabled: "0",
          column_widths: { "0" => "30", "1" => "12", "2" => "14", "3" => "14", "4" => "14", "5" => "18" }
        }
      }
    }
    assert_redirected_to admin_document_templates_path

    template = DocumentTemplate.find_by(tenant: @tenant, document_type: "invoice")
    assert_equal [ 30, 12, 14, 14, 14, 18 ], template.resolved_column_widths
  end
end
