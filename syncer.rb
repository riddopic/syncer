#!/usr/bin/env ruby
#
# Copyright 2012, Stefano Harding
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'fileutils'
require 'timeout'
require 'resolv'
require 'syslog'
require 'socket'
require 'thread'

DOT_FILE = ENV['HOME'] + "/.syncer"

begin
  eval(IO.read(DOT_FILE)) if File.exist?(DOT_FILE)
rescue Exception => e
  puts "There was a problem loading your syncer dot file."
end

rsync_opts = '-ahvhz --progress --partial --delete-after'

# Check if we are already running, exit if we are. This is done to avoid the
# script launching more than once.
def port_lock
  Thread.new do
    begin
      server = TCPServer.new('127.0.0.1', 17553)
      server.accept
    rescue
      raise("Someone's already bound to our port. We're outta here.")
    end
  end
  sleep(1)
end

def log message
  Syslog.open($PROGRAM_NAME, Syslog::LOG_PID | Syslog::LOG_CONS) { |s| s.warning message }
end

# Check if the host is responding.
def port_open? host, port
  begin
    Timeout::timeout(1) do
      begin
        s = TCPSocket.new(host, port)
        s.close
        return true
      rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
        return false
      end
    end
  rescue Timeout::Error
  end
  return false
end

# Display time in 1d 2h 10m 15s
def display_time total_seconds
  total_seconds = total_seconds.to_i
  days = total_seconds / 86400
  hours = (total_seconds / 3600) - (days * 24)
  minutes = (total_seconds / 60) - (hours * 60) - (days * 1440)
  seconds = total_seconds % 60
  display = ''
  display_concat = ''
  if days > 0
    display = display + display_concat + "#{days}d"
    display_concat = ' '
  end
  if hours > 0 || display.length > 0
    display = display + display_concat + "#{hours}h"
    display_concat = ' '
  end
  if minutes > 0 || display.length > 0
    display = display + display_concat + "#{minutes}m"
    display_concat = ' '
  end
  display = display + display_concat + "#{seconds}s"
  display
end

port_lock
log "Started running at: #{Time.now}"
begining = Time.now

@repos.each do |k,v|
  begin
    source = @repos[k.to_sym][:source]
    target = @repos[k.to_sym][:target]
    if source =~ /^rsync/
      host, port = source.split(/\//)[2], 873
    else
      host, port = source.split(":")[0], 22
    end
    raise "Unable to connect to remote host #{source}" unless port_open?(host, port)
    FileUtils.mkdir(target) if !File.directory?(target)
    log "rsync #{rsync_opts} #{source} #{target}"
    `rsync #{rsync_opts} #{source} #{target}`
  rescue Errno::EACCES, Errno::ENOENT, Errno::ENOTEMPTY, Exception => e
    log e.to_s
  end
end

log "Finished running at: #{Time.now} - Execution time: #{display_time(Time.now - begining)}"

# vi:filetype=ruby:tabstop=2:expandtab
