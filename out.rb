#!/usr/bin/env ruby

require 'rubygems'
require 'bundler/setup'
require 'json'
require File.expand_path('../lib/hook', __FILE__)
require 'rugged'

Hook.run!
