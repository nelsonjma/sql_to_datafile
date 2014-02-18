require 'rubygems'
require 'sqlite3'

#load 'ntec_options.rb' # run from the same folder
load File.dirname(__FILE__) + '/ntec_options.rb' # run from sql_to_datafile

class NtecConfigOption
  # sql => [], conn => []
  # normaly datafile = datatable but if sql contains more than one query then
  # it will be one datatable for one sql => datatable_name => []
  attr_accessor :page, :folder_path, :frame,
                :sql, :conn, :datafile, :datatable,
                :clean_data, :drop_table, :xml_file

  def initialize
    @page = nil
    @folder_path = nil
    @frame = nil
    @sql = []
    @conn =  []
    @datafile = nil
    @datatable = []
    @xml_file = nil
  end

  # datatable can be equal to datafile if datafile not defined
  def datatable
    if @datatable.count == 0 && datafile != nil
      @datatable.push(datafile)
    end

    @datatable
  end
end

class NtecConfigOptions
  attr_accessor :options, :db

  def initialize(db_path, schedule_interval)
    @options = []
    @db = nil

    # get data from ntec database and then process it
    get_data(db_path, schedule_interval)
  end

  def get_data(db_path, schedule_interval)
    begin
      @db = SQLite3::Database.open db_path
      @db.results_as_hash = true

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
      sql += ' and f.schedule_interval = ' + schedule_interval.to_s
      sql += ' and f.is_active = 1 '

      process_db_data(@db.execute sql)

    rescue Exception => e
      # destroy the connection
      @db = nil

      throw 'geting data from ntec config db: ' + e.message
    end
  end

  def process_db_data(dt)
    begin
       dt.each do |r|
        begin
          ntec_op = NtecConfigOption.new

          ntec_op.page = r['name']
          ntec_op.frame = r['title']
          ntec_op.folder_path = r['xml_folder_path']

          # inicialize ntec option decoder
          op_decoded = NtecOptions.new(r['options'])

          ntec_op.clean_data = op_decoded.get_first('clean_data')
          ntec_op.drop_table = op_decoded.get_first('drop_table')
          ntec_op.datafile = op_decoded.get_first('datafile')
          ntec_op.datatable = op_decoded.get_all('datatable')
          ntec_op.sql = op_decoded.get_all('sql')
          ntec_op.conn = op_decoded.get_all('conn')
          ntec_op.xml_file = op_decoded.get_first('xml_file')

          # add ntec to option list
          if ntec_op.sql.count > 0 && ntec_op.conn.count > 0 && ( ntec_op.datafile != '' || ntec_op.xml_file != '')
            @options.push(ntec_op)
          end
        end
       end
    rescue Exception => e
      # destroy the connection
      @db = nil

      throw 'processing data from ntec config db: ' + e.message
    end
  end

  private :get_data, :process_db_data
end