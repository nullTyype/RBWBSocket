require 'socket'
require 'digest/sha1'

server = TCPServer.new('localhost', 3000)

loop do 
    socket = server.accept
    STDERR.puts ('Incoming Request')

    http_request = ''
    while (line = socket.gets) && (line != '/r/n')
        http_request += line
    end
    
    if matches = http_request.match(/^Sec-WebSocket-Key: (\S+)/)
        websocket_key = matches[1]
        STDERR.puts "Websocket handshake detected with the key: #{websocket_key}"
    else
        STDERR.puts "Aborting non-websocket connection"
        socket.close
        next
    end

    response_key = Digest::SHA1.base64digest([websocket_key, '258EAFA5-E914-47DA-95CA-C5AB0DC85B11'].join)
    STDERR.puts "Responding to handshake with key #{response_key}"

    socket.write <<-eos
    HTTP/1.1 101 Switching Protocols
    UPGRADE: websocket
    Connection: Upgrade
    Sec-WebSocket-Accept: #{response_key}

    eos
    
    STDERR.puts 'Handshake completed. Starting to parse websocket frame.'

    first_byte = socket.getbyte
    fin = first_byte & 0b10000000
    opcode = first_byte & 0b00001111

    raise "We don't support continuations" unless fin
    raise "We only support opcode 1" unless opcode == 1

    second_byte = socket.getbyte

end
