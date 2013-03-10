#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-
require 'yaml'
require 'daemon_spawn'
require 'redis'

class Reporter < DaemonSpawn::Base
  def start(args)
    puts "start : #{Time.now}"

	config = YAML.load_file(File.expand_path(File.dirname(__FILE__) + '/../config.yml'))
	redis = Redis.new(
		:host=>config['HOST'],
		:port=>config['PORT'],
		:password=>config['PASSWORD'])

    loop do
        t = Time.now.to_i
        loadavg = `uptime`
		redis.set( t, loadavg.split()[7] )
		redis.expire( t, 14400)
        sleep 1
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
    :pid_file => tmp_dir + '/Reporter.pid',
    :log_file => log_dir + '/Reporter.log',
    :sync_log => true,
    :singleton => true
  }) 
