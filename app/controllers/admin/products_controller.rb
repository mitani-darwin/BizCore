module Admin
  # 商品マスタの CRUD を管理する。在庫・発注・受注各明細から参照される。
  class ProductsController < BaseController
    before_action :set_product, only: [ :show, :edit, :update ]

    def index
      @pagy, @products = pagy(current_tenant.products.order(:code, :id))
    end

    def show; end

    def new
      @product = current_tenant.products.build(
        unit_name: "個",
        tax_category: "taxable_10",
        active: true
      )
    end

    def create
      @product = current_tenant.products.build(product_params)

      if @product.save
        redirect_to admin_product_path(@product), notice: "商品を作成しました。"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @product.update(product_params)
        redirect_to admin_product_path(@product), notice: "商品を更新しました。"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    # GET / POST /admin/products/import
    def import
      return unless request.post?

      file = params[:file]
      unless file.present?
        flash.now[:alert] = "ファイルを選択してください。"
        render :import, status: :unprocessable_entity and return
      end

      csv_string = file.read.force_encoding("UTF-8")
      @import_result = Imports::ProductImport.call(tenant: current_tenant, csv_string: csv_string)
      audit!(action_key: required_permission_key, metadata: { total: @import_result.total, succeeded: @import_result.succeeded })
    rescue ArgumentError => e
      flash.now[:alert] = e.message
    end

    # GET /admin/products/import_template
    def import_template
      csv = Imports::ProductImport.template_csv
      send_data(csv.encode("UTF-8"), filename: "商品インポートテンプレート.csv", type: "text/csv; charset=UTF-8", disposition: :attachment)
    end

    private

    def set_product
      @product = current_tenant.products.find_by(id: params[:id])
      return if @product

      render_not_found and return false
    end

    def product_params
      params.require(:product).permit(
        :code,
        :name,
        :unit_name,
        :standard_price,
        :tax_category,
        :active,
        :note
      )
    end
  end
end
