#!/usr/bin/env ruby

# frozen_string_literal: true

require 'sh'

sh.verbose = true

sh.tail('-f', 'log.txt')

# begin
#   puts sh.cat(_in: sh.echo('sergei'))
# rescue Sh::ErrorReturnCode_1 => e
#   puts "No such luck: #{e}"
# end

# x = sh.Cmd('ls', '-l', '/tmp', color: 'never')
# puts(x.exec)
# puts(sh.ls(color: 'never'))
