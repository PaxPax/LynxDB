import os, threadpool, asyncdispatch, asyncnet

var addrParam: string

proc connect(socket: AsyncSocket, serverAddr: string) {.async.} =
    ## Connects to the specified AsyncSocket to specified address
    ## Then receives messages from the server continuously
    echo("Connecting to ", serverAddr)
    # Pause the exe of the procedure until socket connects
    await socket.connect(serverAddr, 7687.Port)
    echo("Connected!")#TODO handle the deletion of the base Entity
    while true:
        #this will be used to show the responses sent by the server
        let line = await socket.recvLine()
        echo(line)

proc start(): void =
    echo("LynxDB has started...")
    if paramCount() > 0:
        addrParam = paramStr(0)
    else:
        addrParam = "localhost"
    
    var socket = newAsyncSocket()
    asyncCheck connect(socket, addrParam)
    
    stdout.write "> "
    var fMessage = spawn stdin.readLine()
    while true:
        if fMessage.isReady():
            asyncCheck socket.send(^fMessage & "\c\l")
            stdout.write "> "
            fMessage = spawn stdin.readLine()
        asyncdispatch.poll()

start()
