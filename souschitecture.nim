import std/[httpclient, json, net, random, strformat, os, sequtils, unicode, strutils, asyncdispatch]
import sousConf, tinyre, sousHelpers, pipeline

const TG_BASE = "https://api.telegram.org/bot"

createDir("src")
block: (let f = open("src/longSous.json", fmAppend); f.close())
block: (let f = open("src/.backup", fmAppend); f.close())

var config: seq[settiBox] 
var коробОшибок: seq[string]

proc tg(token, meth: string, body: JsonNode = newJObject()): Future[JsonNode] {. async .} =
  let client = newAsyncHttpClient()
  client.headers = newHttpHeaders({"Content-Type": "application/json"})
  defer: client.close()
  let resp = await client.request(TG_BASE & token & "/" & meth,
    httpMethod = HttpPost, body = $body)
  result = parseJson(await resp.body)

proc processUpdate(token, botUsername: string, update: JsonNode, conf: seq[settiBox]) {. async .} =
  randomize()

  let confInit = conf.filterIt(it.name == "Init")[0]
  let confMemory = conf.filterIt(it.name == "Memory")[0]

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

  var cut = keyValFetch(confInput, "cut", "1000").parseInt
  var inCut = keyValFetch(confMemory, "inCut", "1000").parseInt
  var outCut = keyValFetch(confMemory, "outCut", "1000").parseInt

  if rate < 0:
    rate = 0
    echo "[!] rate исправлен, измените число в конфиге на 1+"

  try:
    let message = update{"message"}
    if message.isNil or message.kind == JNull:
      echo "[!] пустое сообщение"
      return

    let chatId = message["chat"]["id"].getBiggestInt()
    let messageId = message["message_id"].getInt()
    let msgText = if message.hasKey("text"): message["text"].getStr() else: ""
    let userWho = message{"from"}{"first_name"}.getStr & ": "

    let replyTo = message{"reply_to_message"}
    if not replyTo.isNil and replyTo.kind != JNull:
      let replyUsername = replyTo{"from", "username"}.getStr("")
      if replyUsername != botUsername:
        if rand(0..rate) != 0:
          echo "[!] скип"
          return
      else:
        if msgText.startsWith("!wack"):
          echo "[!] вак"
          let f = open("src/longSous.json", fmWrite)
          f.write($ %* @[%*{"in":"","out":""}])
          f.close()
          discard tg(token, "sendMessage", %*{
            "chat_id": chatId,
            "text": "ААА",
            "reply_parameters": %*{"message_id": messageId}
          })
          return
    else:
      if rand(0..rate) != 0:
        echo "[!] скип"
        return

    var text = userWho & msgText & inputDataCompile(flagIn, update)
    if text == "":
      echo fmt"[!] ничего"
      return

    echo "____ \n"

    if readFile("src/longSous.json") == "":
      let f = open("src/longSous.json", fmWrite)
      f.write($ %* @[%*{"in":"","out":""}])
      f.close()

    var memSous: seq[JsonNode] = (parseJson readFile "src/longSous.json").toSeq

    let sous = newAsyncHttpClient()
    sous.headers = newHttpHeaders({
      "Authorization": "Bearer " & SOUS_KEY,
      "Content-Type": "application/json"
    })

    echo "[текст] ", text

    var finalPrompt: seq[JsonNode] = @[]
    finalPrompt = exec[JsonNode](s = promptPipes.join("\n"), o = finalPrompt,
      (k: "prompt", w: @[ %*{"role":"system","content": prompt} ]),
      (k: "memory", w: makeMeHistory(memSous)),
      (k: "input",  w: @[ %*{"role":"user","content": text} ])
    )

    var body = %*{
      "model": SOUS_MODEL,
      "messages": finalPrompt,
    }

    for pair in extraReq.pairs:
      body[pair.key] = pair.val
    echo "[body] ", body

    let reply = await sous.request(SOUS_URL, httpMethod = HttpPost, body = $body)

    var sendTex = await reply.body
    try:
      sendTex = parseJson(sendTex)["choices"][0]["message"]["content"].getStr()
    except Exception:
      echo "[!] ошибка? "

    echo "[ответ] ", sendTex

    discard tg(token, "sendMessage", %*{
      "chat_id": chatId,
      "text": sendTex,
      "reply_parameters": %*{"message_id": messageId}
    })

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
    try:
      let chatId = update["message"]["chat"]["id"].getBiggestInt()
      let messageId = update["message"]["message_id"].getInt()
      discard tg(token, "sendMessage", %*{
        "chat_id": chatId,
        "text": $e.msg,
        "reply_parameters": %*{"message_id": messageId}
      })
    except:
      echo "[!] не удалось отправить ошибку: ", e.msg


proc startCore() {. async .} =
  let API_KEY = config.filterIt(it.name == "Init")[0]
                      .vklad.filterIt(it.key == "telegramKey")[0].va
  if API_KEY == "":
    echo "[X] нет ключа телеграм апи"
    when appType != "gui": discard readLine(stdin) else: коробОшибок.add "нет ключа Init > telegram Api"
    return

  let meResp = await tg(API_KEY, "getMe")
  echo meResp
  let botUsername = meResp["result"]["username"].getStr()

  echo "[поднял]"

  var offset: int64 = 0

  while true:
    try:
      let resp = await tg(API_KEY, "getUpdates", %*{
        "offset": offset,
        "timeout": 400
      })

      if resp.hasKey("result") and resp["result"].kind == JArray:
        var tasks: seq[Future[void]] = @[]
        for update in resp["result"]:
          offset = update["update_id"].getBiggestInt() + 1
          tasks.add(processUpdate(API_KEY, botUsername, update, config))
        if tasks.len > 0:
          await all(tasks)

    except Exception as e:
      echo $e.msg
      echo "[fall] poll"
      offset += 1      
      sleep(5000)



proc main() {. async .} =

  try: asyncCheck startCore()
  except Exception as e:
    echo "FATAL CORE ERROR: ", e.msg
    when appType != "gui":
      discard readLine(stdin) 
    else: 
      коробОшибок.add "FATAL CORE ERROR: " & e.msg
    quit(1)
  
  discard "еще че то там про gui" # зерот_, напоминаю, для смены конфига не нужно перезапускать core, поменяй var config
  # да блять раньше напомнить не мог??


#_______________________________________#
proc reConfig() =
  config = getConfigPls()
proc startSous() =
  reConfig()
  asyncCheck main()
#_______________________________________#


when appType == "gui":
  include sousGui
else:
  reConfig()
  startSous()
  runForever()