module DocumentNumbering
  extend ActiveSupport::Concern

  class_methods do
    def generates_document_number(attribute, prefix:)
      before_validation(on: :create) do
        next if public_send(attribute).present?

        loop do
          candidate = "#{prefix}-#{Time.current.strftime('%Y%m%d%H%M%S')}-#{SecureRandom.hex(2).upcase}"
          next if self.class.unscoped.exists?(attribute => candidate)

          self.public_send("#{attribute}=", candidate)
          break
        end
      end
    end
  end
end
