import std/[httpclient, json, net, random, strformat, os, sequtils, unicode, strutils]
import sousConf, tinyre, sousHelpers, pipeline

const TG_BASE = "https://api.telegram.org/bot"

createDir("src")
block: (let f = open("src/longSous.json", fmAppend); f.close())
block: (let f = open("src/.backup", fmAppend); f.close())

let config = getConfigPls()

proc tg(token, meth: string, body: JsonNode = newJObject()): JsonNode =
  let client = newHttpClient(timeout = 450_000)
  client.headers = newHttpHeaders({"Content-Type": "application/json"})
  defer: client.close()
  let resp = client.request(TG_BASE & token & "/" & meth,
    httpMethod = HttpPost, body = $body)
  result = parseJson(resp.body)

proc processUpdate(token, botUsername: string, update: JsonNode) =
  randomize()

  let conf = getConfigPls()
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

    # NB: если inputDataCompile использует типы telebot —
    # замените второй аргумент на нужные поля из update (JsonNode)
    var text = msgText & inputDataCompile(flagIn, update)
    if text == "":
      echo fmt"[!] ничего"
      return

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

    let reply = sous.request(SOUS_URL, httpMethod = HttpPost, body = $body)

    var sendTex = $reply.body
    try:
      sendTex = parseJson(reply.body)["choices"][0]["message"]["content"].getStr()
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


proc starrt() =
  let API_KEY = config.filterIt(it.name == "Init")[0]
                      .vklad.filterIt(it.key == "telegramKey")[0].va
  if API_KEY == "":
    echo "[X] нет ключа телеграм апи"
    discard readLine(stdin)
    return

  let meResp = tg(API_KEY, "getMe")
  echo meResp
  let botUsername = meResp["result"]["username"].getStr()

  echo "[поднял]"

  var offset: int64 = 0

  while true:
    try:
      let resp = tg(API_KEY, "getUpdates", %*{
        "offset": offset,
        "timeout": 400
      })

      if resp.hasKey("result") and resp["result"].kind == JArray:
        for update in resp["result"]:
          offset = update["update_id"].getBiggestInt() + 1
          processUpdate(API_KEY, botUsername, update)

    except Exception as e:
      echo $e.msg
      echo "[fall] poll"
      sleep(5000)

starrt()