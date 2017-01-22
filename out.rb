#!/usr/bin/env ruby

require 'rubygems'
require 'bundler/setup'
require 'json'
require File.expand_path('../lib', __FILE__)

@logger = Logger.new('captain-hook.log', 'daily')
@logger.level = Logger::INFO
@logger.datetime_format = '%Y-%m-%d %H:%M:%S'
hook = Hook.new
hook.are_we_running?

@logger.info('In the forked process')
photo_paths = hook.get_photo_paths

if photo_paths.empty?
  @logger.info('Nothing to process, exiting')
  exit
end

photo_paths.each do |photo|
  @logger.info("#{photo}")
  hook.extract_parts(photo)

  hook.download(photo)
  hook.delete(photo)
  hook.create_thumbnail(photo)
  hook.copy_to_s3(photo)
  hook.delete_temp_files(photo)
  hook.add_photo(photo)
end

hook.create_jekyll_page

