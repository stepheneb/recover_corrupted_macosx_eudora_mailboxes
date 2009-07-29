#!/usr/bin/env ruby

require 'fileutils'

def find_unused_name(dir, filename, suffix='')
  if suffix.empty?
    suffix = '-2'
  else
    suffix = "-#{suffix}"
  end
  unless File.exists?("#{dir}/#{filename}#{suffix}")
    "#{dir}/#{filename}#{suffix}"
  else
    i = 2
    while File.exists?("#{dir}/#{filename}#{suffix}#{i}")
      i = i + 1
    end
    "#{dir}/#{filename}#{suffix}#{i}"
  end
end

def files_exist_and_same_length(file1, file2)
  File.exists?(file1) && File.exists?(file2) && (File.stat(file1).size == File.stat(file2).size)
end

def get_macos_file_creator(path)
  `GetFileInfo -c #{path}`.strip.gsub('"', '')
end

def get_macos_file_type(path)
  `GetFileInfo -t #{path}`.strip.gsub('"', '')
end

def eudora_mailbox_file?(path)
  get_macos_file_creator(path) == 'CSOm' && get_macos_file_type(path) == 'TEXT'
end

def set_eudora_file_type_attributes(dir, mailbox)
  Dir.chdir(dir) do
    `SetFile -t TEXT -c CSOm #{mailbox}`
  end
end

def recover_eduora_mailbox_file(mailbox_path)
  raise "File: '#{mailbox_path}' doesn't exist" unless File.exists?(mailbox_path)
  raise "File: ''#{mailbox_path}' is not a Eudora mailbox file" unless eudora_mailbox_file?(mailbox_path)

  mailbox_dir = File.dirname(mailbox_path)
  mailbox = File.basename(mailbox_path)

  mailbox_backup = find_unused_name(mailbox_dir, mailbox, 'backup')
  backup_mailbox_path = "#{mailbox_dir}/#{mailbox_backup}"

  puts "Making backup copy of #{mailbox} to #{mailbox_backup}."
  FileUtils.cp mailbox_path, backup_mailbox_path
  set_eudora_file_type_attributes(mailbox_dir, mailbox_backup)
  
  raise "Problem backing up: #{mailbox}" unless files_exist_and_same_length(mailbox_path, backup_mailbox_path)
  
  mbx = File.read(backup_mailbox_path)
  mbx_messages = mbx.split('From ???@??? ')
  mbx_messages.shift

  new_mailbox = find_unused_name(mailbox_dir, mailbox)
  new_mailbox_path = "#{mailbox_dir}/#{new_mailbox}"


  puts "Reading #{mbx_messages.length} messages from original Eudora mailbox: #{mailbox}."
  puts "Writing into new Eudora mailbox: #{new_mailbox}."

  File.open(new_mailbox_path, 'w') {|f| mbx_messages.each {|m| f.write "From ???@??? #{m}" } }
  
  set_eudora_file_type_attributes(mailbox_dir, new_mailbox)

  puts "Replacing original Eudora mailbox: #{mailbox} with: #{new_mailbox}."
  
  FileUtils.mv new_mailbox_path, mailbox_path

  puts "A copy of the original Eudora mailbox: #{mailbox} is now named: #{mailbox_backup}."
  
end

ARGV.each do |mailbox_path|
  recover_eduora_mailbox_file(mailbox_path)
end