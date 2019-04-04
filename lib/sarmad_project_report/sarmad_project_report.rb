Rails.configuration.to_prepare do
  require 'sarmad_project_report/patches/projects_helper_patch'
  require 'sarmad_project_report/patches/queries_helper_patch'
  require 'sarmad_project_report/patches/query_patch'
end
