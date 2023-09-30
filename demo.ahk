#Include <HotGestures\HotGestures>

leftSlide := HotGestures.Gesture("←:-1,0")
rightSlide := HotGestures.Gesture("→:1,0")
circle := HotGestures.Gesture("O:-20,0|-20,3|-19,5|-19,7|-18,10|-16,12|-15,14|-13,15|-11,17|-9,18|-6,19|-4,20|-1,20|1,20|4,20|6,19|9,18|11,17|13,15|15,14|16,12|18,10|19,7|19,5|20,3|20,0|20,-3|19,-5|19,-7|18,-10|16,-12|15,-14|13,-15|11,-17|9,-18|6,-19|4,-20|1,-20|-1,-20|-4,-20|-6,-19|-9,-18|-11,-17|-13,-15|-15,-14|-16,-12|-18,-10|-19,-7|-19,-5|-20,-3")

hgs := HotGestures()
hgs.Register(leftSlide, "Backspace", _ => Send("{BackSpace}"))
hgs.Register(rightSlide, "Wrap", _ => Send("{Enter}"))
hgs.Register(circle, "Select All", _ => Send("^a"))

HotIfWinactive("ahk_class Notepad")
hgs.Hotkey("RButton")
HotIfWinactive()