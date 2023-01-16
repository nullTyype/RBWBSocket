require 'socket'
require 'digest/sha1'

server = TCPServer.new('localhost', 3000)

