require 'rubygems'
require 'sqlite3'

db = SQLite3::Database.open 'configs.db'

# usar para correr queries
db.results_as_hash = true

schedule_interval = '30'

sql = ''
sql += ' select '
sql += '  p.name, '
sql += '  p.xml_folder_path, '
sql += '  f.title, '
sql += '  f.options '
sql += ' from '
sql += '  page p, '
sql += '  frame f '
sql += ' where p.id = f.id_page '
sql += ' and f.schedule_interval = ' + schedule_interval
sql += ' and f.is_active = 1 '

data = db.execute sql

data.each do |r|
  puts "#{r['name']} | #{r['xml_folder_path']} | #{r['title']}"
end
