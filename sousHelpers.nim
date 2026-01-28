import std/[json, net, sequtils, strutils], sousConf, telebot, strformat

proc inputDataCompile*(use: settiSeq, update: Update): string  =
  if use.findIt(it == "sticker") != -1:   
    if not update.message.sticker.isNil:
      result &= fmt"[Стикер {update.message.sticker.emoji}] "
  if use.findIt(it == "photo") != -1: 
    if update.message.photo.len != 0:
      result &= update.message.photo.mapIt(fmt"[Фото {it.fileSize}байт] ").join(", ")
  if use.findIt(it == "video") != -1:   
    if not update.message.video.isNil: 
      result &= fmt"[Видео {update.message.video.fileName} {update.message.video.duration}сек {update.message.video.fileSize}байт {update.message.video.mimeType} ] "
  if use.findIt(it == "audio") != -1:   
    if not update.message.audio.isNil:
      result &= fmt"[Звук {update.message.audio.title} {update.message.audio.duration}сек] "
  if use.findIt(it == "document") != -1:   
    if not update.message.document.isNil:
      result &= fmt"[Файл {update.message.document.fileName} {update.message.document.fileSize}байт] "
  if use.findIt(it == "voice") != -1:   
    if not update.message.voice.isNil:
      result &= fmt"[Голосовое сообщение {update.message.voice.duration}сек] "
  if use.findIt(it == "gif") != -1:   
    if not update.message.animation.isNil:
      result &= fmt"[GIF {update.message.animation.fileName} {update.message.animation.mimeType}] "
  if use.findIt(it == "videonote") != -1:   
    if not update.message.videoNote.isNil:
      result &= fmt"[Видеосообщение {update.message.videoNote.duration}сек] "
  if use.findIt(it == "contact") != -1:   
    if not update.message.contact.isNil:
      result &= fmt"[Контакт {update.message.contact.firstName} {update.message.contact.lastName} {update.message.contact.phoneNumber}] "
  if use.findIt(it == "caption") != -1:   
    if update.message.caption != "":
      result &= fmt" {update.message.caption} "

func keyValFetch*(mother: settiBox, word: string, def: string = ""): string = 
  let exs = mother.vklad.filterIt(it.key == word)
  if exs.len != 0: result = exs[0].va else: result = word; result = def

func boxFetch*(mother: seq[settiBox], word: string): settiBox = 
  let exs = mother.filterIt(it.name == word)
  if exs.len != 0: result = exs[0] else: discard

func makeMeHistory*(arr: seq[JsonNode]): seq[JsonNode] = 
  for an in arr: 
    result = result.concat @[ %*{"role":"user","content":an["in"]}, %*{"role":"assistant","content":an["out"]} ]
