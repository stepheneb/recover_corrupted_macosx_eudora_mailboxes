#!/usr/bin/env ruby

if ARGV.empty?
  MAILBOXES_PATH = "/Users/stephen/Documents/Eudora\ Folder/Mail\ Folder/"
else
  MAILBOXES_PATH = ARGV[0]
end

LARGE_NUMBER = 25000
MESSAGE_REGEX = '^From \?\?\?\@\?\?\?[[:space:]]+\w+[[:space:]]+\w+[[:space:]]+[0-9]+[[:space:]]+[0-9]+:[0-9]+:[0-9]+[[:space:]]+[0-9]{4}$'

MAILBOX_FORMAT_STR = "  %6u  %8u    %-18s"
LARGE_MAILBOX_FORMAT_STR = "  %8u      %-18s"

mailboxes = []
index = 1
Dir.chdir(MAILBOXES_PATH) do
  mailbox_files = Dir["**/*"].select { |f| !File.stat(f).directory? }
  puts
  puts "processing: #{mailbox_files.length} mailboxes in path: #{MAILBOXES_PATH} ..."
  puts
  puts "    count   messages  path"
  puts "-----------------------------------------------"
  mailboxes = mailbox_files.collect do |mb|
    cmd = "iconv -c -t utf-8 '#{mb}' | LC_ALL=C tr '\r' '\n' | egrep -c '#{MESSAGE_REGEX}'"
    messages = `#{cmd}`.strip.to_i
    puts sprintf(MAILBOX_FORMAT_STR, index, messages, mb)
    index += 1
    [mb, messages]
  end
end

large_mailboxes = mailboxes.select { |mb| mb[1] > LARGE_NUMBER }.sort { | mb1, mb2| mb1[1] <=> mb2[1] }
puts
puts "#{large_mailboxes.length} mailbox files with more than #{LARGE_NUMBER} messages ..."
puts
puts "    messages    path"
puts "-----------------------------------------------"
large_mailboxes.each do |mb|
  puts sprintf(LARGE_MAILBOX_FORMAT_STR, mb[1], mb[0])
end
puts