require 'rubygems'

load 'ntec/ntec_db_operations.rb'
load 'database/connect_to_oledb.rb'
load 'database/connect_to_sqlite.rb'
load 'database/write_to_sqlite.rb'
load 'database/datatable.rb'

class StoreData
  attr_accessor :db_path, :schedule_time, :default_datafile_folder,
                :parallel_threads, :options

  def initialize(db_path, schedule_time, datafile_folder, parallel_threads)
    @db_path = db_path
    @schedule_time = schedule_time
    @default_datafile_folder = datafile_folder
    @parallel_threads = parallel_threads

    @options = []
  end

  ################### PUBLIC ###################
  def get_options
    begin
      ntec_op = NtecConfigOptions.new(@db_path, @schedule_time)
      @options = ntec_op.options
    end
  end

  def store_queries(conn, sql, datatable, datafile)
    begin
      data = run_query(conn, sql)

      write_to_datafile(data, datafile, datatable, true, true)

    rescue Exception => e
      puts e.message
    end
  end

  ################### PRIVATE ###################
  def run_query(conn, sql)
    dt = nil
    begin

      #Data Source=c:\mydb.db;Version=3; => SQLITE

      if conn.to_s.downcase.index('version=') != nil
        dt = ConnectToSqlite.new
        conn = process_sqlite_conn(conn)
      else
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

  def write_to_datafile(data, datatable, datafile, clean_data, drop_table)
    begin
      if datatable == ''
        datatable = datafile
      end

      unless datafile.to_s.index('.db')
        datafile = datafile + '.db'
      end

      # adds the datafile default path
      datafile = db_path.to_s.strip.end_with?('\\') ? db_path + datafile : db_path + '\\' + datafile

      write = WriteToSqlite.new(datafile, datatable, data.columns, data.rows)

      if drop_table.equal?(true)
        write.drop_table
      elsif clean_data.equal?(true)
        write.clean_data
      end

      write.create_table
      write.insert_data
    rescue Exception => e
      throw 'error writing to datafile: ' + e.message
    end
  end

  def process_sqlite_conn(conn)
    list_conn_params = conn.to_s.split(';')

    list_conn_params.each do |conn_op|
      if conn_op.to_s.downcase.index('source=')
        return conn_op[conn_op.index('=')+1..conn_op.length]
      end
    end

    ''
  end

  private :process_sqlite_conn,
          :run_query,
          :write_to_datafile
end



store = StoreData.new('C:\Users\xyon\Desktop\GitHub\sql_to_datafile\code\class','','','')
store.store_queries('Data Source=configs.db;Version=3;', 'select 10 as nelson, 12 as antunes', 'demo_nelson', 'demo_nelson')

