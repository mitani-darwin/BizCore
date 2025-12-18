require "test_helper"

class Admin::NavigationTest < ActiveSupport::TestCase
  class DummyContext
    def initialize(allowed_keys)
      @allowed_keys = allowed_keys
    end

    def can?(key)
      @allowed_keys.include?(key)
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
    assert_not_includes section_ids, :core
  end
end
