require "test_helper"

class FeatureFlagsTest < ActiveSupport::TestCase
  def tenant_with_industry(industry)
    stub = Object.new
    stub.define_singleton_method(:industry) { industry }
    stub
  end

  # ── always_on セクション ───────────────────────────────────────────────

  test "core セクションは全業種で有効" do
    Tenant::INDUSTRIES.each_key do |key|
      assert FeatureFlags.section_enabled?(:core, tenant: tenant_with_industry(key.to_s)),
             "core should be enabled for #{key}"
    end
  end

  test "system セクションは全業種で有効" do
    Tenant::INDUSTRIES.each_key do |key|
      assert FeatureFlags.section_enabled?(:system, tenant: tenant_with_industry(key.to_s)),
             "system should be enabled for #{key}"
    end
  end

  # ── 建設・工事業 ──────────────────────────────────────────────────────

  test "construction: site_management が有効" do
    assert FeatureFlags.section_enabled?(:site_management, tenant: tenant_with_industry("construction"))
  end

  test "construction: inventory が無効" do
    assert_not FeatureFlags.section_enabled?(:inventory, tenant: tenant_with_industry("construction"))
  end

  test "construction: sales が無効" do
    assert_not FeatureFlags.section_enabled?(:sales, tenant: tenant_with_industry("construction"))
  end

  # ── 物販・小売業 ──────────────────────────────────────────────────────

  test "retail: inventory が有効" do
    assert FeatureFlags.section_enabled?(:inventory, tenant: tenant_with_industry("retail"))
  end

  test "retail: site_management が無効" do
    assert_not FeatureFlags.section_enabled?(:site_management, tenant: tenant_with_industry("retail"))
  end

  # ── サービス業 ────────────────────────────────────────────────────────

  test "service: sales が有効" do
    assert FeatureFlags.section_enabled?(:sales, tenant: tenant_with_industry("service"))
  end

  test "service: inventory が無効" do
    assert_not FeatureFlags.section_enabled?(:inventory, tenant: tenant_with_industry("service"))
  end

  test "service: site_management が無効" do
    assert_not FeatureFlags.section_enabled?(:site_management, tenant: tenant_with_industry("service"))
  end

  # ── 汎用 / tenant nil ─────────────────────────────────────────────────

  test "general: 全セクションが有効" do
    FeatureFlags::INDUSTRY_SECTIONS["general"].each do |section|
      assert FeatureFlags.section_enabled?(section, tenant: tenant_with_industry("general")),
             "#{section} should be enabled for general"
    end
  end

  test "tenant が nil のとき general と同じ挙動" do
    FeatureFlags::INDUSTRY_SECTIONS["general"].each do |section|
      assert FeatureFlags.section_enabled?(section, tenant: nil),
             "#{section} should be enabled when tenant is nil"
    end
  end
end
