import json, strutils
let command_list = ["add", "add_pair", "del", "resize", "get"]


proc parseCommand(x: seq[string]): JsonNode

proc genJson*(to_parse: string): JsonNode=
    #We have multiple options to check for so first see if it's a command
    for command in command_list:
        if to_parse.contains(command):
            result = parseCommand(to_parse.split(" "))
    quit("You've given an invalid command my guy")
#TODO write a more forgiving parser
proc parseCommand(x: seq[string]): JsonNode =
    #the second index should contain the args="","",""
    #so we'll split on the equals
    if not x[1].contains("args"):
        quit("Please specify the args parameter")
    var tmp = x[1].split("=")
    #the args= should be a token and the actual args will be grouped together as a second token
    var seq_args = tmp[1].split(",")
    # echo(seq_args)
    var j = %*{
        "command": x[0],
        "args": seq_args
    }
    return j
