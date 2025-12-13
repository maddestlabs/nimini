## Nimini Standard Library - Sequence Operations
## Provides newSeq, setLen, and other sequence manipulation functions

import ../runtime

# Create a new sequence with given size
proc niminiNewSeq*(env: ref Env; args: seq[Value]): Value =
  ## newSeq[T](size: int) - Creates a new sequence of given size
  if args.len < 1:
    quit "newSeq requires at least 1 argument (size)"
  
  let size = toInt(args[0])
  var arr: seq[Value] = @[]
  for i in 0..<size:
    arr.add(valNil())  # Initialize with nil values
  
  return Value(kind: vkArray, arr: arr)

# Set the length of a sequence
proc niminiSetLen*(env: ref Env; args: seq[Value]): Value =
  ## setLen(seq, newLen: int) - Resizes a sequence
  if args.len < 2:
    quit "setLen requires 2 arguments (seq, newLen)"
  
  if args[0].kind != vkArray:
    quit "setLen first argument must be an array"
  
  let newLen = toInt(args[1])
  let arr = args[0]
  
  if newLen > arr.arr.len:
    # Extend with nil values
    for i in arr.arr.len..<newLen:
      arr.arr.add(valNil())
  elif newLen < arr.arr.len:
    # Truncate
    arr.arr.setLen(newLen)
  
  return valNil()

# Get the length of a sequence
proc niminiLen*(env: ref Env; args: seq[Value]): Value =
  ## len(seq) - Returns the length of a sequence or string
  if args.len < 1:
    quit "len requires 1 argument"
  
  case args[0].kind
  of vkArray:
    return valInt(args[0].arr.len)
  of vkString:
    return valInt(args[0].s.len)
  else:
    quit "len requires an array or string"

# Add element to sequence
proc niminiAdd*(env: ref Env; args: seq[Value]): Value =
  ## add(seq, elem) - Adds an element to the end of a sequence
  if args.len < 2:
    quit "add requires 2 arguments (seq, elem)"
  
  if args[0].kind != vkArray:
    quit "add first argument must be an array"
  
  args[0].arr.add(args[1])
  return valNil()

# Delete element from sequence
proc niminiDelete*(env: ref Env; args: seq[Value]): Value =
  ## delete(seq, index) - Deletes an element at the given index
  if args.len < 2:
    quit "delete requires 2 arguments (seq, index)"
  
  if args[0].kind != vkArray:
    quit "delete first argument must be an array"
  
  let idx = toInt(args[1])
  if idx < 0 or idx >= args[0].arr.len:
    quit "delete: index out of bounds"
  
  args[0].arr.delete(idx)
  return valNil()

# Insert element into sequence
proc niminiInsert*(env: ref Env; args: seq[Value]): Value =
  ## insert(seq, elem, index) - Inserts an element at the given index
  if args.len < 3:
    quit "insert requires 3 arguments (seq, elem, index)"
  
  if args[0].kind != vkArray:
    quit "insert first argument must be an array"
  
  let idx = toInt(args[2])
  if idx < 0 or idx > args[0].arr.len:
    quit "insert: index out of bounds"
  
  args[0].arr.insert(args[1], idx)
  return valNil()

# Register all sequence operations
proc registerSeqOps*() =
  registerNative("newSeq", niminiNewSeq)
  registerNative("setLen", niminiSetLen)
  registerNative("len", niminiLen)
  registerNative("add", niminiAdd)
  registerNative("delete", niminiDelete)
  registerNative("insert", niminiInsert)
