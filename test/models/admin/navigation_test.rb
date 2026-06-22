require "test_helper"

class Admin::NavigationTest < ActiveSupport::TestCase
  class DummyContext
    def initialize(allowed_keys, industry: nil)
      @allowed_keys  = allowed_keys
      @industry      = industry
    end

    def can?(key)
      @allowed_keys.include?(key)
    end

    def current_tenant
      return nil if @industry.nil?

      stub = Object.new
      industry = @industry
      stub.define_singleton_method(:industry) { industry }
      stub
    end
  end

  test "visible_sections includes items with allowed keys" do
    context = DummyContext.new(%w[admin.tenants.read])
    sections = Admin::Navigation.visible_sections(context)
    item_ids = sections.flat_map(&:items).map(&:id)

    assert_includes item_ids, :tenants
  end

  test "visible_sections excludes items without allowed keys" do
    context = DummyContext.new(%w[admin.tenants.read])
    sections = Admin::Navigation.visible_sections(context)
    item_ids = sections.flat_map(&:items).map(&:id)

    assert_not_includes item_ids, :audit_logs
  end

  test "parent section is hidden when all children are hidden" do
    context = DummyContext.new([])
    sections = Admin::Navigation.visible_sections(context)
    section_ids = sections.map(&:id)

    assert_not_includes section_ids, :audit
    assert_not_includes section_ids, :access
    assert_not_includes section_ids, :core
  end

  # ── 業種フィルター ────────────────────────────────────────────────────

  test "construction 業種では site_management セクションが表示される" do
    all_keys = Admin::Navigation.sections.flat_map(&:items).map { |i| i.required_keys }.flatten
    context  = DummyContext.new(all_keys, industry: "construction")
    section_ids = Admin::Navigation.visible_sections(context).map(&:id)

    assert_includes     section_ids, :site_management
    assert_not_includes section_ids, :inventory
    assert_not_includes section_ids, :sales
  end

  test "retail 業種では inventory セクションが表示され site_management は非表示" do
    all_keys = Admin::Navigation.sections.flat_map(&:items).map { |i| i.required_keys }.flatten
    context  = DummyContext.new(all_keys, industry: "retail")
    section_ids = Admin::Navigation.visible_sections(context).map(&:id)

    assert_includes     section_ids, :inventory
    assert_not_includes section_ids, :site_management
  end

  test "service 業種では inventory・site_management・procurement が非表示" do
    all_keys = Admin::Navigation.sections.flat_map(&:items).map { |i| i.required_keys }.flatten
    context  = DummyContext.new(all_keys, industry: "service")
    section_ids = Admin::Navigation.visible_sections(context).map(&:id)

    assert_not_includes section_ids, :inventory
    assert_not_includes section_ids, :site_management
    assert_not_includes section_ids, :procurement
  end

  test "tenant が nil のとき全セクションが対象になる" do
    all_keys = Admin::Navigation.sections.flat_map(&:items).map { |i| i.required_keys }.flatten
    context  = DummyContext.new(all_keys, industry: nil)
    section_ids = Admin::Navigation.visible_sections(context).map(&:id)

    assert_includes section_ids, :inventory
    assert_includes section_ids, :site_management
  end
end
