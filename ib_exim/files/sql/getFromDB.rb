#!/usr/bin/ruby
require 'rubygems'
# try and catch around EL5
begin
  require 'pg'
rescue LoadError
  require 'postgres'
end

load "/etc/exim/sql/getFromDB.config.rb"

conn = PGconn.connect($host, 5432, "","",$db, $user,$pw)

$sql1 = "SELECT DISTINCT Domain,'      ',IsCatchAll,IsDomainAlias FROM email_domains ORDER by Domain"
res = conn.exec($sql1)
(res.respond_to?(:values) ? res.values : res).each{|row| puts row.join('') }

