#!/usr/bin/ruby
require 'rubygems'
require 'pg'
require 'singleton'

class DovecotExpire
  include Singleton
  def run
    mailboxes.each do |mb|
      system("bash -c 'for i in Trash Papierkorb spam Spam Junk; do doveadm expunge -u #{mb} $i savedbefore 14d ; done'")
      if $?.to_i > 0
        STDERR.puts "There was an error while expunging #{mb}"
        exit 1
      end
    end
  end

  private
  def conn
    @conn ||= PGconn.connect(config['dbhost'], 5432, "","",config['dbname'], config['dbuser'],config['dbpwd'])
  end

  def mailboxes
    @mailboxes ||= begin
      res = conn.exec("SELECT alias||domain as email FROM email_users WHERE ismailbox = 1 AND deleted_at IS NULL AND storagehost = '#{config['fqdn']}'")
      (res.respond_to?(:values) ? res.values : res.result).flatten
    end
  end
  def config
    @config ||= begin
      f = File.symlink?(__FILE__) ? File.readlink(__FILE__) : __FILE__
      require 'yaml'
      YAML.load_file(File.join(File.dirname(f),File.basename(f,'.rb')+'.config.yaml'))
    end
  end
end

DovecotExpire.instance.run
