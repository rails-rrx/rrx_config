# frozen_string_literal: true

require 'rails/railtie'
require 'active_support'

module RrxConfig
  class Railtie < Rails::Railtie
    initializer 'rrx_config.initialize_database', before: 'active_record.initialize_database' do
      ActiveSupport.on_load(:active_record) do
        # Make sure our config handler is registered before Rails initializes
        require_relative './database_config'
      end
    end

    rake_tasks do
      namespace :db do
        task rrx_init_config: :environment do
          # Make sure our config handler is registered before the Rails rake task runs
          require_relative './database_config'
        end

        task load_config: 'db:rrx_init_config'

        task print_config: 'db:load_config' do
          puts JSON.pretty_generate(ActiveRecord::Base.connection_db_config.configuration_hash)
        end
      end
    end
  end
end
