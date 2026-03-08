import nigui, sousConf, sequtils

app.init()

var w = newWindow("SoUSchitecture")
w.iconPath = "SoUSchitecture.png"
w.height = 500
w.width = 350
w.resizable = false

var c = newContainer()
c.width = w.width
c.height = w.height
c.backgroundColor = Color(red: 200, green: 220, blue: 250)


############################################

var макушка = newLayoutContainer(Layout_Horizontal)
макушка.width = c.width
макушка.xAlign = XAlign_Center 
макушка.backgroundColor = Color(red: 255, green: 101, blue: 69) 
макушка.spacing = 15  
c.add(макушка)


var запуск = newButton("►")
макушка.add(запуск)
запуск.width = 40
запуск.height = 40
запуск.onClick = proc(event: ClickEvent) =
  echo "startSous()"
  запуск.enabled = false

var реКонфиг = newButton("↻")
макушка.add(реКонфиг)
реКонфиг.width = 40
реКонфиг.height = 40
реКонфиг.fontBold = true
реКонфиг.onClick = proc(event: ClickEvent) =
  echo "reConfig()"

var спрятать = newButton("▬")
макушка.add(спрятать)
спрятать.width = 40
спрятать.height = 40
спрятать.onClick = proc(event: ClickEvent) =
  w.minimized = true

############################################

proc genSetting(cont: Container, s: setti) =
  let l = newLayoutContainer(Layout_Horizontal)
  l.width = c.width
  l.height = 30
  l.xAlign = XAlign_Left
  l.spacing = 10

  let k = newLabel(s.key)
  k.width = 100
  k.height = l.height
  l.add(k)

  let v = newTextBox(s.va)
  v.width = 200
  v.height = l.height
  l.add(v)

  c.add(l)

proc genSettings(cont: Container, s: settiSeq, parent: settiBox) =
  if parent.name == "input":
    for i in @["sticker", "photo", "video", "audio", "document", "voice", "gif", "videoNote", "contact", "location", "caption"]:
      if s.findIt(it == i) != -1:
        let chB = newCheckBox(i)
        chB.checked = true
        cont.add(chB)
      else:
        let chB = newCheckBox(i)
        cont.add(chB)
      

    

proc genDropper(box: settiBox, cont: Container) =
  for i in box.vklad:
    cont.genSetting(i)
  







w.add(c)

w.show()

app.run()