#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-
require 'open-uri'
require 'json'
require 'digest/md5'
require 'yaml'
require 'json'
require 'daemon_spawn'
require 'redis'

class Reporter < DaemonSpawn::Base
  def start(args)
    puts "start : #{Time.now}"

    config = YAML.load_file(File.expand_path(File.dirname(__FILE__) + '/../redis-config.yml'))
    redis = Redis.new(
      :host=>config['HOST'],
      :port=>config['PORT'],
      :password=>config['PASSWORD'])

      loop do
        span = 60

        if ((Time.now.sec % span) == 0)
          begin
            t = Time.now.to_i
            url_list = redis.smembers("track_url")
            url_list.each do |url|
              req_uri = URI.parse("http://graph.facebook.com/" + url)
              contents = JSON.parse(req_uri.read)
              k = t.to_s + "_" + Digest::MD5.hexdigest(url)
              if contents.key?("shares") then
                v = contents["shares"].to_s
              elsif contents.key?("likes") then
                v = contents["likes"].to_s
              else
                v = 0
              end
              redis.set(k,v)
              redis.expire( t, 259200)
              puts k +  " => " + v
            end
            sleep 1
          rescue => e
            puts Time.now.to_s + ": " + e.message
          end
        else
          sleep 1
        end
      end 
  end 

  def stop
    puts "stop  : #{Time.now}"
  end 
end


base_path = File.dirname(__FILE__)
work_dir = File.expand_path(base_path + '/work')
tmp_dir = File.expand_path(base_path + '/tmp')
log_dir = File.expand_path(base_path + '/log')

FileUtils.mkdir_p(work_dir) unless FileTest.exist?(work_dir)
FileUtils.mkdir_p(tmp_dir) unless FileTest.exist?(tmp_dir)
FileUtils.mkdir_p(log_dir) unless FileTest.exist?(log_dir)

Reporter.spawn!({
  :working_dir => work_dir,
  :pid_file => tmp_dir + '/FB_Reporter.pid',
  :log_file => log_dir + '/FB_Reporter.log',
  :sync_log => true,
  :singleton => true
}) 
