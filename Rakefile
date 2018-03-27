require "bundler/setup"
Bundler.require(:default, :development)

# require 'json'
# require 'time'

if ENV['RACK_ENV'] != 'production'
  # require 'dotenv'
  Dotenv.load
end

DB = Sequel.connect(ENV['DATABASE_URL'])
# DB[:posts].truncate

# CONTENT_PATH = "#{File.dirname(__FILE__)}/../content"
#
# def parse(file)
#   data = File.read(file)
#   post = JSON.parse(data)
#   url = file.sub(CONTENT_PATH,'').sub(/\.json$/,'')
#
#   DB[:posts].insert(url: url, data: data)
#
#   print "."
# end
#
# desc "Rebuild database cache from all content JSON files."
# task :rebuild do
#   Dir.glob("#{CONTENT_PATH}/**/*.json").each do |file|
#     parse(file)
#   end
# end
#
# desc "Rebuild database cache from this month's content JSON files."
# task :recent do
#   year_month = Time.now.strftime('%Y/%m')
#   files = Dir.glob("#{CONTENT_PATH}/#{year_month}/**/*.json")
#   # need to rebuild all cites and cards because they're not organised by month
#   files += Dir.glob("#{CONTENT_PATH}/cite/**/*.json")
#   files += Dir.glob("#{CONTENT_PATH}/card/**/*.json")
#   files.each do |file|
#     parse(file)
#   end
# end
#
# desc "Fetch a context and store."
# task :context_fetch, :url do |t, args|
#   url = args[:url]
#   Transformative::Context.fetch(url)
# end

# via https://stackoverflow.com/questions/22800017/sequel-generate-migration
namespace :db do
  require "sequel"
  Sequel.extension :migration
  # DB = Sequel.connect(ENV['DATABASE_URL'])

  desc "Prints current schema version"
  task :version do
    version = if DB.tables.include?(:schema_info)
      DB[:schema_info].first[:version]
    end || 0

    puts "Schema Version: #{version}"
  end

  desc "Run migrations"
  task :migrate, [:version] do |t, args|
    if args[:version]
      puts "Migrating to version #{args[:version]}"
      Sequel::Migrator.run(DB, "db/migrate", target: args[:version].to_i)
    else
      puts "Migrating to latest"
      Sequel::Migrator.run(DB, "db/migrate")
    end
    Rake::Task['db:version'].execute
  end

  desc "Perform rollback to specified target or full rollback as default"
  task :rollback, :target do |t, args|
    args.with_defaults(:target => 0)

    Sequel::Migrator.run(DB, "db/migrate", :target => args[:target].to_i)
    Rake::Task['db:version'].execute
  end

  desc "Perform migration reset (full rollback and migration)"
  task :reset do
    Sequel::Migrator.run(DB, "db/migrate", :target => 0)
    Sequel::Migrator.run(DB, "db/migrate")
    Rake::Task['db:version'].execute
  end
end
