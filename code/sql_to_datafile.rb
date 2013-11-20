load 'class/xml/read_xml.rb'
load 'class/ntec/ntec_db_operations.rb'
load 'class/database/write_to_sqlite.rb'

# read xml configs
xml = ReadXml.new('config.xml')
db_path = xml.first_element('//config/db_path')
schedule_time = xml.first_element('//config/schedule_time')
default_datafile_folder = xml.first_element('//config/default_datafile_folder')
parallel_threads =  xml.first_element('//config/parallel_queries')
xml.dispose




# database path
# schedule interval
# default xml folder

####################################################################
#ntec_config = NtecConfigOptions.new('configs.db', 30)
#ntec_config.options.each do |op|
#  puts '------------------'
#  puts ' ' + op.page + '|'  +  op.frame + '|' + op.page + '|' + op.xml_folder_path + '|' + op.datafile + '|'
#  op.datatable.each { |l| puts l }
#  puts '#'
#  op.conn.each { |l| puts l }
#  puts '#'
#  op.sql.each { |l| puts l }
#  puts '####################'
#end

####################################################################
#db = SQLite3::Database.open 'configs.db'
#db.results_as_hash = true
#sql = ''
#sql += ' select '
#sql += '      p.name, '
#sql += '      p.xml_folder_path, '
#sql += '      f.title, '
#sql += '      f.options '
#sql += ' from '
#sql += '      page p, '
#sql += '      frame f '
#sql += ' where p.id = f.id_page '
#sql += ' and f.schedule_interval = 30 '
#sql += ' and f.is_active = 1'
#datatable = db.execute2 sql
#columns = datatable[0]
#datatable.delete_at 0
#insert = InsertToSqlite.new('configs.db', 'test', columns, datatable)
#insert.drop_table
#insert.create_table
#insert.insert_data
