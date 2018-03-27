require 'sequel'
# require 'will_paginate/sequel'
Sequel::Database.extension(:pagination, :pg_json)
Sequel.extension(:pg_array, :pg_json, :pg_json_ops)

DB = Sequel.connect(ENV['DATABASE_URL'])

require_relative 'site'
require_relative 'flow'
require_relative 'store'
require_relative 'github'
require_relative 'file_system'
