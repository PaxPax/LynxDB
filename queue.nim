import server

type
    NewQueueException = object of Exception
    ClientQueue = ref object of RootObj
        queue: seq[Client]

proc newClientQueue*(): ClientQueue =
    try:
        new(result)
    except:
        raise newException(NewQueueException, "Error creating new Client Queue")
    result.queue.newSeq(100)
