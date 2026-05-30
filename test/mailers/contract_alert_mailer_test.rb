require "test_helper"

class ContractAlertMailerTest < ActionMailer::TestCase
  setup do
    @tenant = Tenant.create!(
      name: "契約アラートテナント",
      code: "contract-alert",
      subdomain: "contract-alert",
      plan: "standard",
      status: "active",
      billing_email: "billing@contract-alert.example.com"
    )

    @customer = @tenant.customers.create!(
      code: "CUST-CA-1",
      name: "テスト得意先",
      status: "active"
    )

    @recipient = User.create!(
      tenant: @tenant,
      name: "担当者",
      email: "manager@contract-alert.example.com",
      password: "Password123!",
      password_confirmation: "Password123!",
      is_owner: true
    )

    @contract1 = @tenant.contracts.create!(
      contract_number: "CNT-CA-001",
      title: "基本取引契約",
      counterparty_type: "customer",
      customer: @customer,
      status: "active",
      started_on: Date.current - 365,
      ended_on: Date.current + 10
    )

    @contract2 = @tenant.contracts.create!(
      contract_number: "CNT-CA-002",
      title: "保守契約",
      counterparty_type: "customer",
      customer: @customer,
      status: "active",
      started_on: Date.current - 100,
      ended_on: Date.current + 25
    )
  end

  test "expiry_digest: 件名に契約件数が含まれる" do
    contracts = [ @contract1, @contract2 ]
    mail = ContractAlertMailer.expiry_digest(tenant: @tenant, contracts: contracts, recipient: @recipient)

    assert_equal [ "manager@contract-alert.example.com" ], mail.to
    assert_match "2件", mail.subject
    assert_match "契約期限アラート", mail.subject
    assert_match "契約アラートテナント", mail.subject
  end

  test "expiry_digest: 本文に契約一覧が含まれる" do
    contracts = [ @contract1, @contract2 ]
    mail = ContractAlertMailer.expiry_digest(tenant: @tenant, contracts: contracts, recipient: @recipient)
    text_body = mail.parts.find { |p| p.content_type.include?("text/plain") }&.decoded

    assert_match "基本取引契約", text_body
    assert_match "保守契約", text_body
    assert_match "CNT-CA-001", text_body
    assert_match "テスト得意先", text_body
  end

  test "expiry_digest: HTML・テキスト両パートが存在する" do
    mail = ContractAlertMailer.expiry_digest(tenant: @tenant, contracts: [ @contract1 ], recipient: @recipient)

    assert mail.multipart?
    assert mail.parts.any? { |p| p.content_type.include?("text/plain") }
    assert mail.parts.any? { |p| p.content_type.include?("text/html") }
  end
end
