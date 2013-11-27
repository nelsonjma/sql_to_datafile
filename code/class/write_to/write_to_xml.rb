require 'rubygems'
require 'nokogiri'

load 'class/database/connect_to_sqlite.rb'
load 'class/database/datatable.rb'



class WriteToXml
  attr_accessor :xml_file, :columns, :rows, :column_array

  def initialize(xml_file, columns, rows)
    @xml_file = xml_file
    @columns = columns
    @rows = rows
  end

  def write
    begin
      build_column_array

      builder = buid_row_array

      f = File.open(@xml_file, 'w')
      f.write(builder.to_xml)
      f.close
    rescue Exception => e
      puts 'xml write:' + e.message.to_s
    end
  end

  # extract the columns to a new column array...
  def build_column_array
    @column_array =[]

    @columns.each do |field|
      begin
        column_array.push(field.name)
      rescue
        column_array.push(field)
      end
    end
  end

  def buid_row_array
    builder = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |xml|
      xml.table {
        @rows.each do |row|
          xml.row {
            c=0
            row.each do |cell|
              value = cell

              begin
                value = cell[1] if cell.count == 2
              end

              value = '' if value == nil

              xml.send(column_array[c], value)

              c = c + 1
            end
          }
        end
      }
    end

    return builder
  end

  private :build_column_array,
          :buid_row_array

end