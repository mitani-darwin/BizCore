module Seeds
  module Permissions
    class Admin
      def self.call
        new.call
      end

      def call
        keys = Permissions::Catalog.admin_keys
        existing_keys = Permission.where(key: keys).pluck(:key).to_set

        Permissions::Catalog.seed_admin!

        created_count = keys.count { |k| !existing_keys.include?(k) }
        updated_count = existing_keys.size

        puts "AdminPermissionSeed: created=#{created_count}, updated=#{updated_count}, total=#{keys.size}"

        Permission.where(key: keys).index_by(&:key)
      end

    end
  end
end
