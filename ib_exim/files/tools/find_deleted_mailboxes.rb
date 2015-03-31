#!/bin/env ruby
require 'rubygems'
# try and catch around EL5
begin
  require 'pg'
rescue LoadError
  require 'postgres'
end

class FindDeletedMailboxes
  def self.find_deleted
    require File.join(File.dirname(__FILE__),File.basename(__FILE__,'.rb')+'.config.rb')
    FindDeletedMailboxes.new.find
  end

  def find
    wrongdirs = []
    local_dirs.each do |dir|
      unless invalid?(dir) then
        if valid?(dir) then
          wrongdirs << dir unless mailboxes.include?(mailaddr(dir))
        else
          wrongdirs << dir
        end
      end
    end
    unless wrongdirs.empty?
      if ARGV.shift == '--purge'
        purge(wrongdirs)
      else
        mail(wrongdirs)
      end
    end
  end

  private
  def conn
    @conn ||= PGconn.connect(Options::DBHOST, 5432, "","",Options::DB, Options::DBUSER,Options::DBPWD)
  end

  def mailboxes
    @mailboxes ||= begin
      res = conn.exec("SELECT alias||'@'||domain FROM email_users WHERE ismailbox = 1 AND deleted_at IS NULL AND storagehost LIKE '#{Options::HOST}'")
      (res.respond_to?(:values) ? res.values : res.result).flatten
    end
  end

  def local_dirs
    Dir[File.join(Options::MAIL_STORAGE,'*')]
  end

  def invalid?(dir)
   # filter here directories
   false
  end

  def valid?(dir)
    File.directory?(dir) and dir.include?('@')
  end

  def mailaddr(dir)
    dir.gsub(File.dirname(dir)+'/','')
  end

  def mail(dirs)
    puts "Hi"
    puts
    puts "This is your friendly #{$0} script speaking. I'm checking your mailstorage on existing mailboxes which seem to be deleted from the system. Please have a look at the following mailboxes and clean them up! Thanks!"
    puts
    puts dirs.join("\n")
    puts
    puts "If your are sure about removing these mailboxes you can clean them up, by running #{$0} --purge"
  end

  def purge(dirs)
    puts "I'm going to delete the following directories:"
    puts
    puts dirs.join("\n")
    puts
    puts "Are your really sure that you want to delete them? (y/n)"
    if gets.chomp == 'y'
      require 'fileutils'
      dirs.each{|d| `find #{d} -type f -exec shred -n 1 -u '{}' \\;`; FileUtils.remove_entry_secure(d) }
      puts "Done!"
    else
      puts "Won't do anything!"
    end
  end
end

FindDeletedMailboxes.find_deleted
