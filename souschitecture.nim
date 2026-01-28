import std/[httpclient, json, net, random,strformat, os, sequtils, unicode], telebot, asyncdispatch, strutils, sousConf, tinyre, sousHelpers, pipeline

createDir("src")
let f8437 = open("src/longSous.json", fmAppend); f8437.close() 
let f8438 = open("src/.backup", fmAppend); f8438.close() 


let config = getConfigPls()

proc updateHandler(bot: TeleBot, update: Update): Future[bool] {.async, gcsafe.} =  
  randomize() 

  let conf = getConfigPls()

  let confInit = conf.filterIt(it.name == "Init")[0] 
  let confMemory = conf.filterIt(it.name == "Memory")[0] 

  #let API_KEY = confInit.vklad.filterIt(it.key == "telegramKey")[0].va
  let SOUS_KEY = confInit.vklad.filterIt(it.key == "apiKey")[0].va
  let SOUS_MODEL = confInit.vklad.filterIt(it.key == "apiModel")[0].va
  let SOUS_URL = confInit.vklad.filterIt(it.key == "apiUrl")[0].va

  var confTelebot = conf.boxFetch("Telebot")
  var confInput = confTelebot.boxInBox.boxFetch("input")
  var confAnswer = confTelebot.boxInBox.boxFetch("answer")

  var rate = keyValFetch(confAnswer, "rate", "0").parseInt - 1
  var memLen = keyValFetch(confMemory, "lenght", "0").parseInt
  var prompt = keyValFetch(confMemory, "prompt")
  var flagIn: settiSeq; if confInput.vkladSeq.len != 0: flagIn = confInput.vkladSeq
  var extraReq: JsonNode; if not confAnswer.vkladJson.parseJson.isNil: extraReq = confAnswer.vkladJson.parseJson
  var promptPipes = confInput.vkladPipes

  var cut = keyValFetch(confInput, "cut", "1000").parseint
  var inCut = keyValFetch(confMemory, "inCut", "1000").parseInt
  var outCut = keyValFetch(confMemory, "outCut", "1000").parseInt

  if rate < 0:
    rate = 0
    echo "[!] rate исправлен, измените число в конфиге на 1+"

  try:   

    if update.message.isNil:   
      echo "[!] пустое сообщение"   
      return true   

    if  update.message.replyToMessage != nil:   
      if update.message.replyToMessage.fromUser.firstName != "Sous":   
        if rand(0..rate) != 0:   
          echo "[!] скип"   
          return true   
   
      else:   
        if update.message.text.startsWith("!wack"):   
          echo "[!] вак"   
          let f = open("src/longSous.json", fmWrite)
          f.write($ %* @[%*{"in":"","out":""}])   
          f.close()   
          discard await bot.sendMessage(   
            replyParameters = ReplyParameters(messageId: update.message.messageId),   
            chatid = update.message.chat.id,   
            text = "ААА"   
          )   

          return true 

    else:   
      if rand(0..rate) != 0:   
        echo "[!] скип"   
        return true   

    var text = update.message.text & inputDataCompile(flagIn, update)
    if text == "":
      echo fmt"[!] ничего"
      return true
    

    echo "____ \n"   
       

    if readFile("src/longSous.json") == "": 
      let f = open("src/longSous.json", fmWrite)
      f.write($ %* @[%*{"in":"","out":""}])
      f.close()

    var memSous: seq[JsonNode] = (parseJson readFile "src/longSous.json").toSeq 

       
    let sous = newHttpClient()   
    sous.headers = newHttpHeaders({   
      "Authorization": "Bearer " & SOUS_KEY,   
      "Content-Type": "application/json"   
    })   
     
    let chatId = update.message.chat.id   
    echo "[текст] ", text   

    var finalPrompt: seq[JsonNode] = @[]
    finalPrompt = exec[JsonNode](s = promptPipes.join("\n"), o = finalPrompt, 
      (k: "prompt", w: @[ %*{"role":"user","content": text} ]), 
      (k: "memory", w: makeMeHistory(memSous)) ,
      (k: "input", w: @[ %*{"role":"system","content": prompt} ])
    )

    var body = %*{   
        "model": SOUS_MODEL,   
        "messages": finalPrompt ,
    }   

    for pair in extraReq.pairs:
      body[pair.key] = pair.val
    echo "[body] ", body 

    var reply = 
      sous.request(   
      SOUS_URL,   
      httpMethod = HttpPost,   
      body = $body   
      )   

    var sendTex = $reply.body

    try:
        discard parseJson(reply.body)["choices"][0]["message"]["content"].getStr()
        sendTex = parseJson(reply.body)["choices"][0]["message"]["content"].getStr()
    except Exception as _:
        echo "[!] ошибка? "
    
    echo "[ответ] ", sendTex
   
    discard await bot.sendMessage(   
      replyParameters = ReplyParameters(messageId: update.message.messageId),   
      chatid = chatId,   
      text = sendTex   
    )   

  
    echo "____ \n"    
    

    if memLen != 0:
        memSous.add(%*{"in": runeSubStr(text, 0, inCut), "out": runeSubStr(sendTex, 0, outCut)}) 
        if memSous.len >= memLen:
          memSous = memSous[(memLen div 2)..^1]
    
        block writeLong:
          let f = open("src/longSous.json", fmWrite)
          f.write %*memSous
          close f   


    sous.close()   
       
       
  except Exception as e:   
    discard await bot.sendMessage(   
      replyParameters = ReplyParameters(messageId: update.message.messageId),   
      chatid = update.message.chat.id,   
      text = $e.msg   
    )   
      
  return true    
   

proc starrt() =
  let API_KEY = config.filterIt(it.name == "Init")[0].vklad.filterIt(it.key == "telegramKey")[0].va
  if API_KEY == "":
    echo "[X] нет ключа телеграм апи"
    discard readLine(stdin)
    return

  let bot = newTeleBot(API_KEY)   

  try: bot.onUpdate(updateHandler)   
  except Exception as e:   
    echo $e.msg   
    echo "[fall] init"      

  echo "[поднял]"

  try: bot.poll(timeout = 400)   
  except Exception as e:   
    echo $e.msg   
    echo "[fall] poll"   
    sleep(5000) 

  discard bot.logOut
  discard bot.close

  starrt()

    
starrt()