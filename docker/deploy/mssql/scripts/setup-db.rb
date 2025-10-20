require 'sequel'
require 'yaml'

# Load the databases from the yaml file
config = YAML.safe_load(File.open("databases.yaml"), aliases: true)

defaults = config['defaults']
databases = config['databases']

# Iterate over each database
databases.each do |db|
  db_config = defaults.merge(db).merge(user: "sa", password: ENV['DB_PASSWORD'])

  # Connect to the server with Sequel
  db_connection = Sequel.connect(adapter: ENV['DB_ADAPTER'], user: 'sa', password: ENV['DB_PASSWORD'], host: ENV['DB_HOST'], database_url: db_config['DATABASE_URL'])

  # Check if the login SVC_DS_DEPLOY already exists
  if db_connection.fetch("SELECT 1 FROM sys.syslogins WHERE name = 'SVC_DS_DEPLOY'").first
    puts "Login 'SVC_DS_DEPLOY' already exists. skip create Login"
  else
    puts "Create Login 'SVC_DS_DEPLOY'"
    # Run the setup-user.sql script
    File.read('./scripts/sql/setup-user.sql').split("GO").each do |sql|
      db_connection.run(sql)
    end
  end

  # Disconnect from the server
  db_connection.disconnect

  # Connect to the specific database with Sequel
  db_connection = Sequel.connect(adapter: ENV['DB_ADAPTER'], user: 'sa', password: ENV['DB_PASSWORD'], host: ENV['DB_HOST'], database_url: db_config['DATABASE_URL'])

  # Check if the database already exists
  if db_connection.fetch("SELECT 1 FROM sys.databases WHERE name = '#{db_config['DB_NAME']}'").first
    puts "DB #{db_config['DB_NAME']} already exists, skip create DB "
  else
    # Run the setup-db.sql script
    puts "DB #{db_config['DB_NAME']} doesn't exist, create DB "
    File.read('./scripts/sql/setup-db.sql').gsub('$(MSSQL_DATABASE)', db_config['DB_NAME']).split("GO").each do |sql|
      db_connection.run(sql)
    end
  end
end
