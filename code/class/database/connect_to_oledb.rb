require 'rubygems'
require 'win32ole'

load 'database/datatable.rb'

class ConnectToOleDb
  attr_accessor :conn

  def initialize
    @conn = nil
  end

  def open(conn_str)
    begin
      @conn = WIN32OLE.new('ADODB.Connection')
      @conn.Open(conn_str)
    rescue Exception => e
      @conn = nil
      throw 'error connecting to database: ' + e.message
    end
  end

  def close
    begin
      @conn.Close if @conn != nil
    rescue Exception => e
      throw 'error closing connection: ' + e.message
    end
  end

  # return DataTable Class
  def get_data(sql)
    begin
      # if connection not open then leave
      return DataTable.new if @conn == nil

      recordset =  WIN32OLE.new('ADODB.Recordset')
      recordset.Open(sql, @conn)

      dt = DataTable.new
      dt.rows = (recordset.GetRows).transpose

      dt.columns = []
      recordset.Fields.each {|c| dt.columns.push(c.name)}

      return dt
    rescue Exception => e
      throw 'error running query:' + e.message
    end
  end

end
