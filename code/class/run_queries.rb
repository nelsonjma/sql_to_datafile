require 'rubygems'

# get ntec configs
load 'ntec/ntec_db_operations.rb'
# database connection
load 'database/datatable.rb'
load 'database/connect_to_oledb.rb'
load 'database/connect_to_sqlite.rb'
# datafile write
load 'database/write_to_sqlite.rb'
# read xml files
load 'xml/read_xml.rb'

class StoreData
  attr_accessor :db_path, :schedule_time, :default_datafile_folder, :parallel_threads,
                :config_file_path, :options

  def initialize(config_file_path)
    @config_file_path = config_file_path

    @db_path = nil
    @schedule_time = nil
    @default_datafile_folder = nil
    @parallel_threads = nil

    @options = []
  end

  ################### PUBLIC ###################
  def options_execution

    # get information from config file
    @db_path = 'C:\Users\xyon\Desktop\GitHub\sql_to_datafile\code\class\configs.db'
    @schedule_time = '30'
    @default_datafile_folder = 'C:\Users\xyon\Desktop\GitHub\sql_to_datafile\code\class'
    #@parallel_threads =  xml.first_element('//config/parallel_queries')

    # get ntec options
    get_ntec_options

    # process options
    @options.each do |option|
      option_execution(option)
    end

    puts 'end run...'
  end

  ################### PRIVATE ###################
  # process one option
  def option_execution(option)
    begin
      page = option.page
      folder_path = option.folder_path
      frame = option.frame
      sql = option.sql
      conn = option.conn
      datafile = option.datafile
      datatable = option.datatable
      clean_data = option.clean_data
      drop_table = option.drop_table

      if sql.count > 0 && sql.count == datatable.count && (conn.count == sql.count || conn.count == 1)

        (0..sql.count-1).each { |i|

          aux_sql = sql[i]
          aux_conn = conn.count == 1 ? conn[0] : conn[i]
          aux_datatable = datatable[i]

          process_option(aux_conn, aux_sql, aux_datatable, datafile, clean_data, drop_table, folder_path)
        }
      end

    rescue Exception => e
      puts e.message
    end
  end

  # run query and then write data to datafile
  def process_option(conn, sql, datatable, datafile, clean_data, drop_table, folder_path)
    begin
      data = run_query(conn, sql)

      write_to_datafile(data, datatable, datafile, clean_data, drop_table, folder_path)

    rescue Exception => e
      puts e.message
    end
  end

  # get ntec information from config database
  def get_ntec_options
    begin
      ntec_op = NtecConfigOptions.new(@db_path, @schedule_time)
      @options = ntec_op.options
    end
  end

  # read xml config files
  def read_config_file
    xml = nil

    begin
      xml = ReadXml.new(@config_file_path)

      @db_path = xml.first_element('//config/db_path')
      @schedule_time = xml.first_element('//config/schedule_time')
      @default_datafile_folder = xml.first_element('//config/default_datafile_folder')
      @parallel_threads =  xml.first_element('//config/parallel_queries')

    rescue Exception => e
      throw 'error reading xml config: ' + e.message
    ensure
      xml.dispose if xml != nil
    end
  end

  # run queries in sqlite and oledb
  def run_query(conn, sql)
    dt = nil
    begin

      if conn.to_s.downcase.index('version=') != nil
        #Data Source=c:\mydb.db;Version=3;
        dt = ConnectToSqlite.new
        conn = filter_sqlite_conn_str(conn)
      else
        #Provider=OraOLEDB.Oracle;Data Source=MyOracleDB;User Id=myUsername;Password=myPassword;
        dt = ConnectToOleDb.new
      end

      dt.open(conn)

      return dt.get_data(sql)
    rescue Exception => e
      throw 'error running query: ' + e.message
    ensure
      dt.close if dt != nil
    end
  end

  # write data to sqlite datafile
  def write_to_datafile(data, datatable, datafile, clean_data, drop_table, folder_path)
    begin
      # check if table name was set
      datatable = datafile if datatable == '' || datatable == nil

      # add extension to datafile
      datafile = datafile + '.db' unless datafile.to_s.index('.db')

      # add folder to datafile name
      datafile = build_datafile_path(folder_path, datafile)

      # write to datafile
      write = WriteToSqlite.new(datafile, data.columns, data.rows)

      clean_data = clean_data.to_s.downcase.strip
      drop_table = drop_table.to_s.downcase.strip

      if drop_table.index('false') != nil && clean_data.index('true') == nil # just add new data
        # user just wants to add data
        write.table_name = datatable
        write.insert_data
      elsif clean_data.index('true') != nil # clear original table then add new data
        # => ORIGINAL datatable
        write.table_name = datatable
        write.clean_data
        write.insert_data
      else # drop data
        # => TMP datatable
        write.table_name = datatable + '_tmp'
        write.drop_table
        write.create_table
        write.insert_data
        # => ORIGINAL datatable
        write.table_name = datatable
        write.drop_table
        write.change_name(datatable + '_tmp', datatable)
      end
    rescue Exception => e
      throw 'error writing to datafile: ' + e.message
    end
  end

  # just get the file path ignoring the rest of the information
  def filter_sqlite_conn_str(conn)
    #[Data Source=c:\mydb.db], [Version=3]
    list_conn_params = conn.to_s.split(';')

    list_conn_params.each do |conn_op|
      if conn_op.to_s.downcase.index('source=')
        #Data Source=c:\mydb.db => c:\mydb.db
        return conn_op[conn_op.index('=')+1..conn_op.length]
      end
    end

    ''
  end

  def build_datafile_path(folder_path, datafile)

    folder_path = @default_datafile_folder if folder_path.to_s.strip == '' || folder_path.to_s.strip.downcase == 'default'

    folder_path.to_s.strip.end_with?('\\') ? folder_path.strip + datafile : folder_path.strip + '\\' + datafile
  end

  private :build_datafile_path,
          :filter_sqlite_conn_str,
          :write_to_datafile,
          :run_query,
          :read_config_file,
          :get_ntec_options,
          :process_option,
          :option_execution
end



store = StoreData.new('')
store.options_execution
