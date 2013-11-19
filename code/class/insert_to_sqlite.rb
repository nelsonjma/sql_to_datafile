require 'rubygems'
require 'sqlite3'

class InsertToSqlite
  attr_accessor :db, :table_name, :columns, :rows

  def initialize(db_path, table_name, columns, rows)
    @db = nil
    @table_name = table_name
    @columns = columns
    @rows = rows

    connect(db_path)
  end

  ################## PRIVATE ##################
  def connect(path)
    begin
      @db = SQLite3::Database.open path
    rescue Exception => e
      puts 'error connection to database: ' + e.message
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
    insert_to_tb = 'INSERT INTO ' + @table_name + ' ('

    a = 0
    @columns.each do |field|
      insert_to_tb += ',' if a > 0
      begin
        insert_to_tb += field.name
      rescue
        insert_to_tb += field
      end
      a = a + 1
    end

    insert_to_tb += ') VALUES ('

    c = 0
    row.each do |cell|
      insert_to_tb += ',' if c > 0
      insert_to_tb +=  "'"  + (cell.to_s.index("'") != nil ? cell.to_s.gsub("'", ' ') : cell.to_s) + "'"

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

  ################## PUBLIC ##################
  def create_table
    if @db == nil
      return -1
    end

    begin
      @db.execute build_create_table_script(@columns)
    rescue Exception => e
      puts e.message
    end
  end

  def drop_table
    if @db == nil
      return -1
    end

    begin
      @db.execute 'DROP TABLE ' + @table_name
    rescue Exception => e
      puts e.message
    end
  end

  def insert_data
    begin
      commit_rows = set_transaction_interval(@rows.count)
      transaction_count = 0

      @rows.each do |row|
        begin
          transaction_count = check_transaction_status(commit_rows, transaction_count)

          @db.execute build_insert_script(row)

          transaction_count = transaction_count + 1
        rescue Exception => e
          puts 'error doing insert: ' + e.message
        end
      end
    rescue Exception => e
      puts 'error writing data to table  ' + e.message
    end
  end

  private :connect,
          :set_transaction_interval,
          :check_transaction_status,
          :build_insert_script,
          :build_create_table_script

end



