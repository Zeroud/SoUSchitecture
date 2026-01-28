import os, strutils, sequtils, tinyre, json, flatty

type
    setti* = tuple
      key: string
      va: string 

    settiSeq* = seq[string]

    settiBox* = object
      name*: string
      vklad*: seq[setti] 
      vkladSeq*: settiSeq
      vkladJson*: string
      vkladPipes*: seq[string]
      boxInBox*: seq[settiBox] 


proc boxToBox(va: int,  box: var settiBox, nm: string) =
  if va != 0:
    boxToBox(va - 1, box.boxInBox[^1], nm)
  else:
    box.boxInBox.add(settiBox(name: nm))



proc getConfigPls*(): seq[settiBox] {.gcsafe.} =
  if fileExists("src/sousSett.md"): (
    let settFile = open("src/sousSett.md", fmRead)
    let backupFile = open("src/.backup", fmRead)

    var rawLines = readAll settFile
    let backupLines = readAll backupFile

    if not backupLines.endsWith(rawLines):
      echo "[ЗАГРУЗКА КОНФИГУРАЦИИ]"
      var config: seq[settiBox] = @[]


      for i, pool in rawLines.splitLines.toSeq:


        if pool.startsWith("#"):
          let parsName =  pool.replace(re"^#+", "").strip
          let l = pool.bounds(re"^#+")[0].b
          if l == 0:
            config.add settiBox(name: parsName)
          else:
            boxToBox(l - 1, config[^1], parsName)


        elif pool.startsWith("__"):
          let splitted = pool.split(re"__")[1 .. ^1]
          var curBox: ptr settiBox = addr config[^1]
          while curBox[].boxInBox.len != 0:
            curBox = addr curBox[].boxInBox[^1]          
          curBox[].vklad.add((key: splitted[0], va: splitted[1 .. ^1].join("__").strip()))
        

        elif pool.startsWith("*"):
          var curBox: ptr settiBox = addr config[^1]
          while curBox[].boxInBox.len != 0:
            curBox = addr curBox[].boxInBox[^1]
          curBox[].vkladSeq.add(pool[2..^1])



        elif pool.startsWith("```json"):
          var curBox: ptr settiBox = addr config[^1]
          while curBox[].boxInBox.len != 0:
            curBox = addr curBox[].boxInBox[^1]

          let remainingLines = rawLines.splitLines.toSeq[i + 1 .. ^1]
          let closingIdx = findIt(remainingLines, it == "```")
          
          if closingIdx != -1:
            let jsonLines = remainingLines[0 .. closingIdx - 1]
            curBox[].vkladJson = jsonLines.join("\n")
          else:
            echo "[!] Ошибка: у вас какашек в небе нехватает в конфигурации."



        elif pool.startsWith("```pipeline"):
          var curBox: ptr settiBox = addr config[^1]
          while curBox[].boxInBox.len != 0:
            curBox = addr curBox[].boxInBox[^1]

          let remainingLines = rawLines.splitLines.toSeq[i + 1 .. ^1]
          let closingIdx = findIt(remainingLines, it == "```")
          
          if closingIdx != -1:
            let pipeLines = remainingLines[0 .. closingIdx - 1]
            curBox[].vkladPipes = pipeLines
          else:
            echo "[!] Ошибка: у вас какашек в небе нехватает в конфигурации."



      close settFile; close backupFile;
      {.cast(gcsafe).}:
        writeFile("src/.backup", config.toFlatty & "\n" & rawLines)

      return config


    else:
      {.cast(gcsafe).}:
        return backupLines.split("\n")[0].fromFlatty(seq[settiBox])
  )


  else:
      echo "[НЕ НАЙДЕНО КОНФИГУРАЦИИ]"
      try:
         writeFile("src/sousSett.md","""# Telebot
## input
* sticker

* caption

## answer
__rate__ 1

```json
{"temperature": 0.8,}
```

```pipeline
concat prompt
concat memory
concat input
```

# Init
__telegramKey__ 

__apiUrl__ 

__apiModel__ 

__apiKey__ 

# Memory
__lenght__ 0

__inCut__ 100

__outCut__ 100""")
         echo "[УСПЕШНО ЗАПИСАНО] пожалуйста, впишите ключи и url в src/sousSett.md"
         return getConfigPls()
      except Exception as e:
        echo "[НЕ ЗАПИСАНО] из-за ", $e.msg