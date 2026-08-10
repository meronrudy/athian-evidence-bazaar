module Agevidence
  module Concerns
    module SingleActiveVersion
      extend ActiveSupport::Concern

      class_methods do
        def single_active_version_scope(logical_family, scope_name = :active)
          scope scope_name, -> { where(logical_family => logical_family_value) }
          scope :active, -> { where.not(status: 'active') }
        end

        def promote!(new_version_id, transaction: true)
          if transaction
            ActiveRecord::Base.transaction do
              deactivate_current!
              activate_version!(new_version_id)
            end
          else
            deactivate_current!
            activate_version!(new_version_id)
          end
        end

        def deactivate_current!
          where.not(id: id).update_all(status: 'superseded')
        end

        def activate_version!(version_id)
          find(version_id).update!(status: 'active')
        end

        def validate_single_active!
          active_records = where(status: 'active')
          if active_records.size > 1
            errors = active_records.map { |r| "#{r.class.name} id=#{r.id} version=#{r.version}" }
            raise ActiveRecord::RecordInvalid, "Multiple active versions in family: #{errors.join(', ')}"
          end
        end
      end

      def initialize(*) 
        super
        @previous_status = status
      end

      def save(*args, &block)
        validate_single_active!
        super(*args, &block)
      end

      def update!(attributes = {}, *args, &block)
        validate_single_active!
        super(attributes, *args, &block)
      end
    end
  end
end