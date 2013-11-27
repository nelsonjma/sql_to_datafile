require 'rubygems'
require 'sqlite3'

class WriteToSqlite
  attr_accessor :db, :table_name, :columns, :rows, :insert_header

  def initialize(db_path, columns, rows)
    @db = nil
    @columns = columns
    @rows = rows

    connect(db_path)
  end

  ################## PRIVATE ##################
  def connect(path)
    begin
      @db = SQLite3::Database.open path
    rescue Exception => e
      throw 'error connection to database: ' + e.message
    end
  end

  def set_transaction_interval(row_count)
    case row_count
      when 0..1000
        return row_count / 2
      when 1000..100000
        return row_count / 4
      else
        return 25000
    end
  end

  def check_transaction_status(commit_rows, transaction_count)
    if transaction_count == 0 && !@db.transaction_active?
      @db.transaction
    elsif transaction_count >= commit_rows && @db.transaction_active?
      @db.commit
      return -1
    end

    transaction_count
  end

  def build_insert_script(row)
    insert_to_tb = 'INSERT INTO ' + @table_name + ' (' + @insert_header + ') VALUES ('

    c = 0
    row.each do |cell|
      value = cell

      begin
        if cell.count == 2
          value = cell[1]
        end
      end

      insert_to_tb += ',' if c > 0
      insert_to_tb +=  "'"  + (value.to_s.index("'") != nil ? value.to_s.gsub("'", ' ') : value.to_s) + "'"

      c = c + 1
    end

    insert_to_tb += ')'

    return insert_to_tb
  end

  def build_create_table_script(columns)
    table_script = 'CREATE TABLE IF NOT EXISTS ' + @table_name + ' ('

    a = 0

    columns.each do |field|
      table_script += ',' if a > 0

      begin
        table_script += field.name + ' TEXT '
      rescue
        table_script += field + ' TEXT '
      end


      a = a + 1
    end

    table_script += ')'

    return table_script
  end

  def build_insert_header
    @insert_header = ''

    a = 0
    @columns.each do |field|
      @insert_header += ',' if a > 0
      begin
        @insert_header += field.name
      rescue
        @insert_header += field
      end
      a = a + 1
    end

  end

  ################## PUBLIC ##################
  def clean_data
    if @db == nil
      return -1
    end

    begin
      @db.execute 'DELETE FROM ' + @table_name
    rescue Exception => e
      throw e.message
    end
  end

  def create_table
    if @db == nil
      return -1
    end

    begin
      @db.execute build_create_table_script(@columns)
    rescue Exception => e
      throw e.message
    end
  end

  def drop_table
    if @db == nil
      return -1
    end

    begin
      @db.execute 'DROP TABLE IF EXISTS ' + @table_name
    rescue Exception => e
      throw e.message
    end
  end

  def insert_data
    begin
      commit_rows = set_transaction_interval(@rows.count)
      transaction_count = 0

      build_insert_header

      @rows.each do |row|
        begin
          transaction_count = check_transaction_status(commit_rows, transaction_count)

          @db.execute build_insert_script(row)

          transaction_count = transaction_count + 1
        rescue Exception => e
          puts 'error doing insert: ' + e.message
        end
      end

      @db.commit if @db.transaction_active?
    rescue Exception => e
      throw 'error writing data to table  ' + e.message
    end
  end

  def change_name(old, new)
    if @db == nil
      return -1
    end

    begin
      @db.execute 'ALTER TABLE ' + old + ' RENAME TO ' + new
    rescue Exception => e
      throw e.message
    end
  end

  def copy_table_structure(original, copy)
    if @db == nil
      return -1
    end

    begin
      @db.execute 'CREATE TABLE ' + copy + ' AS SELECT * FROM ' + original + ' WHERE 0'
    rescue Exception => e
      throw e.message
    end
  end

  private :connect,
          :set_transaction_interval,
          :check_transaction_status,
          :build_insert_script,
          :build_create_table_script,
          :build_insert_header
end



