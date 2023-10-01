#Include <HotGestures\HotGestures>

leftSlide := HotGestures.Gesture("←:-1,0")
rightSlide := HotGestures.Gesture("→:1,0")
circle := HotGestures.Gesture("O:-20,0|-20,3|-19,5|-19,7|-18,10|-16,12|-15,14|-13,15|-11,17|-9,18|-6,19|-4,20|-1,20|1,20|4,20|6,19|9,18|11,17|13,15|15,14|16,12|18,10|19,7|19,5|20,3|20,0|20,-3|19,-5|19,-7|18,-10|16,-12|15,-14|13,-15|11,-17|9,-18|6,-19|4,-20|1,-20|-1,-20|-4,-20|-6,-19|-9,-18|-11,-17|-13,-15|-15,-14|-16,-12|-18,-10|-19,-7|-19,-5|-20,-3")
z := HotGestures.Gesture("Z:2,0|4,-1|8,0|10,0|14,0|17,-1|18,-2|18,-1|19,-1|17,-1|16,0|15,0|12,-1|11,-1|12,0|13,0|12,0|13,0|10,0|6,0|4,0|1,0|-1,1|-3,2|-5,2|-5,4|-7,5|-8,6|-10,6|-12,7|-13,9|-15,8|-14,8|-14,9|-13,7|-12,7|-12,7|-11,6|-12,7|-13,7|-13,7|-12,5|-11,5|-9,4|-8,4|-6,3|-4,2|-1,1|2,0|5,0|9,0|12,0|16,0|19,0|23,0|27,0|34,0|35,1|33,1|31,0|25,0|19,0|13,0|8,0")
s := HotGestures.Gesture("S:0,-1|0,-1|-1,-1|-1,-1|-2,-1|-1,-1|-1,-1|-1,0|-2,-1|-2,-2|-3,-1|-4,-2|-5,-1|-7,-1|-7,0|-9,0|-8,0|-9,0|-8,0|-6,0|-4,2|-4,1|-4,2|-4,3|-4,3|-5,3|-5,3|-4,3|-4,4|-4,4|-5,5|-4,5|-3,6|-1,7|-1,7|0,8|0,9|2,8|2,7|3,5|3,4|5,4|7,4|9,4|11,5|13,6|14,5|13,5|15,5|14,5|11,5|10,4|7,3|5,2|3,2|2,2|1,2|1,1|1,1|0,2|0,2|0,3|0,4|0,3|-2,4|-2,5|-3,4|-5,5|-6,6|-7,5|-8,6|-10,6|-11,6|-12,5|-11,4|-12,4|-10,4|-7,2|-9,1|-8,1|-8,1|-6,1|-5,0|-3,0|-2,0")

hgs := HotGestures()
hgs.Register(leftSlide, "Backspace", _ => Send("{BackSpace}"))
hgs.Register(rightSlide, "Wrap", _ => Send("{Enter}"))
hgs.Register(circle, "Select All", _ => Send("^a"))
hgs.Register(z, "Undo", _ => Send("^z"))
hgs.Register(s, "Save", _ => Send("^s"))

HotIfWinactive("ahk_class Notepad")
hgs.Hotkey("RButton")
HotIfWinactive()

txt := "
(
    click and hold the right button to gesture:
    left slide: backspace
    right slide: wrap
    circle: select all
    z: undo
    s: save
)"
Run("Notepad.exe")
hwnd := WinWaitActive("ahk_class Notepad")
Sleep(1000)
try {
    ControlSetText(txt, "RichEditD2DPT1", hwnd)
}
catch {
    try {
        ControlSetText(txt, "Edit1", hwnd)
    }
}