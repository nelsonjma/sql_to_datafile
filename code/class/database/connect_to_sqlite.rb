require 'rubygems'
require 'sqlite3'

load File.dirname(__FILE__) + '/datatable.rb'


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
