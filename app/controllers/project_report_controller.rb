class ProjectReportController < ApplicationController
  menu_item :overview
  menu_item :settings, :only => :settings
  menu_item :projects, :only => [:index, :new, :copy, :create]

  before_action :find_project, :except => [ :index, :autocomplete, :list, :new, :create, :copy ]
  before_action :authorize, :except => [ :index, :autocomplete, :list, :new, :create, :copy, :archive, :unarchive, :destroy]
  before_action :authorize_global, :only => [:new, :create]
  before_action :require_admin, :only => [ :copy, :archive, :unarchive, :destroy ]
  accept_rss_auth :index
  accept_api_auth :index, :show, :create, :update, :destroy
  require_sudo_mode :destroy

  helper :custom_fields
  helper :issues
  helper :queries
  include QueriesHelper
  helper :repositories
  helper :members
  helper :projects

  def index
    # try to redirect to the requested menu item
    if params[:jump] && redirect_to_menu_item(params[:jump])
      return
    end

    retrieve_project_query
    scope = project_scope

    respond_to do |format|
      format.html {
        @entry_count = scope.count
        @entry_pages = Paginator.new @entry_count, per_page_option, params['page']
        @entries = scope.offset(@entry_pages.offset).limit(@entry_pages.per_page).to_a
      }
      format.api  {
        @offset, @limit = api_offset_and_limit
        @project_count = scope.count
        @projects = scope.offset(@offset).limit(@limit).to_a
      }
      format.atom {
        projects = scope.reorder(:created_on => :desc).limit(Setting.feeds_limit.to_i).to_a
        render_feed(projects, :title => "#{Setting.app_title}: #{l(:label_project_latest)}")
      }
      format.csv {
        # Export all entries
        @entries = scope.to_a
        send_data(query_to_csv(@entries, @query, params), :type => 'text/csv; header=present', :filename => 'projects.csv')
      }
    end
  end

  private

  # Returns the ProjectEntry scope for index
  def project_scope(options={})
    @query.results_scope(options)
  end

  def retrieve_project_query
    retrieve_query(ProjectQuery, false)
  end
end
