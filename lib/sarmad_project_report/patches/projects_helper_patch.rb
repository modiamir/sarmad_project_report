module SarmadProjectReport
  module Patches
    module ProjectsHelperPatch
      def self.included(base)
        base.extend(ClassMethods)

        base.send(:include, InstanceMethods)
        base.class_eval do

        end
      end

      module ClassMethods

      end

      module InstanceMethods
        def grouped_project_list(projects, query, &block)
          ancestors = []
          grouped_query_results(projects, query) do |project, group_name, group_count, group_totals|
            while (ancestors.any? && !project.is_descendant_of?(ancestors.last))
              ancestors.pop
            end
            yield project, ancestors.size, group_name, group_count, group_totals
            ancestors << project unless project.leaf?
          end
        end
      end
    end
  end
end

unless ProjectsHelper.included_modules.include?(SarmadProjectReport::Patches::ProjectsHelperPatch)
  ProjectsHelper.send(:include, SarmadProjectReport::Patches::ProjectsHelperPatch)
end
