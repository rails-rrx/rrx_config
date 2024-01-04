# frozen_string_literal: true

if defined?(ActiveRecord)
  require 'active_record/database_configurations'
  ActiveRecord::DatabaseConfigurations.register_db_config_handler do |env_name, name, url, config|
    if url
      ActiveRecord::DatabaseConfigurations::UrlConfig.new(env_name, name, url, config)
    elsif RrxConfig.database?
      ActiveRecord::DatabaseConfigurations::HashConfig.new(env_name, name, RrxConfig.database.to_h)
    else
      ActiveRecord::DatabaseConfigurations::HashConfig.new(env_name, name, config)
    end
  end
end
