module Admin
  class ProductsController < BaseController
    before_action :set_product, only: [:show, :edit, :update]

    def index
      @products = current_tenant.products.order(:code, :id)
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
