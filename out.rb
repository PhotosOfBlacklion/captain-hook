#!/usr/bin/env ruby
# frozen_string_literal: true

require "rubygems"
require "bundler/setup"
require "json"
require File.expand_path("lib/hook", __dir__)
require "rugged"

Hook.run!
