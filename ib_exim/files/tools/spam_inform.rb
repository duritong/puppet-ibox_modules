#!/bin/env ruby
require 'rubygems'
require 'yaml'
require 'maildir'

require 'maildir/serializer/mail'
Maildir::Message.serializer = Maildir::Serializer::Mail.new

class Mailbox < Struct.new(:mailaddr)
  def spammails?
    spamfolder? && !mails.empty?
  end
  def print_mails
    header = pretty_table_row
    [header,header.gsub(/./, '-'), mails.collect do |mail|
      begin
        pretty_table_row(mail.data)
      rescue
        sprintf('%0-71s','| An error occured while parsing this email!')+'|'
      end
    end,header.gsub(/./, '-')].flatten.join("\n")
  end

  private
  def spamfolder?
    File.directory?(spamfolder)
  end
  def mails
    @mails ||= maildir.list(:cur)
  end
  def maildir
    unless @maildir
      @maildir = Maildir.new(spamfolder,false)
      maildir.list(:new).each { |message| message.process }
    end
    @maildir
  end

  def spamfolder
    @spamfolder ||= File.join('/e','mails',self[:mailaddr],'mail','.spam')
  end

  def pretty_table_row(obj = nil)
    '| ' + fields.collect do |field|
      sprintf("%0-#{field_sizes[field]}s", (obj ? Mail::Encodings.unquote_and_convert_to((obj[field].try(:value)||''),'utf-8') : field).to_s.first(field_sizes[field]) )
    end.join(' | ') + ' |'
  end

  def field_sizes
    @field_sizes ||= {'From' => 19, 'Subject' => 17, 'Date' => 11, 'X-SPAM-SCORE' => 12 }
  end
  def fields
    @fields ||= ['From', 'Subject', 'Date', 'X-SPAM-SCORE']
  end

end

class SpamMailScanner
  include Singleton

  def run(mode=:mail)
    scan.each{ |mailbox| inform(mailbox,mode) if mailbox.spammails? }
  end

  private

  def inform(mailbox,mode)
    puts "Parsing: #{mailbox.mailaddr}" unless mode == :mail
    content = "#{config['header']}

#{mailbox.print_mails}

#{config['footer']}
"
    if mode == :mail
      mail = Mail.new
      # we are sending the mail locally so no need for tls
      mail.delivery_method.settings[:enable_starttls_auto] = false
      mail.from     = config['from']
      mail.to       = mailbox.mailaddr
      mail.charset  = 'UTF-8'
      mail.subject  = config['subject']
      mail.body     = content
      mail.content_transfer_encoding = '8bit'
      mail.deliver
    else
      puts "To: #{mailbox.mailaddr}"
      puts content
    end
  end

  def scan
    Dir[File.join(config['maildir']},'*')].collect{ |mb| gen_mailbox(mb) }.compact
  end

  def gen_mailbox(mailfolder)
    Mailbox.new(File.basename(mailfolder))
  end

  def config
    @config ||= YAML.load_file(File.join(File.dirname(__FILE__),
      "#{File.basename(__FILE__,'.rb')}.yaml"))
  end
end

SpamMailScanner.instance.run(ARGV.first||:mail)
