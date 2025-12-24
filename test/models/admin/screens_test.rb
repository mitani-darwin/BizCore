require "test_helper"

class Admin::ScreensTest < ActiveSupport::TestCase
  test "screen actions map to permission keys in catalog" do
    keys = Permissions::Catalog.admin_keys
    missing = []

    Admin::Screens::SCREEN_DEFS.keys.each do |controller|
      screen = Admin::Screens.screen_for(controller)
      screen.actions.each_value do |action|
        next if action.permission_key.nil?
        missing << action.permission_key unless keys.include?(action.permission_key)
      end
    end

    assert missing.empty?, "Missing screen permission keys: #{missing.uniq.sort.join(', ')}"
  end
end
