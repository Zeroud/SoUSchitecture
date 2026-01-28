import tinyre, sequtils, strutils, random

proc exec*[T](s: string, o: seq[T], v: varargs[tuple[k: string, w: seq[T]]]): seq[T] = 
    randomize()

    let glob = re"\w+\[\]"
    let pConcat = re"^concat\s+"
    let pShuffle = re"^shuffle\s*"

    var lines = s.splitLines.toSeq
    result = o
    
    for line in lines:
        if line.contains(pConcat):
            let exsPipe = v.filterIt(it.k == line.match(glob)[0].replace("[]", ""))
            if exsPipe.len != 0:
                result.add(exsPipe[0].w)
        elif line.contains(pShuffle):
            result.shuffle
