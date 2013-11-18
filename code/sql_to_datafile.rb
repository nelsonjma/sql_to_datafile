load 'class/read_xml.rb'
load 'class/ntec/ntec_db_operations.rb'

#xml = ReadXml.new('config.xml')
#puts xml.first_element('//config/path')
#xml.dispose


# xml config
# database path
# schedule interval
# default xml folder


ntec_config = NtecConfigOptions.new('configs.db', 30)

ntec_config.options.each do |op|

  puts '------------------'
  puts ' ' + op.page + '|'  +  op.frame + '|' + op.page + '|' + op.xml_folder_path + '|' + op.datafile + '|'

  op.datatable.each { |l| puts l }
  puts '#'
  op.conn.each { |l| puts l }
  puts '#'
  op.sql.each { |l| puts l }


  puts '####################'

end