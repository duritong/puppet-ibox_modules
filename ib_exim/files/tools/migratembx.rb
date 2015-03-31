#!/bin/env ruby

require 'singleton'
require 'benchmark'
require 'fileutils'
require 'rubygems'
# try and catch around EL5
begin
  require 'pg'
rescue LoadError
  require 'postgres'
end
require File.join(File.dirname(__FILE__),File.basename(__FILE__,'.rb')+'.config.rb')

class Db
  include Singleton
  def self.exec(query)
    Db.instance.connection.exec(query)
  end

  def connection
    @connection ||= PGconn.connect(Options::DB_HOST, 5432, "","",Options::DB, Options::DB_USER,Options::DB_PWD)
  end
end

class MigrateMailbox
  def self.migrate(mailbox,progress=false,debug=false,oldmbx=false)
    unless MigrateMailbox.new(mailbox,progress,debug,oldmbx).migrate!
      puts "Can't migrate #{mailbox} please investigate!"
    end
  end

  def initialize(mailbox,debug=false,progress=false,oldmbx=false)
    @mailbox = mailbox
    @debug = debug
    @progress = progress
    @oldmbx = oldmbx
  end

  def migrate!
    return unless src_host=check_migrate
    lock2migrate
    unless exitcode=copy_mbox(src_host)
      puts "#{@mailbox} successfully migrated. Unlocking..."
      unlock 
    else
      puts "Something went wrong while migrating #{@mailbox}! Exitcode: #{exitcode} . Please have a look at it!"
    end
    true
  end

  private
  def copy_mbox(src_host)
    print "Syncing #{@mailbox} from #{src_host} " if debug?
    FileUtils.mkdir_p(target_dir) if oldmbx?
    puts rsync_command(src_host) if progress?
    #return nil
    time = Benchmark.measure { system rsync_command(src_host) }
    puts "=> "+time.to_s if debug?
    exitstatus = $?.exitstatus
    ensure_filemod
    return_code(exitstatus)
  end

  def ensure_filemod
    @oldmbx = false
    FileUtils.chown_R(uid,'mail',target_dir)
    system "/bin/chmod -R og-rwx #{target_dir}"
  end

  def rsync_command(src_host)
    "/usr/bin/rsync -e \"ssh #{Options::RSYNC_SSH_OPTIONS}\" #{Options::RSYNC_OPTIONS} root@#{src_host}:#{@mailbox}/ #{oldmbx? ? File.join(target_dir,'mail') : target_dir} #{"--progress -v" if progress?} 2>&1 | (egrep -v \"#{Options::IGNORE_OUTPUT}\" || true)"
  end

  def return_code(exit_code)
    return exit_code unless exit_code == 0 or exit_code == Options::IGNORE_EXITCODE
    nil
  end

  def lock2migrate
    Db.exec("UPDATE #{Options::DB_TABLE} SET #{Options::DB_MIGRATE_TIME_FIELD} = now() WHERE alias||'@'||domain = '#{@mailbox}';")
  end

  def unlock
    Db.exec("UPDATE #{Options::DB_TABLE} SET #{Options::DB_MIGRATE_TIME_FIELD} = NULL, #{Options::DB_STORAGEHOST_FIELD} = '#{Options::HOST}', #{Options::DB_MIGRATE_FIELD} = NULL WHERE alias||'@'||domain = '#{@mailbox}';")
  end

  def check_migrate
    res = Db.exec("SELECT #{Options::DB_STORAGEHOST_FIELD} FROM #{Options::DB_TABLE} WHERE alias||'@'||domain = '#{@mailbox}' AND #{Options::DB_MIGRATE_TIME_FIELD} IS NULL;")
    (res.respond_to?(:values) ? res.values : res.result).flatten.first
  end

  def uid
    @uid ||= begin
      res = Db.exec("SELECT #{Options::DB_UID_FIELD} FROM #{Options::DB_TABLE} WHERE alias||'@'||domain = '#{@mailbox}';")
      (res.respond_to?(:values) ? res.values : res.result).flatten.first
    end
  end

  def debug?
    @debug
  end

  def progress?
    @progress
  end

  def oldmbx?
    @oldmbx
  end

  def target_dir
    return File.join(Options::DEFAULT_PATH,@mailbox)
  end
end

class Migrate
  def self.migrate_mailboxes(progress=false,debug=false)
    Migrate.new.migrate_mbxs(progress,debug)
  end

  def migrate_mbxs(progress=false,debug=false)
    mbx2migrate.each { |mailbox| MigrateMailbox.migrate(mailbox,progress,debug) }
  end

  def mbx2migrate
    res = Db.exec("SELECT alias||'@'||domain FROM #{Options::DB_TABLE} WHERE #{Options::DB_MIGRATE_FIELD} LIKE '#{Options::HOST}' AND #{Options::DB_MIGRATE_TIME_FIELD} IS NULL;")
    (res.respond_to?(:values) ? res.values : res.result).flatten
  end
end

if __FILE__ == $0
  Migrate.migrate_mailboxes(ARGV.include?('--progress'),ARGV.include?('--debug'))
end
