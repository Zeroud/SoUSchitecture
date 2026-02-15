import std/[json, net, sequtils, strutils], sousConf, strformat

proc inputDataCompile*(use: settiSeq, update: JsonNode): string =
  if use.findIt(it == "sticker") != -1:
    if update["message"].hasKey("sticker"):
      result &= fmt"""[Стикер {update["message"]["sticker"]["emoji"].getStr}]"""
  if use.findIt(it == "photo") != -1:
    if update["message"].hasKey("photo") and update["message"]["photo"].len != 0:
      result &= update["message"]["photo"].getElems.mapIt(fmt"""[Фото {it["fileSize"].getInt}байт] """).join(", ")
  if use.findIt(it == "video") != -1:
    if update["message"].hasKey("video"):
      let v = update["message"]["video"]
      result &= fmt"""[Видео {v["fileName"].getStr} {v["duration"].getInt}сек {v["fileSize"].getInt}байт {v["mimeType"].getStr} ] """
  if use.findIt(it == "audio") != -1:
    if update["message"].hasKey("audio"):
      let a = update["message"]["audio"]
      result &= fmt"""[Звук {a["title"].getStr} {a["duration"].getInt}сек] """
  if use.findIt(it == "document") != -1:
    if update["message"].hasKey("document"):
      let d = update["message"]["document"]
      result &= fmt"""[Файл {d["fileName"].getStr} {d["fileSize"].getInt}байт] """
  if use.findIt(it == "voice") != -1:
    if update["message"].hasKey("voice"):
      result &= fmt"""[Голосовое сообщение {update["message"]["voice"]["duration"].getInt}сек] """
  if use.findIt(it == "gif") != -1:
    if update["message"].hasKey("animation"):
      let g = update["message"]["animation"]
      result &= fmt"""[GIF {g["fileName"].getStr} {g["mimeType"].getStr}] """
  if use.findIt(it == "video_note") != -1:
    if update["message"].hasKey("videoNote"):
      result &= fmt"""[Видеосообщение {update["message"]["videoNote"]["duration"].getInt}сек] """
  if use.findIt(it == "contact") != -1:
    if update["message"].hasKey("contact"):
      let c = update["message"]["contact"]
      result &= fmt"""[Контакт {c["firstName"].getStr} {c["lastName"].getStr} {c["phoneNumber"].getStr}] """
  if use.findIt(it == "contact") != -1:
    if update["message"].hasKey("location"):
      let geo = update["message"]["location"]
      result &= fmt"""[Координаты {geo["latitude"].getFloat} {geo["longitude"].getFloat}] """
  if use.findIt(it == "caption") != -1:
    if update["message"].hasKey("caption") and update["message"]["caption"].getStr != "":
      result &= fmt""" {update["message"]["caption"].getStr} """

func keyValFetch*(mother: settiBox, word: string, def: string = ""): string = 
  let exs = mother.vklad.filterIt(it.key == word)
  if exs.len != 0: result = exs[0].va else: result = word; result = def

func boxFetch*(mother: seq[settiBox], word: string): settiBox = 
  let exs = mother.filterIt(it.name == word)
  if exs.len != 0: result = exs[0] else: discard

func makeMeHistory*(arr: seq[JsonNode]): seq[JsonNode] = 
  for an in arr: 
    result = result.concat @[ %*{"role":"user","content":an["in"]}, %*{"role":"assistant","content":an["out"]} ]
