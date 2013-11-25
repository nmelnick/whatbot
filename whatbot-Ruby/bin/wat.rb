#!/usr/bin/env ruby

$LOAD_PATH << './lib'
require 'whatbot/message'

message = Whatbot::Message.new({ 'to' => 'your mom' })
puts message.is_private
puts message.to

