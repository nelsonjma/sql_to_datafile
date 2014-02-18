load File.dirname(__FILE__) + '/class/run_queries.rb'


# just run if you add arguments
if ARGV.length >= 0
  # to be used in tests
  #store = StoreData.new('C:\Users\xoli169\Desktop\codigo\ruby\sql_to_datafile\config.xml')

  # for production
  store = StoreData.new(ARGV[0].to_s)
  store.options_execution
else
  puts 'you need to add the database config file path'
end

