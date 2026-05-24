require "test_helper"

class Admin::SitesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @tenant = Tenant.create!(
      name: "Sites Tenant",
      code: "sites-test",
      subdomain: "sites-test",
      plan: "standard",
      status: "active",
      billing_email: "owner@sites-test.example.com"
    )

    @owner = User.create!(
      tenant: @tenant,
      name: "Sites Owner",
      email: "owner@sites-test.example.com",
      password: "Password123!",
      password_confirmation: "Password123!",
      locale: "ja",
      time_zone: "Asia/Tokyo",
      is_owner: true
    )

    @site = @tenant.sites.create!(
      name: "テスト現場",
      code: "SITE-001",
      category: "construction",
      status: "active",
      progress_percentage: 30,
      address: "東京都渋谷区"
    )

    Permissions::Catalog.seed_admin!
    sign_in @owner
  end

  # index のテスト
  test "index が成功する" do
    get admin_sites_path
    assert_response :success
    assert_select "h1", text: "現場一覧"
    assert_select "td", text: /テスト現場/
  end

  test "index はキーワードでフィルタできる" do
    @tenant.sites.create!(name: "別の現場", code: "SITE-002", category: "maintenance", status: "active")

    get admin_sites_path, params: { q: "テスト" }
    assert_response :success
    assert_select "tbody tr", count: 1
    assert_select "td", text: /テスト現場/
  end

  test "index はステータスでフィルタできる" do
    @tenant.sites.create!(name: "計画中現場", code: "SITE-003", category: "construction", status: "planning")

    get admin_sites_path, params: { status: "planning" }
    assert_response :success
    assert_select "tbody tr", count: 1
    assert_select "td", text: /計画中現場/
  end

  # show のテスト
  test "show が成功する" do
    get admin_site_path(@site)
    assert_response :success
    assert_select "h1", text: "テスト現場"
  end

  test "他テナントの現場は 404 になる" do
    other_tenant = Tenant.create!(
      name: "他テナント",
      code: "other-sites",
      subdomain: "other-sites",
      plan: "standard",
      status: "active",
      billing_email: "owner@other-sites.example.com"
    )
    other_site = other_tenant.sites.create!(name: "他の現場", code: "S-001", category: "construction", status: "active")

    get admin_site_path(other_site)
    assert_response :not_found
  end

  # new のテスト
  test "new が成功する" do
    get new_admin_site_path
    assert_response :success
    assert_select "h1", text: "現場新規作成"
  end

  # create のテスト
  test "有効なパラメータで現場を作成できる" do
    assert_difference("Site.count", 1) do
      post admin_sites_path, params: {
        site: {
          name: "新規現場",
          code: "SITE-NEW",
          category: "construction",
          status: "planning",
          progress_percentage: 0,
          address: "東京都千代田区"
        }
      }
    end

    site = Site.order(:id).last
    assert_redirected_to admin_site_path(site)
    assert_equal "新規現場", site.name
    assert_equal @tenant.id, site.tenant_id
  end

  test "無効なパラメータでは現場を作成できない" do
    assert_no_difference("Site.count") do
      post admin_sites_path, params: {
        site: { name: "", code: "SITE-001", category: "construction", status: "active" }
      }
    end
    assert_response :unprocessable_entity
  end

  # edit のテスト
  test "edit が成功する" do
    get edit_admin_site_path(@site)
    assert_response :success
  end

  # update のテスト
  test "有効なパラメータで現場を更新できる" do
    patch admin_site_path(@site), params: {
      site: { name: "更新後現場名", code: "SITE-001", category: "construction", status: "active", progress_percentage: 50 }
    }
    assert_redirected_to admin_site_path(@site)
    assert_equal "更新後現場名", @site.reload.name
  end

  # update_progress のテスト
  test "update_progress でステータスと進捗率を更新できる" do
    patch update_progress_admin_site_path(@site), params: {
      site: { status: "completed", progress_percentage: 100 }
    }
    assert_redirected_to admin_site_path(@site)
    @site.reload
    assert_equal "completed", @site.status
    assert_equal 100, @site.progress_percentage
  end

  # destroy のテスト
  test "現場を削除できる" do
    assert_difference("Site.count", -1) do
      delete admin_site_path(@site)
    end
    assert_redirected_to admin_sites_path
  end
end
