import nigui, sugar

var running = true

let conFile = "src/sousSett.md"

app.init()

var w = newWindow("SoUSchitecture")
w.iconPath = "SoUSchitecture.png"
w.height = 700
w.width = 400
w.resizable = true

var c = newLayoutContainer(Layout_Vertical)
c.widthMode = WidthMode_Fill         
c.backgroundColor = Color(red: 200, green: 220, blue: 250)

############################################


var макушка = newLayoutContainer(Layout_Horizontal)
макушка.widthMode = WidthMode_Fill
макушка.xAlign = XAlign_Center
макушка.backgroundColor = Color(red: 255, green: 101, blue: 69)
макушка.spacing = 15
макушка.padding = 10             
c.add(макушка)


var запуск = newButton("►")
макушка.add(запуск)
запуск.width = 40
запуск.height = 40
запуск.onClick = proc(event: ClickEvent) =
  startSous()
  if коробОшибок.len != 0:
    for err in коробОшибок:
      w.alert(message = err, title = "ААААА МЫ ВСЕ УМРЕМ")
    коробОшибок = @[]
  else:
    запуск.enabled = false

var реКонфиг = newButton("✔")
макушка.add(реКонфиг)
реКонфиг.width = 40
реКонфиг.height = 40
реКонфиг.fontBold = true

var спрятать = newButton("▬")
макушка.add(спрятать)
спрятать.width = 40
спрятать.height = 40
спрятать.onClick = proc(event: ClickEvent) =
  w.minimized = true

############################################

proc genSetting(cont: Container, s: setti) =
  let l = newLayoutContainer(Layout_Horizontal)
  l.widthMode = WidthMode_Fill       
  l.height = 30
  l.spacing = 10
  l.backgroundColor = Color(red: 255, green: 101, blue: 69)

  let k = newLabel(s.key)
  k.width = 100                      
  k.height = l.height
  k.backgroundColor = Color(red: 255, green: 101, blue: 69)
  k.xTextAlign = XTextAlign_Center
  k.yTextAlign = YTextAlign_Center
  k.fontSize = 15
  l.add(k)

  let v = newTextBox(s.va)
  v.widthMode = WidthMode_Fill       
  v.height = l.height
  l.add(v)

  cont.add(l)  

proc genSettings(cont: Container, s: settiSeq, parent: settiBox) =
  if parent.name == "input":
    for i in @["sticker", "photo", "video", "audio", "document", "voice", "gif", "videoNote", "contact", "location", "caption"]:
      if s.findIt(it == i) != -1:
        let chB = newCheckBox(i)
        chB.checked = true
        chB.backgroundColor = Color(red: 255, green: 101, blue: 69)
        cont.add(chB)
      else:
        let chB = newCheckBox(i)
        chB.backgroundColor = Color(red: 255, green: 101, blue: 69)
        cont.add(chB)
      
proc genJson(cont: Container, t: string) =
  let lab = newLabel("json:")
  lab.backgroundColor = Color(red: 255, green: 101, blue: 69)
  let area = newTextArea(t)
  area.widthMode = WidthMode_Fill
  cont.add(lab)
  cont.add(area)

proc genPipes(cont: Container, ps: seq[string]) =
  let lab = newLabel("pipeline:")
  lab.backgroundColor = Color(red: 255, green: 101, blue: 69)
  let area = newTextArea()
  for i in ps:
    area.addLine(i)

  area.widthMode = WidthMode_Fill
  cont.add(lab)
  cont.add(area)

proc genDropper(cont: Container, box: settiBox) =
  var dropper = newLayoutContainer(Layout_Vertical)
  dropper.widthMode = WidthMode_Fill     
  dropper.backgroundColor = Color(red: 200, green: 220, blue: 250)
  dropper.visible = false

  let dropperButt = newButton(box.name)
  dropperButt.widthMode = WidthMode_Fill      
  dropperButt.height = 30

  capture dropper:                             
    dropperButt.onClick = proc(event: ClickEvent) =
      dropper.visible = not dropper.visible
      dropperButt.fontBold = dropper.visible

  cont.add(dropperButt)
  cont.add(dropper)
  
  for i in box.vklad:
    dropper.genSetting(i)
  for i in box.boxInBox:
    genDropper(dropper, i)
  if box.vkladSeq.len != 0:
    dropper.genSettings(box.vkladSeq, box)
  if box.vkladJson != "":
    dropper.genJson(box.vkladJson)
  if box.vkladPipes.len != 0:
    dropper.genPipes(box.vkladPipes)


let содержанка = newLayoutContainer(Layout_Vertical)
содержанка.widthMode = WidthMode_Fill    
содержанка.backgroundColor = Color(red: 200, green: 220, blue: 250)
c.add(содержанка)

######################################


proc mergeBox(dst: var settiBox, src: settiBox) =

  for srcSetti in src.vklad:
    let idx = dst.vklad.findIt(it.key == srcSetti.key)
    if idx == -1:
      dst.vklad.add(srcSetti)
    elif dst.vklad[idx].va == "":
      dst.vklad[idx].va = srcSetti.va

  for srcChild in src.boxInBox:
    let idx = dst.boxInBox.findIt(it.name == srcChild.name)
    if idx == -1:
      dst.boxInBox.add(srcChild)
    else:
      mergeBox(dst.boxInBox[idx], srcChild)

  if dst.vkladSeq.len == 0 and src.vkladSeq.len != 0:
    dst.vkladSeq = src.vkladSeq

  if dst.vkladJson == "" and src.vkladJson != "":
    dst.vkladJson = src.vkladJson

  if dst.vkladPipes.len == 0 and src.vkladPipes.len != 0:
    dst.vkladPipes = src.vkladPipes


proc mergeConfigs(dst: var seq[settiBox], src: seq[settiBox]) =
  for srcBox in src:
    let idx = dst.findIt(it.name == srcBox.name)
    if idx == -1:
      dst.add(srcBox)
    else:
      mergeBox(dst[idx], srcBox)


var конфиг = getConfigPls() 
let идеальныйКонфиг = @[
  settiBox(
    name: "Init",
    vklad: @[
      (key: "telegramKey", va: ""),
      (key: "apiKey", va: ""),
      (key: "apiModel", va: ""),
      (key: "apiUrl", va: ""),
    ]
    ),
  settiBox(
    name: "Telebot",
    boxInBox: @[
      settiBox(
        name: "input",
        vkladSeq: @[],
        vklad: @[
          (key: "cut", va: "1000"),
        ],
        vkladPipes: @[
          "concat[] prompt", "concat[] memmory", "concat[] input",
        ]
      ),
      settiBox(
        name: "answer",
        vklad: @[
          (key: "rate", va: "1"),
        ],
        vkladJson: """{"temperature": 0.8}"""
      )
    ]
  ),
  settiBox(
    name: "Memory",
    vklad: @[
      (key: "prompt", va: ""),
      (key: "lenght", va: "0"),
      (key: "inCut", va: "1000"),
      (key: "outCut", va: "1000"),
    ]
  ),
]

mergeConfigs(конфиг, идеальныйКонфиг)


for i in конфиг:
  let подДроппер = newLayoutContainer(Layout_Vertical)
  подДроппер.widthMode = WidthMode_Fill       
  содержанка.add(подДроппер)
  подДроппер.backgroundColor = Color(red: 200, green: 220, blue: 250)

  genDropper(подДроппер, i)

proc indeparts(c: Container, deep: int): string =
  var protoConstruct = ""
  var codeConstruct = "```"
  for ch in c.childControls:
    if ch of LayoutContainer:
      result.add indeparts(LayoutContainer(ch), deep + 1)
    elif ch of Button:
      result.add "#".repeat(deep) & " " & Button(ch).text & "\n"
    elif ch of Label:
      if Label(ch).text.endsWith(":"):
        codeConstruct &= fmt"""{Label(ch).text.replace(":","")}""" & "\n"
      else:
        protoConstruct &= fmt"__{Label(ch).text}__ "
    elif ch of CheckBox:
      if CheckBox(ch).checked:
        result.add "* " & CheckBox(ch).text & "\n" & "\n" 
    elif ch of TextArea:
      result.add codeConstruct & TextArea(ch).text.split("\n").filterIt(it != "").join("\n") & "\n```" & "\n" & "\n" 
      codeConstruct = "```"
    elif ch of TextBox:
      protoConstruct &= TextBox(ch).text
      result.add protoConstruct & "\n" & "\n"
      protoConstruct = ""


proc saveConfig() =
  let newConfig = indeparts(содержанка, 0)
  writeFile(conFile, newConfig)


реКонфиг.onClick = proc(event: ClickEvent) =
  saveConfig()
  reConfig()

w.add(c)

w.show()

w.onCloseClick = proc(event: CloseClickEvent) =
  running = false

# Кооператив (не лебединое озеро)
while running:
  app.processEvents()          
  if hasPendingOperations():  
    poll(20)                 
  else:
    sleep(100)                 