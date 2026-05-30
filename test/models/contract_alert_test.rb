require "test_helper"

class ContractAlertTest < ActiveSupport::TestCase
  setup do
    @tenant = Tenant.create!(
      name: "契約モデルテナント",
      code: "contract-model",
      subdomain: "contract-model",
      plan: "standard",
      status: "active",
      billing_email: "billing@contract-model.example.com"
    )
    @customer = @tenant.customers.create!(
      code: "CUST-CM-1",
      name: "テスト得意先",
      status: "active"
    )
  end

  def create_contract(ended_on:, status: "active")
    @tenant.contracts.create!(
      contract_number: "CNT-#{SecureRandom.hex(4)}",
      title: "テスト契約",
      counterparty_type: "customer",
      customer: @customer,
      status: status,
      started_on: Date.current - 365,
      ended_on: ended_on
    )
  end

  # ── スコープのテスト ──────────────────────────────────────────────

  test "already_expired スコープ: active かつ ended_on < 今日の契約を返す" do
    expired = create_contract(ended_on: Date.current - 1)
    active  = create_contract(ended_on: Date.current + 30)
    expired_status = create_contract(ended_on: Date.current - 10, status: "expired")

    ids = @tenant.contracts.already_expired.pluck(:id)
    assert_includes     ids, expired.id,        "期限切れ active 契約が含まれるべき"
    assert_not_includes ids, active.id,         "有効な契約は含まれないべき"
    assert_not_includes ids, expired_status.id, "既に expired ステータスは含まれないべき"
  end

  test "expiring_within スコープ: 指定日数以内の期限を返す" do
    soon  = create_contract(ended_on: Date.current + 10)
    later = create_contract(ended_on: Date.current + 60)

    ids = @tenant.contracts.expiring_within(30).pluck(:id)
    assert_includes     ids, soon.id
    assert_not_includes ids, later.id
  end

  # ── auto_expire! のテスト ────────────────────────────────────────

  test "auto_expire!: active で期限切れの契約を expired に更新する" do
    contract = create_contract(ended_on: Date.current - 1)
    assert contract.status_active?

    contract.auto_expire!
    assert contract.reload.status_expired?
  end

  test "auto_expire!: 期限切れでない契約は変更しない" do
    contract = create_contract(ended_on: Date.current + 30)
    contract.auto_expire!
    assert contract.reload.status_active?
  end

  test "auto_expire!: 既に expired の契約は変更しない" do
    contract = create_contract(ended_on: Date.current - 10, status: "expired")
    contract.auto_expire!
    assert contract.reload.status_expired?
  end

  # ── alert_threshold_reached? のテスト ───────────────────────────

  test "alert_threshold_reached?: 30日以内は true" do
    contract = create_contract(ended_on: Date.current + 25)
    assert contract.alert_threshold_reached?
  end

  test "alert_threshold_reached?: 31日以上先は false" do
    contract = create_contract(ended_on: Date.current + 35)
    assert_not contract.alert_threshold_reached?
  end

  test "alert_threshold_reached?: 満了日なしは false" do
    contract = @tenant.contracts.create!(
      contract_number: "CNT-#{SecureRandom.hex(4)}",
      title: "無期限契約",
      counterparty_type: "customer",
      customer: @customer,
      status: "active",
      started_on: Date.current
    )
    assert_not contract.alert_threshold_reached?
  end
end
