require "test_helper"

class SiteTest < ActiveSupport::TestCase
  setup do
    @tenant = Tenant.create!(
      name: "現場テナント",
      code: "site-test",
      subdomain: "site-test",
      plan: "standard",
      status: "active",
      billing_email: "owner@site-test.example.com"
    )
  end

  # バリデーション: 名前の必須チェック
  test "name は必須" do
    site = @tenant.sites.build(code: "S-001", category: "construction", status: "active")
    assert_not site.valid?
    assert_includes site.errors[:name], "を入力してください"
  end

  # バリデーション: コードの必須チェック
  test "code は必須" do
    site = @tenant.sites.build(name: "テスト現場", category: "construction", status: "active")
    assert_not site.valid?
    assert_includes site.errors[:code], "を入力してください"
  end

  # バリデーション: テナント内のコード一意性
  test "同じテナント内で code は一意" do
    @tenant.sites.create!(name: "現場A", code: "S-001", category: "construction", status: "active")
    duplicate = @tenant.sites.build(name: "現場B", code: "S-001", category: "construction", status: "active")
    assert_not duplicate.valid?
    assert duplicate.errors[:code].any?
  end

  # 別テナントでは同じコードが使える
  test "別テナントでは同じ code が使える" do
    @tenant.sites.create!(name: "現場A", code: "S-001", category: "construction", status: "active")
    other_tenant = Tenant.create!(
      name: "他テナント",
      code: "other-site",
      subdomain: "other-site",
      plan: "standard",
      status: "active",
      billing_email: "owner@other-site.example.com"
    )
    other_site = other_tenant.sites.build(name: "現場B", code: "S-001", category: "construction", status: "active")
    assert other_site.valid?
  end

  # バリデーション: progress_percentage の範囲
  test "progress_percentage は 0〜100 の範囲内" do
    site = @tenant.sites.build(name: "テスト", code: "S-001", category: "construction", status: "active", progress_percentage: 50)
    assert site.valid?

    site.progress_percentage = -1
    assert_not site.valid?

    site.progress_percentage = 101
    assert_not site.valid?

    site.progress_percentage = 0
    assert site.valid?

    site.progress_percentage = 100
    assert site.valid?
  end

  # status enum の動作
  test "status enum が正しく動作する" do
    site = @tenant.sites.create!(name: "テスト現場", code: "S-002", category: "construction", status: "planning")
    assert site.planning?
    assert_not site.active?

    site.update!(status: "active")
    assert site.active?

    site.update!(status: "completed")
    assert site.completed?
  end

  # category_label が正しいラベルを返す
  test "category_label がカテゴリの日本語ラベルを返す" do
    site = @tenant.sites.build(name: "テスト", code: "S-003", category: "construction", status: "active")
    assert_equal "建設工事", site.category_label

    site.category = "maintenance"
    assert_equal "保守・メンテナンス", site.category_label
  end

  # status_label が正しいラベルを返す
  test "status_label がステータスの日本語ラベルを返す" do
    site = @tenant.sites.build(name: "テスト", code: "S-004", category: "construction", status: "active")
    assert_equal "施工中", site.status_label

    site.status = "completed"
    assert_equal "完了", site.status_label
  end
end
