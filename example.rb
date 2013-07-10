# encoding: utf-8

require 'rubygems'
require 'ruby-sms-reactor'

api = SMSReactor::Api.new( "user@example.com", "..." )
puts api.get_signatures( 1 )