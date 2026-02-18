import tinyre, sequtils, strutils, random, algorithm, os, json

proc doEmRound[T](word: string, input: seq[T]): seq[T] =
  case word
    of "sample()":
      randomize()
      result = @[sample(input)]
    of "shuffle()":
      randomize()
      var shuffled = input
      shuffle shuffled
      result = shuffled
    of "reverse()":
      result = input.reversed
    else:
      echo "[ERR] нет никакого: ", word
      result = input

proc doEmSquare[T](word: string, input: seq[T], target: var seq[T]) =
  case word
    of "concat[]":
      target = target.concat input
    of "write[]":
      target = input
    else:
      echo "[ERR] нет никакого: ", word

proc doRound[T](word: string): seq[T] =
  case word.replace(re"\(.*\)", ""):
    of "readAnJsonl":
      when T isnot JsonNode:
        echo "[typeERR] ты не можешь вернуть JsonArray в ", $seq[T]; return @[]
      else:
        randomize()
        result =  parseJson( sample( readFile("src/" & word.replace(re"readAnJsonl\(|\)", "")).splitLines.toSeq ))["messages"].toSeq
    of "readAllJsonl":
      when T is JsonNode:
        result = (readFile("src/" & word.replace(re"readAllJsonl\(|\)", "") ).splitLines.toSeq).mapIt( (parseJson it)["messages"].toSeq).concat
      else:
        echo "[typeERR] ты не можешь вернуть JsonArray в ", $seq[T] ; return @[]
    else:
      echo "[ERR] нет никакого: ", word
      result = @[]

# 

proc unPack[T](s: string, v: varargs[tuple[k: string, w: seq[T]]]): seq[T] =
  let filtered = v.filterIt(it.k == s)
  if filtered.len > 0:
    return filtered[0].w
  else:
    echo "[ERR] не найден ключ: ", s
    return @[]

proc exec*[T](s: string, o: seq[T], v: varargs[tuple[k: string, w: seq[T]]]): seq[T] = 
    
  result = o
   
  for l in s.splitLines.toSeq:
    var local: seq[T] = result
    for i, word in l.split(re"\s+").filterIt(it != "").reversed:
      if match(word, re".*\(\).*").len > 0:
        local = doEmRound[T](word, local)
      elif match(word, re".*\[\].*").len > 0:
        doEmSquare[T](word, local, result)
      elif match(word, re".*\([^)]+\).*").len > 0:
        local = doRound[T](word)
      else:
        local = unPack(word, v)        
       