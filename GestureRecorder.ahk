#Include HotGestures.ahk
GestureRecorder()

GestureRecorder() {
    hgs := HotGestures()
    testing := false
    animation := ""
    itemIndex := 1
    maxDistance := 0.1

    mainWindow := Gui(, "Gesture Recorder")
    mainWindow.SetFont(, "Cascadia Code")
    mainWindow.AddText(, "F2: edit name | Ctrl+C: copy vectors")
    addBtn := mainWindow.AddButton("Section w120", "Add")
    deleteBtn := mainWindow.AddButton("x+M wp", "Delete")
    genCodeBtn := mainWindow.AddButton("x+M wp", "Generate Code")
    testBtn := mainWindow.AddButton("x+M wp", "Test")
    mainWindow.AddText("x+M wp hp-5 Center 0x200", "Max Distance:")
    distanceEdit := mainWindow.AddEdit("x+M w100", "0.1")
    listview := mainWindow.AddListView("-ReadOnly Center Grid xs w500 h500", ["Name", "Vectors"])
    drawingBoard := mainWindow.AddText("BackgroundWhite Center w500 h500 x+M")
    statusBar := mainWindow.AddStatusBar()

    listview.ModifyCol(1, 100)
    mainWindow.OnEvent("Close", MainWindow_Close)
    addBtn.OnEvent("Click", AddButton_Click)
    deleteBtn.OnEvent("Click", DeleteBtn_Click)
    genCodeBtn.OnEvent("Click", GenCodeBtn_Click)
    testBtn.OnEvent("Click", TestBtn_Click)
    drawingBoard.OnEvent("Click", DrawingBoard_Click)
    listview.OnEvent("ItemFocus", ListView_ItemFocus)
    ; listview.OnEvent("ItemSelect", ListView_ItemSelect)
    OnMessage(0x0100, ListView_DeleteKeyDown)
    OnMessage(0x0102, ListView_CtrlC)
    mainWindow.Show()

    InitDrawingBoard()
    listview.Add(, "↑", "0,-10|0,-10|0,-10|0,-10|0,-10|0,-10|0,-10|0,-10|0,-10|0,-10|0,-10|0,-10|0,-10|0,-10|0,-10|0,-10|0,-10|0,-10|0,-10|0,-10")
    listview.Add(, "↓", "0,10|0,10|0,10|0,10|0,10|0,10|0,10|0,10|0,10|0,10|0,10|0,10|0,10|0,10|0,10|0,10|0,10|0,10|0,10|0,10")
    listview.Add(, "←", "-10,0|-10,0|-10,0|-10,0|-10,0|-10,0|-10,0|-10,0|-10,0|-10,0|-10,0|-10,0|-10,0|-10,0|-10,0|-10,0|-10,0|-10,0|-10,0|-10,0")
    listview.Add(, "→", "10,0|10,0|10,0|10,0|10,0|10,0|10,0|10,0|10,0|10,0|10,0|10,0|10,0|10,0|10,0|10,0|10,0|10,0|10,0|10,0")
    listview.Add(, "circle", "-20,0|-20,3|-19,5|-19,7|-18,10|-16,12|-15,14|-13,15|-11,17|-9,18|-6,19|-4,20|-1,20|1,20|4,20|6,19|9,18|11,17|13,15|15,14|16,12|18,10|19,7|19,5|20,3|20,0|20,-3|19,-5|19,-7|18,-10|16,-12|15,-14|13,-15|11,-17|9,-18|6,-19|4,-20|1,-20|-1,-20|-4,-20|-6,-19|-9,-18|-11,-17|-13,-15|-15,-14|-16,-12|-18,-10|-19,-7|-19,-5|-20,-3")
    ControlFocus(listview)

    MainWindow_Close(mainWindow) {
        animation := ""
        mainWindow.Destroy()
    }

    AddButton_Click(ctrl, info) {
        dialog := Gui("Owner" mainWindow.Hwnd, "Add a gesture")
        dialog.SetFont(, "Cascadia Code")
        dialog.AddText(, "Vectors:")
        vectorsEdit := dialog.AddEdit("w400 r8")
        okBtn := dialog.AddButton("w190", "OK")
        cancelBtn := dialog.AddButton("wp x+M", "Cancel")
        dialog.Show()
        okBtn.OnEvent("Click", OkButton_Click)
        cancelBtn.OnEvent("Click", (ctrl, info) => dialog.Destroy())

        OkButton_Click(ctrl, info) {
            try
                gesture := HotGestures.Gesture(Trim(vectorsEdit.Text, " `r`n`t"))
            catch
                MsgBox("Invalid vectors", "Warming")
            else if AddGesture(gesture)
                dialog.Destroy()
        }
    }

    DeleteBtn_Click(ctrl, info) => DeleteSelections()

    GenCodeBtn_Click(ctrl, info) {
        if CheckDistance(&distance) == ""
            return
        hgsVarName := "hgs"
        part1 := part2 := part3 := ""
        loop listview.GetCount() {
            name := listview.GetText(A_Index, 1)
            vectors := listview.GetText(A_Index, 2)
            varName := "gesture" A_Index
            part1 .= Format('{} := HotGestures.Gesture("{}")`n', varName, name ":" vectors)
            part2 .= Format('{}.Register({}, "")`n', hgsVarName, varName)
            part3 .= Format('case {}: `; {}`n            ', varName, name)
        }
        part3 .= "default: return"
        code := Format("
        (
            {1}
            {2} := HotGestures({3})
            {4}
            $RButton::{
                {2}.Start()
                KeyWait("RButton")
                {2}.Stop()
                if {2}.Result.Valid {
                    switch {2}.Result.MatchedGesture {
                        {5}
                    }
                }
                else {
                    Send("{RButton}")
                }
            }
        )", part1, hgsVarName, Format("{:g}", distance), part2, part3)
        codeUi := Gui("+Owner" mainWindow.Hwnd, "Gesture code")
        codeUi.SetFont(, "Cascadia Code")
        codeUi.AddEdit("Multi HScroll w800 h500", code)
        codeUi.Show()
    }

    TestBtn_Click(ctrl, info) {
        if testing {
            hgs.Clear()
            testBtn.Text := "Test"
            statusBar.Text := ""
            addBtn.Opt("-Disabled")
            deleteBtn.Opt("-Disabled")
            genCodeBtn.Opt("-Disabled")
            distanceEdit.Opt("-Disabled")
            testing := false
        }
        else {
            if !CheckDistance(&distance)
                return
            hgs.MaxDistance := distance
            loop listview.GetCount() {
                name := listview.GetText(A_Index, 1)
                vectors := listview.GetText(A_Index, 2)
                gestrue := HotGestures.Gesture(name ":" vectors)
                hgs.Register(gestrue, "")
            }
            animation := ""
            InitDrawingBoard()
            testBtn.Text := "Stop Test"
            statusBar.Text := "Testing"
            addBtn.Opt("Disabled")
            deleteBtn.Opt("Disabled")
            genCodeBtn.Opt("Disabled")
            distanceEdit.Opt("Disabled")
            testing := true
        }
    }

    DrawingBoard_Click(ctrl, info) {
        animation := ""
        InitDrawingBoard("")
        if hgs.StartAndWait("LButton", &result) {
            if testing {
                if result.MatchedGesture
                    statusBar.Text := result.MatchedGesture.Name " matched, distance: " result.Distance
                else
                    statusBar.Text := "no match"
            }
            else {
                newGesture := HotGestures.Gesture("Unnamed" itemIndex++, result.Vectors)
                AddGesture(newGesture)
            }
        }
        else {
            InitDrawingBoard()
        }
    }

    ListView_CtrlC(wp, lp, msg, hwnd) {
        if hwnd == listview.Hwnd && wp == 3 {
            row := 0
            str := ""
            while row := listview.GetNext(row)
                str .= listview.GetText(row, 1) ":" listview.GetText(row, 2) "`n"
            if str != "" {
                A_Clipboard := Trim(str)
                statusBar.Text := "Copied!"
            }
        }
    }

    ListView_DeleteKeyDown(wp, lp, msg, hwnd) {
        if hwnd == listview.Hwnd && wp == 0x2E
            DeleteSelections()
    }

    ListView_ItemFocus(ctrl, item) {
        ; if focus changed because of deleting a item, the item index passed in is incorrect.
        if item := listview.GetNext(0, "Focused") {
            name := listview.GetText(item, 1)
            vectorsStr := listview.GetText(item, 2)
            gesture := HotGestures.Gesture(name, vectorsStr)
            animation := CreateAnimation(gesture)
        }
    }

    AddGesture(newGesture) {
        prompt := ""
        for name, vectorsStr in GesturesEnumerator() {
            d := newGesture.Compare(HotGestures.Gesture(name ":" vectorsStr))
            if d <= maxDistance {
                prompt .= "`n    Name: " name "`tDistance: " d
            }
        }
        if prompt != "" {
            mainWindow.Opt("OwnDialogs")
            prompt := "This gesture is too similar to the following:" prompt "`n`nAre you sure to add it?"
            if "No" = MsgBox(prompt, "Warming", 0x4)
                return false
        }
        listview.Add("Vis Focus", newGesture.Name, newGesture.ToString())
        animation := CreateAnimation(newGesture)
        return true
    }

    GesturesEnumerator() {
        return enum
        enum(&name, &vectors) {
            if A_Index > listview.GetCount()
                return false
            name := listview.GetText(A_Index, 1)
            vectors := listview.GetText(A_Index, 2)
        }
    }

    CreateAnimation(gesture, interval := 20, repeatInterval := 1000) {
        InitDrawingBoard("")
        points := []
        points.Capacity := gesture.Length
        x := y := left := top := right := bottom := 0
        for v in gesture {
            points.Push([x += v[1], y += v[2]])
            left := Min(x, left)
            top := Min(y, top)
            right := Max(x, right)
            bottom := Max(y, bottom)
        }
        w := right - left
        h := bottom - top

        dc := DllCall("GetDC", "ptr", drawingBoard.Hwnd, "ptr")
        ; transform
        drawingBoard.GetPos(, , &boardW, &boardH)
        boardW *= A_ScreenDPI / 96
        boardH *= A_ScreenDPI / 96
        xform := Buffer(24)
        scale := 1
        if w > boardH - 5 || h > boardH - 5 {
            scale := Min((boardW - 10) / w, (boardH - 10) / h)
            w *= scale, h *= scale, left *= scale, top *= scale
        }
        NumPut("float", scale, "float", 0, "float", 0, "float", scale, "float", (boardW - w) / 2 - left, "float", (boardH - h) / 2 - top, xform)
        DllCall("SetGraphicsMode", "ptr", dc, "int", 2)
        DllCall("SetWorldTransform", "ptr", dc, "ptr", xform)

        pen := DllCall("CreatePen", "int", 0, "int", 5, "uint", 0xFE4F7F, "ptr")
        DllCall("SelectObject", "ptr", dc, "ptr", pen, "ptr")

        index := 1
        SetTimer(LineToNextPoint, interval)
        return { __Delete: __Delete }

        LineToNextPoint() {
            if index == 0 {
                InitDrawingBoard("")
                DllCall("MoveToEx", "ptr", dc, "int", 0, "int", 0, "ptr", 0)
                SetTimer(LineToNextPoint, interval)
                index++
            }
            if index <= points.Length {
                DllCall("LineTo", "ptr", dc, "int", points[index][1], "int", points[index][2])
                index++
            }
            else {
                SetTimer(LineToNextPoint, -repeatInterval)
                index := 0
            }
        }

        __Delete(_) {
            SetTimer(LineToNextPoint, 0)
            DllCall("DeleteObject", "ptr", pen)
            DllCall("ReleaseDC", "ptr", dc)
        }
    }

    InitDrawingBoard(text?) {
        text := text ?? "Draw gestures here with the left button"
        dc := DllCall("GetDC", "ptr", drawingBoard.Hwnd, "ptr")
        drawingBoard.GetPos(, , &boardW, &boardH)
        boardW *= A_ScreenDPI / 96
        boardH *= A_ScreenDPI / 96
        DllCall("Rectangle", "ptr", dc, "int", 0, "int", 0, "int", boardW, "int", boardH)
        if text {
            rect := Buffer(16)
            NumPut("int64", 0, "int", boardW, "int", boardH, rect)
            font := SendMessage(0x0031, 0, 0, drawingBoard)
            DllCall("SelectObject", "ptr", dc, "ptr", font, "ptr")
            DllCall("DrawTextW", "ptr", dc, "str", text, "int", StrLen(text), "ptr", rect, "uint", 0x125)
        }
        DllCall("ReleaseDC", "ptr", dc)
    }

    DeleteSelections() {
        if testing {
            statusBar.Text := "Please stop test"
        }
        else {
            row := 0
            arr := []
            while row := listview.GetNext(row)
                arr.InsertAt(1, row)
            else
                return
            animation := ""
            for r in arr
                listview.Delete(r)
            statusBar.Text := arr.Length " items deleted"
        }
        if !listview.GetNext(0, "Focused") {
            InitDrawingBoard()
        }
    }

    CheckDistance(&distance) {
        distanceStr := distanceEdit.Text
        if IsNumber(distanceStr) {
            distance := Number(distanceStr)
            if distance >= 0 && distance <= 2
                return true
        }
        statusBar.Text := "invalid distance"
        return false
    }
}