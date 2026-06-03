require "test_helper"

class Admin::CustomersDeleteTest < ActionDispatch::IntegrationTest
  setup do
    @tenant = Tenant.create!(
      name: "削除テストテナント",
      code: "delete-test",
      subdomain: "delete-test",
      plan: "standard",
      status: "active",
      billing_email: "billing@delete-test.example.com"
    )
    @owner = User.create!(
      tenant: @tenant,
      name: "オーナー",
      email: "owner@delete-test.example.com",
      password: "Password123!",
      password_confirmation: "Password123!",
      is_owner: true
    )
    @customer = @tenant.customers.create!(
      code: "CUST-DEL-1",
      name: "削除対象得意先",
      status: "active"
    )
    Permissions::Catalog.seed_admin!
    sign_in @owner
  end

  test "関連データなしの得意先は削除できる" do
    assert_difference -> { @tenant.customers.count }, -1 do
      delete admin_customer_path(@customer)
    end
    assert_redirected_to admin_customers_path
    assert_match "削除しました", flash[:notice]
  end

  test "削除後は得意先一覧にリダイレクトされる" do
    delete admin_customer_path(@customer)
    follow_redirect!
    assert_response :success
  end

  test "注文が存在する得意先は削除できない" do
    @tenant.orders.create!(
      customer: @customer,
      order_date: Date.current,
      status: "draft"
    )

    assert_no_difference -> { @tenant.customers.count } do
      delete admin_customer_path(@customer)
    end
    assert_redirected_to admin_customer_path(@customer)
    assert_match "注文", flash[:alert]
    assert_match "削除できません", flash[:alert]
  end

  test "請求書が存在する得意先は削除できない" do
    @tenant.invoices.create!(
      customer: @customer,
      closing_date: Date.current,
      billing_period_from: Date.current.beginning_of_month,
      billing_period_to: Date.current.end_of_month,
      invoice_date: Date.current,
      due_date: Date.current + 30,
      status: "issued",
      subtotal_amount: 10_000,
      tax_amount: 1_000,
      total_amount: 11_000,
      paid_amount: 0,
      balance_amount: 11_000
    )

    assert_no_difference -> { @tenant.customers.count } do
      delete admin_customer_path(@customer)
    end
    assert_redirected_to admin_customer_path(@customer)
    assert_match "請求", flash[:alert]
  end

  test "deletable? は関連データなしで true を返す" do
    assert @customer.deletable?
  end

  test "deletable? は注文ありで false を返す" do
    @tenant.orders.create!(customer: @customer, order_date: Date.current, status: "draft")
    assert_not @customer.reload.deletable?
  end

  test "deletion_blocked_reason は削除可能な場合 nil を返す" do
    assert_nil @customer.deletion_blocked_reason
  end

  test "deletion_blocked_reason は削除不可の場合に理由を返す" do
    @tenant.orders.create!(customer: @customer, order_date: Date.current, status: "draft")
    reason = @customer.reload.deletion_blocked_reason
    assert_not_nil reason
    assert_match "注文", reason
  end
end
