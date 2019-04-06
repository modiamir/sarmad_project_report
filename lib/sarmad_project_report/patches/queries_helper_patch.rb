module SarmadProjectReport
  module Patches
    module QueriesHelperPatch
      def self.included(base)
        base.extend(ClassMethods)

        base.send(:include, InstanceMethods)
        base.class_eval do
          alias_method_chain :column_value, :patch
        end
      end

      module ClassMethods

      end

      module InstanceMethods


        def column_value_with_patch(column, item, value)
          case column.name
          when :id
            link_to value, issue_path(item)
          when :subject
            link_to value, issue_path(item)
          when :parent
            if value.is_a? Issue
              value ? (value.visible? ? link_to_issue(value, :subject => false) : "##{value.id}") : ''
            else
              format_object(value)
            end
          when :description
            item.description? ? content_tag('div', textilizable(item, :description), :class => "wiki") : ''
          when :last_notes
            item.last_notes.present? ? content_tag('div', textilizable(item, :last_notes), :class => "wiki") : ''
          when :done_ratio
            progress_bar(value)
          when :relations
            content_tag('span',
                        value.to_s(item) {|other| link_to_issue(other, :subject => false, :tracker => false)}.html_safe,
                        :class => value.css_classes_for(item))
          when :hours, :estimated_hours
            format_hours(value)
          when :spent_hours
            link_to_if(value > 0, format_hours(value), project_time_entries_path(item.project, :issue_id => "#{item.id}"))
          when :total_spent_hours
            link_to_if(value > 0, format_hours(value), project_time_entries_path(item.project, :issue_id => "~#{item.id}"))
          when :attachments
            value.to_a.map {|a| format_object(a)}.join(" ").html_safe
          when :status
            if value.present? && item.is_a?(Project)
              case value
              when 1
                status_label = 'active'
              when 5
                status_label = 'closed'
              when 9
                status_label = 'archived'
              else
                status_label = 'unknown'
              end
              l('project_status_' + status_label)
            else
              format_object(value)
            end
          else
            format_object(value)
          end
        end

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
