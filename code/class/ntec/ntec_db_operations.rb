require 'rubygems'
require 'sqlite3'

#load 'ntec_options.rb' # run from the same folder
load 'class/ntec/ntec_options.rb' # run from sql_to_datafile

class NtecConfigOption
  # sql => [], conn => []
  # normaly datafile = datatable but if sql contains more than one query then
  # it will be one datatable for one sql => datatable_name => []
  attr_accessor :page, :xml_folder_path, :frame,
                :sql, :conn, :datafile, :datatable

  def initialize
    @page = nil
    @xml_folder_path = nil
    @frame = nil
    @sql = []
    @conn =  []
    @datafile = nil
    @datatable = []
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

      puts 'geting data from ntec config db: ' + e.message
    end
  end

  def process_db_data(dt)
    dt.each do |r|
      begin
        ntec_op = NtecConfigOption.new

        ntec_op.page = r['name']
        ntec_op.frame = r['title']
        ntec_op.xml_folder_path = r['xml_folder_path']

        # inicialize ntec option decoder
        op_decoded = NtecOptions.new(r['options'])

        ntec_op.datafile = op_decoded.get_first('datafile')
        ntec_op.datatable = op_decoded.get_all('datatable')
        ntec_op.sql = op_decoded.get_all('sql')
        ntec_op.conn = op_decoded.get_all('conn')

        # add ntec to option list
        @options.push(ntec_op)

      rescue Exception => e
        # destroy the connection
        @db = nil

        puts 'processing data from ntec config db: ' + e.message
      end
    end
  end

  private :get_data, :process_db_data
end