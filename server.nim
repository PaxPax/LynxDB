import asyncdispatch, asyncnet, parser, json, schema, tables
import parseutils, strutils
#this will hold the tree when using command line arguments
var treeContainer* = initTable[string, DoublyLinkedNodeObj]()
#the first new entity will be the basis of the root key
var root_key : string

type
    Client* = ref object
        socket: AsyncSocket
        netAddr: string
        id: int
        connected: bool
    
    Server = ref object
        socket: AsyncSocket
        clients: seq[Client]

proc newServer(): Server =
    Server(socket: newAsyncSocket(), clients: @[])

proc `$`(client: Client): string =
    $client.id & "(" & client.netAddr & ")"

proc cmdAdd(self: Server,x: JsonNode): void =
    var str_max_size = x["args"][1]
    var int_max_size = parseInt($str_max_size)
    var name = $x["args"][0]
    #if the dictionary len is 0 it means that it's empty
    #and there is no root node found inside the dictionary
    #so the first entity created will become the root and the
    #key to access it will be the entities name
    if treeContainer.len == 0:
        #TODO the static value should be a temporary thing
        var tmp = newEntity(name, int_max_size)
        treeContainer.add(tmp.data.name, tmp)
        root_key = tmp.data.name
    else:
        var root = treeContainer[root_key]
        root.newEntity(name, int_max_size)
        asyncCheck self.socket.send("add: OK")

proc cmdDel(self: Server, x: JsonNode): void =
    if treeContainer.len == 0:
        asyncCheck self.socket.send("Nothing to delete")
        return
    else:
        if treeContainer[root_key].hasEntity($["args"][0]):
            var tmp = treeContainer[root_key].delEntity($["args"][0])
            treeContainer.clear()

            treeContainer.add(tmp.data.name, tmp)
            root_key = tmp.data.name
            asyncCheck self.socket.send("del: OK")

proc cmdAddPair(self: Server,x: JsonNode): void =
    var root = treeContainer[root_key]
    var name = $x["args"][0]
    var key = $x["args"][1]
    var value = $x["args"][2]
    #while caching the values now isn't a noticable difference it does allow two things
    #one it increases code readability
    #two if this code grows the impact of having to reacesses items will be be a bad thing
    if treeContainer.len == 0:
        asyncCheck self.socket.send("Nothing for Lynx to add")
        return
    elif root.hasEntity(name):
        root.getEntity(name).addPair(key, value)
        asyncCheck self.socket.send("addPair confirmed")

proc exeCommand(self: Server,x: JsonNode): void =

    var test_against = getStr(x["command"])
    case test_against:
        of "add":
            self.cmdAdd(x)
        of "del":
            self.cmdDel(x)
        of "add_pair":
            self.cmdAddPair(x)

proc checkCommand(server: Server, client: Client) {.async.} =
    #as stated this thread runs in the background async
    #it's waiting for the user to send a line if the line len is 0 then they're disconnected
    #else we'll pass that line into the parser and if it's valid will return a JsonNodeObj
    #that we can retireve the needed values to execute the command
    #the jsonnodeobj is sent the the execution phase.
    while true:
        let line = await client.socket.recvLine()

        if line.len == 0:
            echo(client, "disconnected")
            client.connected = false
            client.socket.close()
            return
        var command = genJson(line)
        server.exeCommand(command)

proc loop(server: Server, port = 7687) {.async.} =
    #this is forever loop running in the background that is waiting on connections from clients
    #the port it's listening on is 7687, but can be overridden
    server.socket.bindAddr(port.Port)
    server.socket.listen()
    echo("listening on loclahost:", port)

    while true:
        #the await is a simplified call back
        let (netAddr, clientSocket) = await server.socket.acceptAddr()
        echo("Accepted connection from ", netAddr)
        let client = Client(
            socket: clientSocket,
            netAddr: netAddr,
            id: server.clients.len,
            connected: true
        )
        #once there is a detected connection on the given socket it's accepted and the client
        #is created and added the the seq[client] that the server has
        #after words another thread is spawned
        server.clients.add(client)

        asyncCheck checkCommand(server, client)

when isMainModule:
    var s = newServer()
    echo("Server init")
    waitFor loop(s)