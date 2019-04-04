module SarmadProjectReport
  module Patches
    module QueriesHelperPatch
      def self.included(base)
        base.extend(ClassMethods)

        base.send(:include, InstanceMethods)
        base.class_eval do

        end
      end

      module ClassMethods

      end

      module InstanceMethods
        def available_display_types_tags(query)
          available_display_types = []
          query.available_display_types.each do |t|
            available_display_types << [l(:"label_display_type_#{t}"), t]
          end
          select_tag('display_type', options_for_select(available_display_types, @query.display_type), :id => 'display_type')
        end
      end
    end
  end
end

unless QueriesHelper.included_modules.include?(SarmadProjectReport::Patches::QueriesHelperPatch)
  QueriesHelper.send(:include, SarmadProjectReport::Patches::QueriesHelperPatch)
end
