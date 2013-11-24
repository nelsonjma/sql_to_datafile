require 'rubygems'
require 'win32ole'
require 'sqlite3'

conn = WIN32OLE.new('ADODB.Connection')
conn.Open('Provider=SQLOLEDB;Data Source=TJPSFA44,1433;Initial Catalog=portal;Integrated Security=SSPI;')

recordset =  WIN32OLE.new('ADODB.Recordset')
recordset.Open("select top 100000 * from viewitemvenda " , conn)


###################################################################
#recordset.Fields.each do |field|
#  puts field.name
#end

dataset = recordset.GetRows
recordset.Close

###################################################################
dataset = dataset.transpose
#dataset.each do |row|
#  row.each do |cell|
#    print cell.to_s + ' | '
#  end
#  print "\n"
#end

###################################################################
# add to sqlite database
###################################################################

db = SQLite3::Database.open 'db_tmp.db'

table_name = 'viewitemvenda'

# drop table
db.execute 'drop table if exists ' + table_name

###################################################################
# create table
###################################################################
create_tb_cmd = 'create table ' + table_name + '('

a = 0
recordset.Fields.each do |field|
  create_tb_cmd += ',' if a > 0
  create_tb_cmd += field.name + ' TEXT '

  a = a + 1
end

create_tb_cmd += ')'

puts 'create table ' + create_tb_cmd

db.execute create_tb_cmd
###################################################################
###################################################################

###################################################################
# add data to table
###################################################################

starttime = Time.now

puts 'inserting data'

# transaction ctrl
transaction_count = 0

case dataset.count
  when 0..1000
    commit_rows = dataset.count / 2
  when 1000..100000
    commit_rows = dataset.count / 4
  else
    commit_rows = 25000
end


dataset.each do |row|

  if transaction_count == 0 && !db.transaction_active?
    db.transaction
  elsif transaction_count >= commit_rows && db.transaction_active?
    db.commit
    transaction_count = -1
    puts 'commit'
  end

  c=0
  insert_to_tb = 'INSERT INTO ' + table_name + ' VALUES ('

  row.each do |cell|
    insert_to_tb += ',' if c > 0
    insert_to_tb +=  "'"  + (cell.to_s.index("'") != nil ? cell.to_s.gsub("'", ' ') : cell.to_s) + "'"

    c = c + 1
  end

  insert_to_tb += ')'
  db.execute insert_to_tb

  transaction_count = transaction_count + 1
end

# end last transaction
if db.transaction_active?
  db.commit
  puts 'commit'
end

puts 'start time: ' + starttime.to_s
puts 'end time: ' + Time.now.to_s

# 2 colunas - sem transções 10000 rows...
#start time: 2013-11-13 16:28:13 +0000
#end time: 2013-11-13 16:47:31 +0000

# 2 colunas - com transações 10000 rows / commit 1.000 rows...
#start time: 2013-11-13 17:18:30 +0000
#end time: 2013-11-13 17:18:33 +0000
# 3

# 2 colunas - com transações 100000 rows / commit 1.000 rows...
#start time: 2013-11-13 17:21:34 +0000
#end time: 2013-11-13 17:22:05 +0000
# 31s

# 2 colunas - com transações 100000 rows / commit 10.000 rows...
#start time: 2013-11-13 17:22:42 +0000
#end time: 2013-11-13 17:22:49 +0000
# 7

# 2 colunas - com transações 100000 rows / commit 20.000 rows...
#start time: 2013-11-13 17:23:43 +0000
#end time: 2013-11-13 17:23:48 +0000
# 7

# 2 colunas - com transações 100000 rows / commit 50.000 rows...
#start time: 2013-11-13 17:24:34 +0000
#end time: 2013-11-13 17:24:39 +0000
# 5s

# select * from viewitemvenda - com transações 10000 rows / commit 1.000 rows...
#start time: 2013-11-13 17:48:12 +0000
#end time: 2013-11-13 17:48:21 +0000
# 8s

# select * from viewitemvenda - com transações 100000 rows / commit 10000 rows...
#start time: 2013-11-13 18:00:56 +0000
#end time: 2013-11-13 18:04:16 +0000
# 260s


# select * from viewitemvenda - com transações 100000 rows / commit 25000 rows...
#start time: 2013-11-13 18:09:23 +0000
#end time: 2013-11-13 18:12:35 +0000
# 242s

# select * from viewitemvenda - com transações 100000 rows / commit 25000 rows...
#start time: 2013-11-13 18:27:39 +0000
#end time: 2013-11-13 18:30:36 +0000
# 227s