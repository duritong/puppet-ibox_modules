#!/usr/bin/ruby
require 'rubygems'
require 'pg'
require 'singleton'

class GenerateLocalMailUsers
  include Singleton
  def run(verbose=false)
    f = File.symlink?(__FILE__) ? File.readlink(__FILE__) : __FILE__
    require File.join(File.dirname(f),File.basename(f,'.rb')+'.config.rb')
    system "rkhunter --enable passwd_changes --skip-keypress --nocolors --report-warnings-only"
    if $?.to_i > 0
      puts "There was an unreported rkhunter warning, I don't continue creating local mail users! Further infos have been mailed to you!"
      exit 1
    end
    system "echo '#{gen_str}' | puppet apply --no-report --color false --detailed-exitcodes #{'--logdest /dev/null' unless verbose}"
    if $?.to_i > 0
      puts "Something changed... Running rkhunter..." if verbose
      system "rkhunter --enable passwd_changes --skip-keypress --nocolors --no-mail-on-warning #{verbose ? '--report-warnings-only' : '--quiet'}"
    end
  end

  private
  def conn
    @conn ||= PGconn.connect(Options::DBHOST, 5432, "","",Options::DB, Options::DBUSER,Options::DBPWD)
  end

  def uids
    @uids ||= begin
      res = conn.exec("SELECT uid FROM email_users WHERE ismailbox = 1 AND deleted_at IS NULL AND storagehost LIKE '#{Options::HOST}'")
      (res.respond_to?(:values) ? res.values : res.result).flatten
    end
  end

  def gen_str
  <<-END
resources{"user": purge => true , unless_system_user => "39999" }

define mail_user(){
  user{"u${name}":
    uid        => $name,
    gid        => 12,
    home       => '/dev/null',
    allowdupe  => false,
    comment    => "Local Mailuser for mailbox with uid ${name}",
    managehome => false,
    shell      => '/sbin/nologin',
  }
}

mail_user{["#{uids.join("\", \"")}"]: }
END
  end
end

GenerateLocalMailUsers.instance.run(ARGV.size > 0)
