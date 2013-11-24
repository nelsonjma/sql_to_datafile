require 'rubygems'
require 'thread'

# get ntec configs
load 'class/ntec/ntec_db_operations.rb'
# database connection
load 'class/database/datatable.rb'
load 'class/database/connect_to_oledb.rb'
load 'class/database/connect_to_sqlite.rb'
# datafile write
load 'class/database/write_to_sqlite.rb'
# read xml files
load 'class/xml/read_xml.rb'
# logging
load 'class/log/logme.rb'

class StoreData
  attr_accessor :db_path, :schedule_time, :default_datafile_folder, :parallel_threads,
                :config_file_path, :options, :thread_semaphore, :log

  def initialize(config_file_path)
    @config_file_path = config_file_path

    @db_path = nil
    @schedule_time = nil
    @default_datafile_folder = nil
    @parallel_threads = nil
    @thread_semaphore = nil
    @log = nil

    @options = []
  end

  ################### PUBLIC ###################
  def options_execution
    begin
      # get information from config file
      read_config_file

      # get ntec options
      get_ntec_options

      # thread initialize
      ths = []
      thread_count = 0;

      @thread_semaphore = Mutex.new
      ###################

      # logging
      @log = LogMe.new

      @options.each do |option|
        index = @log.add_item(option.page, option.frame)
        @log.add_output_msg_by_index(index, 'waiting: ' + Time.now.strftime('%H:%M:%S'))
      end
      ###################

      # process options
      @options.each do |option|

        thread_count += + 1

        th = Thread.new{ option_execution(option) }

        # wait for the thread to start
        until th.alive?
          sleep 0.1
        end

        ths.push(th)

        ths, thread_count = thread_wait_management(ths, thread_count)
      end

      # dont want to have no more threads active
      @parallel_threads = 0

      # launtch last thread manager execution
      thread_wait_management(ths, thread_count)

      puts 'end run...'
    rescue Exception => e
      puts 'generic error: ' + e.message.to_s.gsub('uncaught throw', '').gsub('\"', '').gsub('\\\\', '\\')
    end
  end

  ################### PRIVATE ###################

  # show console information about the thread status
  def logging_show_report
    @thread_semaphore.synchronize {
      if @log != nil
        @log.show_report
      end
    }

  end

  def logging_store_msg(page, frame, msg)
      @thread_semaphore.synchronize {
        if @log != nil
          @log.add_output_msg_by_name(page, frame, msg + ' ' + Time.now.strftime('%H:%M:%S'))
        end
      }
  end

  # controls the thread waiting
  def thread_wait_management(ths, thread_count)
    begin
      while thread_count > @parallel_threads

        # check if all threads are alive
        (0..ths.count-1).each do |i|
          if ths[i] != nil && !ths[i].alive?
            ths[i] = nil
            thread_count += -1
          end
        end

        sleep 0.5

        # show data to console
        logging_show_report
      end
    rescue Exception => e
      puts 'thread management error: ' + e.message.to_s.gsub('uncaught throw', '').gsub('\"', '').gsub('\\', '')
    end

    return ths, thread_count
  end

  # process one option
  def option_execution(option)
    page = nil
    frame = nil
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

      # log starting
      logging_store_msg(page, frame, 'starting')

      if sql.count > 0 && sql.count == datatable.count && (conn.count == sql.count || conn.count == 1)
        (0..sql.count-1).each { |i|

          aux_sql = sql[i]
          aux_conn = conn.count == 1 ? conn[0] : conn[i]
          aux_datatable = datatable[i]

          process_option(page, frame, aux_conn, aux_sql, aux_datatable, datafile, clean_data, drop_table, folder_path)
        }
      end

    rescue Exception => e
      # log error
      logging_store_msg(page, frame, e.message.to_s.gsub('uncaught throw', '').gsub('\"', '').gsub('\\', ''))
    end
  end

  # run query and then write data to datafile
  def process_option(page, frame, conn, sql, datatable, datafile, clean_data, drop_table, folder_path)
    begin
      # log query start
      logging_store_msg(page, frame, 'query running:')

      data = run_query(conn, sql)

      # log write to datafile
      logging_store_msg(page, frame, 'write to datafile:')

      write_to_datafile(data, datatable, datafile, clean_data, drop_table, folder_path)


      # log write to datafile
      logging_store_msg(page, frame, 'end:')

    rescue Exception => e
      throw e.message
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

      @db_path = xml.first_element('//config/db_path').to_s.strip
      @schedule_time = xml.first_element('//config/schedule_time').to_s.strip
      @default_datafile_folder = xml.first_element('//config/default_datafile_folder').to_s.strip
      @parallel_threads =  xml.first_element('//config/parallel_queries').to_s.strip.to_i

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
      throw 'query: ' + e.message
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
      throw 'writing: ' + e.message
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
          :option_execution,
          :thread_wait_management,
          :logging_show_report,
          :logging_store_msg
end