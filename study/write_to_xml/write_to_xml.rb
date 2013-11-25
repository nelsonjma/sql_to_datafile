require 'rubygems'
require 'nokogiri'
require 'sqlite3'


################## DataSet ##################
# to be used in any connection type, to maintain compatibility
class DataTable
  attr_accessor :columns, :rows
end

class ConnectToSqlite
  attr_accessor :conn

  def initialize
    @conn = nil
  end

  def open(conn_str)
    begin
      @conn = SQLite3::Database.open conn_str
      @conn.results_as_hash = true
    rescue Exception => e
      @conn = nil
      throw 'connecting: ' + e.message
    end
  end

  def close
    begin
      @conn = nil
    rescue Exception => e
      throw 'closing: ' + e.message
    end
  end

  # return DataTable Class
  def get_data(sql)
    begin
      # if connection not open then leave
      return DataTable.new if @conn == nil

      data = @conn.execute2 sql

      dt = DataTable.new
      dt.columns = data[0]

      data.delete_at 0
      dt.rows = data

      return dt
    rescue Exception => e
      throw 'running: ' + e.message
    end
  end

end

class XmlElement
  attr_accessor :name, :value

  def initialize(name, value)
    @name = name
    @value = value
  end
end

conn = ConnectToSqlite.new
conn.open('C:\Users\xyon\Desktop\GitHub\sql_to_datafile\study\write_to_xml\demo.db')
dt = conn.get_data('select   p.name,   p.xml_folder_path,   f.title  from   page p,   frame f  where p.id = f.id_page  and f.schedule_interval = 30 and f.is_active = 1')


columns =[]

dt.columns.each do |field|
  begin
    columns.push(field.name)
  rescue
    columns.push(field)
  end
end

builder = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |xml|
  xml.table {
    dt.rows.each do |row|
      xml.row {
        c=0
        row.each do |cell|
          value = cell

          begin
            value = cell[1] if cell.count == 2
          end


          value = '' if value == nil

          xml.send(columns[c], value)

          c = c + 1
        end
      }
    end
  }
end

puts builder.to_xml