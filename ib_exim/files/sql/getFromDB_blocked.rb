#!/usr/bin/ruby

require 'rubygems'
# try and catch around EL5
begin
  require 'pg'
rescue LoadError
  require 'postgres'
end


load '/etc/exim/sql/getFromDB.config.rb'

conn = PGconn.connect($host, 5432, "","",$db, $user,$pw)

# tODO: implement relaying
$sql1 = "SELECT DISTINCT address,'      ','1' FROM blocked_addresses ORDER by address"
res = conn.exec($sql1)
(res.respond_to?(:values) ? res.values : res).each{|row| puts row.join('') }
