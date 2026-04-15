require "test_helper"

class Admin::CustomerCrmControllerTest < ActionDispatch::IntegrationTest
  setup do
    @tenant = Tenant.create!(
      name: "CRM Tenant",
      code: "crm-tenant",
      subdomain: "crm",
      plan: "standard",
      status: "active",
      billing_email: "owner@crm.example.com"
    )

    @owner = User.create!(
      tenant: @tenant,
      name: "CRM Owner",
      email: "owner@crm.example.com",
      password: "Password123!",
      password_confirmation: "Password123!",
      locale: "ja",
      time_zone: "Asia/Tokyo",
      is_owner: true
    )

    @customer = @tenant.customers.create!(
      code: "C500",
      name: "未来商事",
      status: "active",
      email: "sales@mirai.example.com",
      contact_person_department: "営業企画",
      contact_person_name: "中村未来",
      contact_person_email: "nakamura@mirai.example.com",
      contact_person_tel: "03-0000-5555",
      closing_day: 31,
      payment_method: "bank_transfer",
      payment_due_rule: "next_month_end",
      invoice_delivery_method: "email"
    )

    @inquiry = @tenant.customer_inquiries.create!(
      customer: @customer,
      inquiry_date: Date.new(2026, 4, 10),
      response_due_date: Date.new(2026, 4, 12),
      status: "responding",
      source: "phone",
      subject: "サイト刷新の相談",
      details: "営業サイトの見直しについて相談。",
      assigned_user: @owner
    )

    @prospect_inquiry = @tenant.customer_inquiries.create!(
      inquiry_date: Date.new(2026, 4, 11),
      response_due_date: Date.new(2026, 4, 13),
      status: "new",
      source: "web",
      company_name: "新星工業",
      contact_person_name: "高橋明",
      contact_email: "takahashi@shinsei.example.com",
      subject: "新規Web問い合わせ",
      details: "CRM導入についての相談。"
    )

    @opportunity = @tenant.customer_opportunities.create!(
      customer: @customer,
      customer_inquiry: @inquiry,
      opened_on: Date.new(2026, 4, 12),
      expected_close_on: Date.new(2026, 4, 28),
      stage: "proposal",
      subject: "CRM導入提案",
      expected_amount: 80000,
      probability: 70,
      summary: "ヒアリング完了。提案準備中。",
      next_action: "提案書を送付",
      assigned_user: @owner
    )

    @invoice = @tenant.invoices.create!(
      customer: @customer,
      closing_date: Date.new(2026, 4, 30),
      billing_period_from: Date.new(2026, 4, 1),
      billing_period_to: Date.new(2026, 4, 30),
      invoice_date: Date.new(2026, 4, 30),
      due_date: Date.new(2026, 5, 31),
      status: "partially_paid",
      subtotal_amount: 50000,
      tax_amount: 5000,
      total_amount: 55000,
      paid_amount: 20000,
      balance_amount: 35000
    )

    @payment = @tenant.payments.create!(
      customer: @customer,
      payment_date: Date.new(2026, 4, 20),
      amount: 20000,
      status: "partially_applied",
      payment_method: "bank_transfer"
    )

    Permissions::Catalog.seed_admin!
    sign_in @owner
  end

  test "customer inquiry screens render and inquiry can be created for a prospect" do
    get admin_customer_inquiries_path, params: { q: "刷新", status: "responding", source: "phone" }
    assert_response :success

    assert_select "h1", text: "問い合わせ一覧"
    assert_select "tbody", text: /サイト刷新の相談/
    assert_select "tbody", text: /新規Web問い合わせ/, count: 0

    assert_difference("CustomerInquiry.count", 1) do
      post admin_customer_inquiries_path, params: {
        customer_inquiry: {
          inquiry_date: "2026-04-15",
          response_due_date: "2026-04-18",
          status: "new",
          source: "web",
          company_name: "北風工業",
          contact_person_name: "高橋一郎",
          contact_email: "takahi@example.com",
          subject: "展示会の資料請求",
          details: "製品紹介と見積条件を相談したい。"
        }
      }
    end

    inquiry = CustomerInquiry.order(:id).last
    assert_redirected_to admin_customer_inquiry_path(inquiry)
    assert_nil inquiry.customer_id

    get admin_customer_inquiry_path(inquiry)
    assert_response :success
    assert_select "a", text: "得意先を作成"
  end

  test "customer opportunity can be created from inquiry and shown" do
    get new_admin_customer_opportunity_path(inquiry_id: @inquiry.id, customer_id: @customer.id)
    assert_response :success
    assert_select "select[name='customer_opportunity[customer_id]'] option[selected='selected'][value='#{@customer.id}']"
    assert_select "select[name='customer_opportunity[customer_inquiry_id]'] option[selected='selected'][value='#{@inquiry.id}']"

    assert_difference("CustomerOpportunity.count", 1) do
      post admin_customer_opportunities_path, params: {
        customer_opportunity: {
          customer_id: @customer.id,
          customer_inquiry_id: @inquiry.id,
          assigned_user_id: @owner.id,
          opened_on: "2026-04-16",
          expected_close_on: "2026-04-30",
          stage: "proposal",
          subject: "追加提案",
          expected_amount: 120000,
          probability: 80,
          summary: "追加機能を提案する商談。",
          next_action: "役員説明会を設定"
        }
      }
    end

    opportunity = CustomerOpportunity.order(:id).last
    assert_redirected_to admin_customer_opportunity_path(opportunity)

    get admin_customer_opportunities_path, params: { stage: "proposal", customer_id: @customer.id }
    assert_response :success
    assert_select "tbody", text: /追加提案/

    get admin_customer_opportunity_path(opportunity)
    assert_response :success
    assert_select "a", text: "見積を作成"
    assert_select "a", text: @inquiry.subject
  end

  test "customer sales and customer detail include crm summaries" do
    get admin_customer_sales_path, params: { from: "2026-04-01", to: "2026-04-30", q: @customer.code }
    assert_response :success

    assert_select "h1", text: "得意先別売上一覧"
    assert_select "td", text: "¥55,000"
    assert_select "td", text: "¥20,000"
    assert_select "td", text: "¥35,000"
    assert_select "td", text: "¥80,000"

    get admin_customer_path(@customer)
    assert_response :success
    assert_select "a", text: @inquiry.subject
    assert_select "a", text: @opportunity.subject
    assert_select "a", text: "新規問い合わせ"
    assert_select "a", text: "新規商談"
    assert_select "div", text: /商談見込/
  end
end
