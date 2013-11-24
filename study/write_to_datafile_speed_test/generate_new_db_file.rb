require 'rubygems'
require 'sqlite3'

db = SQLite3::Database.open 'demo.db'

db.execute 'CREATE TABLE IF NOT EXISTS Cars(Id INTEGER PRIMARY KEY, Name TEXT, Price INT)'