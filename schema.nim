import json, os
type
    DuplicateNodeError = object of Exception
    NilNodeError = object of Exception

    DoublyLinkedNodeObj* = ref object
        next*,prev*: DoublyLinkedNodeObj
        data*: Entity
    
    Entity* = object
        name*: string
        pairs*: seq[tuple[key: string, value: string]]
        size*: int
        saved: bool

#[Prototypes]#
proc newEntity*(self: DoublyLinkedNodeObj,name: string, max_size: int): void
proc minEntity*(self: DoublyLinkedNodeObj): DoublyLinkedNodeObj
proc swapRoot(root: DoublyLinkedNodeObj): DoublyLinkedNodeObj
proc printTree(x: DoublyLinkedNodeObj): void
#[/Prototypes]#

var save_string = newJArray()

proc newNode(target: Entity): DoublyLinkedNodeObj =
    return DoublyLinkedNodeObj(next: nil, prev: nil, data: target)

proc delEntity*(self: DoublyLinkedNodeObj, target: string): DoublyLinkedNodeObj =
    if self.isNil:
        raise newException(NilNodeError, "There is nothing to delete!")
    if self.data.name == target:
        return swapRoot(self)
    if target < self.data.name:
        self.prev = self.prev.delEntity(target)
    elif target > self.data.name:
        self.next = self.next.delEntity(target)
    else:
        if self.prev.isNil:
            return self.next
        elif self.prev.isNil:
            return self.prev

        var tmp = self.next.minEntity()
        self.data = tmp.data

        self.next = self.next.delEntity(tmp.data.name)

proc swapRoot(root: DoublyLinkedNodeObj): DoublyLinkedNodeObj =
    var newroot = new(DoublyLinkedNodeObj)
    if not root.next.isNil:
        newroot = root.next
        newroot.prev = root.prev
    elif not root.prev.isNil:
        newroot = root.prev
        newroot.next = root.next
    
    return newroot

proc addEntity*(tree, target: DoublyLinkedNodeObj): void =
    if tree.data.name == target.data.name:
        raise newException(DuplicateNodeError, "Don't add two of the same nodes!")
    if tree.data.name < target.data.name:
        if tree.next.isNil:
            tree.next = target
        else:
            tree.next.addEntity(target)
    else:
        if tree.prev.isNil:
            tree.prev = target
        else:
            tree.prev.addEntity(target)

proc newEntity*(name: string, max_size: int): DoublyLinkedNodeObj =
    var tmp: seq[tuple[key: string, value: string]]
    newSeq(tmp, max_size)
    result = DoublyLinkedNodeObj(
        next: nil,
        prev: nil,
        data: Entity(
            name: name,
            pairs: tmp,
            size: max_size,
            saved: false
            )
    )

proc newEntity*(self: DoublyLinkedNodeObj,name: string, max_size: int): void =
    var tmp: seq[tuple[key: string, value: string]]
    newSeq(tmp, max_size)
    var tmp2 =DoublyLinkedNodeObj(
        next: nil,
        prev: nil,
        data: Entity(
            name: name,
            pairs: tmp,
            size: max_size,
            saved: false
        )
    )
    self.addEntity(tmp2)

proc hasEntity*(tree: DoublyLinkedNodeObj, entity: string): bool =
    if tree.isNil:
        return false
    if tree.data.name == entity:
        return true
    if tree.data.name < entity:
        return tree.next.hasEntity(entity)
    return tree.prev.hasEntity(entity)

proc getEntity*(tree: DoublyLinkedNodeObj, entity: string): DoublyLinkedNodeObj =
    if tree.isNil or tree.data.name == entity:
        return tree
    if tree.data.name < entity:
        return tree.next.getEntity(entity)
    return tree.prev.getEntity(entity)
 
proc addPair*(target: DoublyLinkedNodeObj, key: string, value: string): void =
    target.data.pairs[target.data.size].key = key
    target.data.pairs[target.data.size].value = value
    target.data.size += 1

proc resizePairs*(target: DoublyLinkedNodeObj, new_size: int): void =
    var tmp = target.data.pairs
    var tmp2: seq[tuple[key: string, value: string]]
    newSeq(tmp2, new_size)
    tmp2 = tmp
    target.data.pairs = tmp2

proc minEntity*(self: DoublyLinkedNodeObj): DoublyLinkedNodeObj =
    var curr = self
    while not curr.prev.isNil:
        curr = curr.prev
    return curr

proc `$`(x: Entity): string =
    result = $x.name & $x.pairs & $x.size

proc `$`(x: DoublyLinkedNodeObj): string =
    result = $x.data & $x.next.data & $x.prev.data
    
proc printTree(x: DoublyLinkedNodeObj): void =
    if x.isNil:
        return
    else:
        echo(x.data)
        x.next.printTree()
        x.prev.printTree()

proc getKeys(self: DoublyLinkedNodeObj): string =
    var tmp: string
    for x in self.data.pairs:
        tmp.add(x.key & "\n")
    return tmp & "\c\l"


proc getNextEntity(self: DoublyLinkedNodeObj): DoublyLinkedNodeObj =
    if not self.next.isNil:
        return self.next
    else:
        return self

proc getPrevEntity(self: DoublyLinkedNodeObj): DoublyLinkedNodeObj =
    if not self.prev.isNil:
        return self.prev
    else:
        return self

proc formatNode(y: DoublyLinkedNodeObj): JsonNode =
    var str_prev,str_next: string

    if y.isNil:
        return
    var x = y.data

    if y.prev.isNil and y.next.isNil:
        str_prev = "Nil"
        str_next = "Nil"
    elif y.prev.isNil:
        str_prev = "Nil"
    elif y.next.isNil:
        str_next = "Nil"
    else:
        str_prev = y.prev.data.name
        str_next = y.next.data.name

    var currentNode = %*{
        "name": x.name,
        "pairs": $x.pairs,
        "size": x.size,
        "saved": x.saved,
        "prev": str_prev,
        "next": str_next
    }
    return currentNode

proc saveTree(self: DoublyLinkedNodeObj): void =
    if self.isNil:
        return
    saveTree(self.next)
    save_string.add(formatNode(self))
    saveTree(self.prev)

proc writeOrderedTree(): void =
    discard existsOrCreateDir("./src/storage")
    try:
        writeFile("./src/storage/lynx.json", $save_string)
    except IOError:
        echo("Error trying to save to file")
