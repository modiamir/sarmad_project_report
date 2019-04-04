module SarmadProjectReport
  module Patches
    module QueryPatch
      def self.included(base)
        base.extend(ClassMethods)

        base.send(:include, InstanceMethods)
        base.class_eval do
          alias_method_chain :build_from_params, :patch
          alias_method_chain :columns, :patch
          alias_method_chain :statement, :patch
        end
      end

      module ClassMethods

      end

      module InstanceMethods
        def display_type
          options[:display_type] || self.available_display_types.first
        end

        def display_type=(type)
          unless type || self.available_display_types.include?(type)
            type = self.available_display_types.first
          end
          options[:display_type] = type
        end

        def available_display_types
          ['list']
        end

        def build_from_params_with_patch(params)
          build_from_params_without_patch(params)
          self.display_type = params[:display_type] || (params[:query] && params[:query][:display_type])

          self
        end

        def columns_with_patch
          return [] if self.available_columns.empty?

          columns_without_patch
        end

        def statement_with_patch
          # filters clauses
          filters_clauses = []
          filters.each_key do |field|
            next if field == "subproject_id"
            v = values_for(field).clone
            next unless v and !v.empty?
            operator = operator_for(field)

            # "me" value substitution
            if %w(assigned_to_id author_id user_id watcher_id updated_by last_updated_by).include?(field)
              if v.delete("me")
                if User.current.logged?
                  v.push(User.current.id.to_s)
                  v += User.current.group_ids.map(&:to_s) if field == 'assigned_to_id'
                else
                  v.push("0")
                end
              end
            end

            if field == 'project_id' || (self.type == 'ProjectQuery' && field == 'id')
              if v.delete('mine')
                v += User.current.memberships.map(&:project_id).map(&:to_s)
              end
            end

            if field =~ /^cf_(\d+)\.cf_(\d+)$/
              filters_clauses << sql_for_chained_custom_field(field, operator, v, $1, $2)
            elsif field =~ /cf_(\d+)$/
              # custom field
              filters_clauses << sql_for_custom_field(field, operator, v, $1)
            elsif field =~ /^cf_(\d+)\.(.+)$/
              filters_clauses << sql_for_custom_field_attribute(field, operator, v, $1, $2)
            elsif respond_to?(method = "sql_for_#{field.gsub('.','_')}_field")
              # specific statement
              filters_clauses << send(method, field, operator, v)
            else
              # regular field
              filters_clauses << '(' + sql_for_field(field, operator, v, queried_table_name, field) + ')'
            end
          end if filters and valid?

          if (c = group_by_column) && c.is_a?(QueryCustomFieldColumn)
            # Excludes results for which the grouped custom field is not visible
            filters_clauses << c.custom_field.visibility_by_project_condition
          end

          filters_clauses << project_statement
          filters_clauses.reject!(&:blank?)

          filters_clauses.any? ? filters_clauses.join(' AND ') : nil
        end
      end
    end
  end
end

unless Query.included_modules.include?(SarmadProjectReport::Patches::QueryPatch)
  Query.send(:include, SarmadProjectReport::Patches::QueryPatch)
end
