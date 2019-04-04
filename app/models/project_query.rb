# Redmine - project management software
# Copyright (C) 2006-2017  Jean-Philippe Lang
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

class ProjectQuery < Query

  self.queried_class = Project
  self.view_permission = :search_project

  self.available_columns = [
    QueryColumn.new(:name, :sortable => "#{Project.table_name}.name"),
    QueryColumn.new(:status, :sortable => "#{Project.table_name}.status"),
    QueryColumn.new(:short_description, :sortable => "#{Project.table_name}.description", :caption => :field_description),
    QueryColumn.new(:homepage, :sortable => "#{Project.table_name}.homepage"),
    QueryColumn.new(:identifier, :sortable => "#{Project.table_name}.identifier"),
    QueryColumn.new(:parent_id, :sortable => "#{Project.table_name}.lft ASC", :default_order => 'desc', :caption => :field_parent),
    QueryColumn.new(:is_public, :sortable => "#{Project.table_name}.is_public", :groupable => true),
    QueryColumn.new(:created_on, :sortable => "#{Project.table_name}.created_on", :default_order => 'desc'),
    QueryColumn.new(:spent_budget, :inline => false),
    QueryColumn.new(:estimated_budget, :inline => false),
    QueryColumn.new(:estimated_income, :inline => false),
    QueryColumn.new(:actual_income, :inline => false)
  ]

  def initialize(attributes=nil, *args)
    super attributes
    self.filters ||= { 'status' => {:operator => "=", :values => ['1']} }
  end

  def initialize_available_filters
    add_available_filter "status",
      :type => :list, :values => lambda { project_statuses_values }
    add_available_filter("id",
      :type => :list, :values => lambda { project_values }, :label => :field_project
    )
    add_available_filter "name", :type => :text
    add_available_filter "description", :type => :text
    add_available_filter("parent_id",
      :type => :list_subprojects, :values => lambda { project_values }, :label => :field_parent
    )
    add_available_filter "is_public",
      :type => :list,
      :values => [[l(:general_text_yes), "1"], [l(:general_text_no), "0"]]
    add_available_filter "created_on", :type => :date_past
    add_custom_fields_filters(ProjectCustomField.all)
  end

  def available_columns
    return @available_columns if @available_columns
    @available_columns = self.class.available_columns.dup
    @available_columns += ProjectCustomField.visible.
                            map {|cf| QueryAssociationCustomFieldColumn.new(:project, cf) }
    @available_columns
  end

  def available_display_types
    ['board', 'list']
  end

  def default_columns_names
    @default_columns_names = [:name, :identifier, :short_description]
  end

  def default_sort_criteria
    [['lft', 'desc']]
  end

  def base_scope
    Project.visible.where(statement)
  end

  def results_scope(options={})
    order_option = [group_by_sort_order, (options[:order] || sort_clause)].flatten.reject(&:blank?)

    scope = base_scope.
      order(order_option).
      joins(joins_for_order_statement(order_option.join(',')))

    if has_custom_field_column?
      scope = scope.preload(:custom_values)
    end

    if has_column?(:parent_id)
      scope = scope.preload(:parent)
    end

    scope
  end

  # Returns a scope of project statuses that are available as columns or filters
  def project_statuses_values
    [
      [l(:project_status_active), "#{Project::STATUS_ACTIVE}"],
      [l(:project_status_closed), "#{Project::STATUS_CLOSED}"]
    ]
  end
end
