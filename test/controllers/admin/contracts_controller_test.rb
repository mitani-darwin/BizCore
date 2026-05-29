require "test_helper"

class Admin::ContractsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @tenant = Tenant.create!(
      name: "Contract Tenant",
      code: "contract-test",
      subdomain: "contract-test",
      plan: "standard",
      status: "active",
      billing_email: "owner@contract-test.example.com"
    )

    @owner = User.create!(
      tenant: @tenant,
      name: "Contract Owner",
      email: "owner@contract-test.example.com",
      password: "Password123!",
      password_confirmation: "Password123!",
      locale: "ja",
      time_zone: "Asia/Tokyo",
      is_owner: true
    )

    @customer = @tenant.customers.create!(
      code: "CUST-001",
      name: "テスト得意先",
      status: "active"
    )

    @supplier = @tenant.suppliers.create!(
      code: "SUPP-001",
      name: "テスト仕入先",
      status: "active"
    )

    @contract = @tenant.contracts.create!(
      contract_number: "CT-2026-001",
      title: "業務委託契約",
      counterparty_type: "customer",
      customer: @customer,
      status: "active",
      started_on: Date.new(2026, 1, 1),
      ended_on: Date.new(2026, 12, 31)
    )

    Permissions::Catalog.seed_admin!
    sign_in @owner
  end

  test "index が成功する" do
    get admin_contracts_path
    assert_response :success
    assert_select "h1", text: "契約一覧"
    assert_select "td", text: /業務委託契約/
  end

  test "show が成功する" do
    get admin_contract_path(@contract)
    assert_response :success
    assert_select "h1", text: "業務委託契約"
  end

  test "他テナントの契約は 404 になる" do
    other_tenant = Tenant.create!(
      name: "他テナント",
      code: "other-ct",
      subdomain: "other-ct",
      plan: "standard",
      status: "active",
      billing_email: "owner@other-ct.example.com"
    )
    other_customer = other_tenant.customers.create!(code: "C-001", name: "他テナント得意先", status: "active")
    other_contract = other_tenant.contracts.create!(
      contract_number: "CT-001",
      title: "他テナント契約",
      counterparty_type: "customer",
      customer: other_customer,
      status: "active",
      started_on: Date.current
    )

    get admin_contract_path(other_contract)
    assert_response :not_found
  end

  test "new が成功する" do
    get new_admin_contract_path
    assert_response :success
    assert_select "h1", text: "契約新規作成"
  end

  test "有効なパラメータで得意先契約を作成できる" do
    assert_difference("Contract.count", 1) do
      post admin_contracts_path, params: {
        contract: {
          contract_number: "CT-2026-002",
          title:           "保守契約",
          counterparty_type: "customer",
          customer_id:     @customer.id,
          status:          "active",
          started_on:      "2026-04-01"
        }
      }
    end

    contract = Contract.order(:id).last
    assert_redirected_to admin_contract_path(contract)
    assert_equal "保守契約", contract.title
    assert_equal @tenant.id, contract.tenant_id
    assert_equal @customer.id, contract.customer_id
  end

  test "有効なパラメータで仕入先契約を作成できる" do
    assert_difference("Contract.count", 1) do
      post admin_contracts_path, params: {
        contract: {
          contract_number: "CT-2026-003",
          title:           "仕入れ基本契約",
          counterparty_type: "supplier",
          supplier_id:     @supplier.id,
          status:          "draft",
          started_on:      "2026-04-01"
        }
      }
    end

    contract = Contract.order(:id).last
    assert_equal @supplier.id, contract.supplier_id
    assert_nil contract.customer_id
  end

  test "counterparty_type=customer で customer_id がなければ作成失敗" do
    assert_no_difference("Contract.count") do
      post admin_contracts_path, params: {
        contract: {
          contract_number: "CT-ERR",
          title:           "エラー契約",
          counterparty_type: "customer",
          customer_id:     "",
          status:          "active",
          started_on:      "2026-04-01"
        }
      }
    end
    assert_response :unprocessable_entity
  end

  test "update で契約を更新できる" do
    patch admin_contract_path(@contract), params: {
      contract: {
        contract_number: "CT-2026-001",
        title:           "更新後業務委託契約",
        counterparty_type: "customer",
        customer_id:     @customer.id,
        status:          "active",
        started_on:      "2026-01-01"
      }
    }
    assert_redirected_to admin_contract_path(@contract)
    assert_equal "更新後業務委託契約", @contract.reload.title
  end
end
