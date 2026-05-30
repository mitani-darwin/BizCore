module Admin
  # 帳票テンプレートの設定編集を管理する。テナント×帳票種別で一意のレコードを管理する。
  class DocumentTemplatesController < BaseController
    before_action :set_template, only: [ :edit, :update ]

    def index
      all_templates = DocumentTemplate::DOCUMENT_TYPES.map do |doc_type|
        DocumentTemplate.for_tenant_and_type(current_tenant, doc_type)
      end
      @pagy, @templates = pagy_array(all_templates)
    end

    def edit; end

    def update
      new_settings = build_settings_from_params
      if @template.update(settings: new_settings)
        audit!(
          action_key: required_permission_key,
          auditable: @template,
          metadata: { document_type: @template.document_type }
        )
        redirect_to admin_document_templates_path, notice: "#{@template.definition[:title]}のテンプレートを更新しました。"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_template
      doc_type = params[:document_type].to_s
      unless DocumentTemplate::DOCUMENT_TYPES.include?(doc_type)
        render_not_found and return
      end
      @template = DocumentTemplate.for_tenant_and_type(current_tenant, doc_type)
    end

    def build_settings_from_params
      raw = params[:document_template]&.dig(:settings) || {}

      column_widths = parse_column_widths(raw[:column_widths])
      row_visibility = parse_row_visibility(raw[:row_visibility])
      item_column_labels = parse_item_column_labels(raw[:item_column_labels])

      {
        "company_header_enabled" => raw[:company_header_enabled] == "1",
        "company_name" => raw[:company_name].to_s.strip,
        "company_postal_code" => raw[:company_postal_code].to_s.strip,
        "company_address" => raw[:company_address].to_s.strip,
        "company_tel" => raw[:company_tel].to_s.strip,
        "company_email" => raw[:company_email].to_s.strip,
        "column_widths" => column_widths,
        "row_visibility" => row_visibility,
        "item_column_labels" => item_column_labels
      }
    end

    def parse_column_widths(raw)
      defaults = @template.definition[:column_widths] || []
      return defaults unless raw.is_a?(ActionController::Parameters) || raw.is_a?(Hash)

      values = raw.to_unsafe_h.sort_by { |k, _| k.to_i }.map { |_, v| [ v.to_i, 1 ].max }
      values.length == defaults.length ? values : defaults
    end

    def parse_row_visibility(raw)
      raw_hash = raw.is_a?(ActionController::Parameters) ? raw.to_unsafe_h : (raw || {})
      (@template.definition[:rows] || []).each_with_object({}) do |row_def, h|
        h[row_def[:key]] = raw_hash[row_def[:key]] == "1"
      end
    end

    def parse_item_column_labels(raw)
      raw_hash = raw.is_a?(ActionController::Parameters) ? raw.to_unsafe_h : (raw || {})
      (@template.definition[:item_columns] || []).each_with_object({}) do |col_def, h|
        label = raw_hash[col_def[:key]].to_s.strip
        h[col_def[:key]] = label.present? ? label : col_def[:default_label]
      end
    end
  end
end
