/************************************************************************
 * @description An Autohotkey library for creating and recognizing any custom mouse gestures.
 * @author Tebayaki
 * @date 2023/9/30
 * @version 1.0
 ***********************************************************************/
class HotGestures {
    __matchInfos := Map()

    __New(maxDistance := 0.1, minTrackLen := 100, penColor := 0xFE4F7F) {
        this.MaxDistance := maxDistance
        this.MinTrackLength := minTrackLen
        this.__drawingBoard := HotGestures.DrawingBoard(penColor)
    }

    __Delete() => this.__drawingBoard.Destroy()

    Register(gesture, comment, callback := "") {
        matchInfo := { Gesture: gesture, Comment: comment, Callback: callback, Matrix: HotGestures.DistanceMatrix(gesture), Excluded: false }
        this.__matchInfos.Set(gesture, matchInfo)
    }

    Unregister(gesture) => this.__matchInfos.Delete(gesture)

    Clear() => this.__matchInfos.Clear()

    Hotkey(keyName, options := "") {
        keyName := GetKeyName(keyName)
        if keyName == ""
            throw Error("invalid key name")
        sendIfNoMoved := !(keyName ~= "Control|Shift|Alt|Win")
        Hotkey("$" keyName, OnHotkey, options)

        OnHotkey(_) {
            this.Start()
            KeyWait(keyName)
            this.Stop()
            if this.Result.Valid {
                if this.__match && this.__match.Callback is Func
                    this.__match.Callback.Call(this.Result)
            }
            else if sendIfNoMoved {
                Send("{" keyName "}")
            }
        }
    }

    StartAndWait(keyName, &result) {
        if GetKeyName(keyName) == ""
            throw Error("invalid key name", , keyName)
        this.Start()
        KeyWait(keyName)
        this.Stop()
        result := this.Result
        return this.Result.Valid
    }

    Start() {
        CoordMode("Mouse", "Screen")
        MouseGetPos(&x, &y)
        this.__lastX := x
        this.__lastY := y
        this.__drawingBoard.MoveTo(x, y)
        this.__trackLen := 0
        this.__match := ""
        this.__vectors := []
        for , mi in this.__matchInfos {
            mi.Excluded := false
            mi.Matrix.Clear()
        }
        this.Result := { Valid: false, Vectors: this.__vectors, MatchedGesture: "", Distance: "", Comment: "", }
        this.__mouseHook := HotGestures.MouseHook(this.__OnMouseMove.Bind(this))
        this.__drawingBoard.Show()
    }

    Stop() {
        this.__mouseHook := ""
        if this.__trackLen >= this.MinTrackLength {
            this.Result.Valid := true
            if this.__match {
                this.Result.MatchedGesture := this.__match.Gesture
                this.Result.Distance := this.__match.Distance
                this.Result.Comment := this.__match.Comment
            }
        }
        this.__drawingBoard.Hide()
    }

    __OnMouseMove(x, y) {
        ; anti-shake
        x := (x + this.__lastX) // 2
        y := (y + this.__lastY) // 2
        if x == this.__lastX && y == this.__lastY
            return
        this.__drawingBoard.DrawLineTo(x, y)

        vx := x - this.__lastX
        vy := y - this.__lastY
        newVector := [vx, vy]
        this.__vectors.Push(newVector)
        this.__BuildMatrixes(newVector)

        if this.__trackLen < this.MinTrackLength
            this.__trackLen += Sqrt(vx * vx + vy * vy)
        else if this.__UpdateMatch() {
            tip := ""
            if this.__match {
                name := this.__match.Gesture.Name
                comment := this.__match.Comment
                if name != "" && comment != ""
                    tip := name ": " comment
                else if name == ""
                    tip := comment
                else if comment == ""
                    tip := name
            }
            this.__drawingBoard.DrawTip(tip)
        }

        this.__lastX := x
        this.__lastY := y
    }

    __BuildMatrixes(newVector) {
        for , mi in this.__matchInfos
            if !mi.Excluded
                mi.Matrix.Append(newVector)
    }

    __UpdateMatch() {
        match := ""
        minDist := this.MaxDistance
        for , mi in this.__matchInfos {
            distance := mi.Matrix.TraceBack()
            if distance <= minDist {
                mi.Distance := minDist := distance
                match := mi
            }
            else if distance > 1 {
                mi.Excluded := true
            }
        }
        if this.__match == match
            return false
        this.__match := match
        return true
    }

    class MouseHook {
        __New(function) {
            this.__proc := CallbackCreate(LowLevelMouseHookProc, "F")
            this.__hook := DllCall("SetWindowsHookEx", "int", 14, "ptr", this.__proc, "ptr", 0, "uint", 0, "ptr")

            LowLevelMouseHookProc(nCode, wParam, lParam) {
                if nCode == 0 && wParam == 0x0200
                    function(NumGet(lParam, "int"), NumGet(lParam, 4, "int"))
                return DllCall("CallNextHookEx", "ptr", 0, "int", nCode, "ptr", wParam, "ptr", lParam)
            }
        }

        __Delete() {
            DllCall("UnhookWindowsHookEx", "ptr", this.__hook)
            CallbackFree(this.__proc)
        }
    }

    class DrawingBoard extends Gui {
        __lastTipRect := 0
        __lastTipX := 0
        __lastTipY := 0
        __lastTipW := 0
        __lastTipH := 0

        __New(penColor) {
            super.__New("+LastFound +AlwaysOnTop +ToolWindow +E0x00000020 -Caption -DPIScale")
            this.BackColor := 0
            WinSetTransColor(0)
            this.SetFont("S30", "Microsoft YaHei")

            this.__dc := DllCall("GetDC", "ptr", this.Hwnd, "ptr")
            this.__pen := DllCall("CreatePen", "int", 0, "int", 5, "int", penColor, "ptr")
            DllCall("SelectObject", "ptr", this.__dc, "ptr", this.__pen)

            this.__tip := this.AddText("Background0 +E0x00080000 x0 y0 w" A_ScreenWidth " h" A_ScreenHeight - 1)
            WinSetTransColor("0 200", this.__tip)

            this.__tipDC := DllCall("GetDC", "ptr", this.__tip.Hwnd, "ptr")
            this.__tipMemDC := DllCall("CreateCompatibleDC", "ptr", this.__tipDC, "ptr")
            tipBmp := DllCall("CreateCompatibleBitmap", "ptr", this.__tipDC, "int", A_ScreenWidth, "int", A_ScreenHeight, "ptr")
            DllCall("SelectObject", "ptr", this.__tipMemDC, "ptr", tipBmp)

            this.__blackBrush := DllCall("GetStockObject", "int", 4, "ptr")
            grayBrush := DllCall("GetStockObject", "int", 3, "ptr")
            DllCall("SelectObject", "ptr", this.__tipMemDC, "ptr", grayBrush)

            font := SendMessage(0x0031, 0, 0, this.__tip)
            DllCall("SelectObject", "ptr", this.__tipMemDC, "ptr", font)
            DllCall("SetBkMode", "ptr", this.__tipMemDC, "int", 1)
            DllCall("SetTextColor", "ptr", this.__tipMemDC, "uint", 0xffffff)

            DllCall("DeleteObject", "ptr", tipBmp)
        }

        __Delete() {
            DllCall("DeleteObject", "ptr", this.__pen)
            DllCall("DeleteDC", "ptr", this.__tipMemDC)
            DllCall("ReleaseDC", "ptr", this.__tipDC)
            DllCall("ReleaseDC", "ptr", this.__dc)
        }

        Show() {
            this.Opt("AlwaysOnTop")
            ; A_ScreenHeight - 1 to avoid "do not disturb" mode
            super.Show("NoActivate x0 y0 w" A_ScreenWidth " h" A_ScreenHeight - 1)
        }

        Hide() {
            ; Built-in WinRedraw don't redraw immediately.
            DllCall("RedrawWindow", "ptr", this.__tip.Hwnd, "ptr", 0, "ptr", 0, "uint", 0x205)
            DllCall("RedrawWindow", "ptr", this.Hwnd, "ptr", 0, "ptr", 0, "uint", 0x105)
            super.Hide()
        }

        MoveTo(x, y) => DllCall("MoveToEx", "ptr", this.__dc, "int", x, "int", y, "ptr", 0)

        DrawLineTo(x, y) => DllCall("LineTo", "ptr", this.__dc, "int", x, "int", y)

        DrawTip(text) {
            if text == "" {
                DllCall("RedrawWindow", "ptr", this.__tip.Hwnd, "ptr", 0, "ptr", 0, "uint", 0x105)
                return
            }
            ; calc text size
            DllCall("GetTextExtentPoint32", "ptr", this.__tipMemDC, "str", text, "int", StrLen(text), "int64*", &size := 0)
            w := (size & 0xffffffff) + 100
            h := (size >> 32) + 10
            NumPut("int", left := (A_ScreenWidth - w) // 2,
                "int", top := 200,
                "int", right := left + w,
                "int", bottom := top + h,
                rect := Buffer(16))
            ; erase last tip rect
            if w < this.__lastTipW {
                DllCall("FillRect", "ptr", this.__tipMemDC, "ptr", this.__lastTipRect, "ptr", this.__blackBrush)
                DllCall("RoundRect", "ptr", this.__tipMemDC, "int", left, "int", top, "int", right, "int", bottom, "int", 20, "int", 20)
                DllCall("DrawTextW", "ptr", this.__tipMemDC, "str", text, "int", StrLen(text), "ptr", rect, "uint", 0x125)
                DllCall("BitBlt", "ptr", this.__tipDC, "int", this.__lastTipX, "int", this.__lastTipY, "int", this.__lastTipW, "int", this.__lastTipH, "ptr", this.__tipMemDC, "int", this.__lastTipX, "int", this.__lastTipY, "uint", 0x00CC0020)
            }
            else {
                NumPut("int", left, "int", top, "int", right, "int", bottom, rect)
                DllCall("RoundRect", "ptr", this.__tipMemDC, "int", left, "int", top, "int", right, "int", bottom, "int", 20, "int", 20)
                DllCall("DrawTextW", "ptr", this.__tipMemDC, "str", text, "int", StrLen(text), "ptr", rect, "uint", 0x125)
                DllCall("BitBlt", "ptr", this.__tipDC, "int", left, "int", top, "int", w, "int", h, "ptr", this.__tipMemDC, "int", left, "int", top, "uint", 0x00CC0020)
            }
            this.__lastTipRect := rect
            this.__lastTipX := left
            this.__lastTipY := top
            this.__lastTipW := w
            this.__lastTipH := h
        }
    }

    class Gesture extends Array {
        __New(name, vectors?) {
            valid := false
            if IsSet(vectors) {
                if vectors is String {
                    valid := HotGestures.Gesture.VerifyVectorsString(vectors, , &vectorsArr)
                }
                else if vectors is Array {
                    valid := HotGestures.Gesture.VerifyVectorsArray(vectors, &vectorsArr)
                }
            }
            else {
                valid := HotGestures.Gesture.VerifyVectorsString(name, &name, &vectorsArr)
            }
            if !valid {
                throw Error("invalid parameter(s)")
            }
            this.Name := name
            super.__New(vectorsArr*)
        }

        ToString() {
            vectorsStr := ""
            for v in this
                vectorsStr .= (A_Index == 1 ? "" : "|") v[1] "," v[2]
            return vectorsStr
        }

        Compare(vectors) {
            matrix := HotGestures.DistanceMatrix(this)
            for v in vectors
                matrix.Append(v)
            return matrix.TraceBack()
        }

        static VerifyVectorsArray(vectorsArr, &copy) {
            copy := []
            for v in vectorsArr {
                if v.Length != 2
                    return false
                if !(v[1] is Integer) || !(v[2] is Integer)
                    return false
                copy.Push([v[1], v[2]])
            }
            return true
        }

        static VerifyVectorsString(vectorsStr, &name?, &vectorsArr?) {
            if res := RegExMatch(vectorsStr, "^(?:(.*):)?((?:-?\d+,-?\d+)(?:\|-?\d+,-?\d+)*)$", &m) {
                name := m[1]
                vectorsArr := []
                loop parse m[2], "|" {
                    v := StrSplit(A_LoopField, ",", , 2)
                    vectorsArr.Push([Integer(v[1]), Integer(v[2])])
                }
            }
            return !!res
        }
    }

    class DistanceMatrix extends Array {
        __New(standard) {
            static INF := NumGet(ObjPtr(&_ := 0x7F800000) + A_PtrSize * 2, "float")

            if !len := standard.Length
                throw Error("invalid parameter")

            this.Standard := standard
            this.Capacity := len + 1

            this.RowTemplate := []
            this.RowTemplate.Capacity := len + 1
            this.RowTemplate.Push(INF)

            this.Push(firstRow := this.RowTemplate.Clone())
            firstRow[1] := 0
            loop len
                firstRow.Push(INF)
        }

        Append(newVector) {
            static Distance(a, b) => 1 - (a[1] * b[1] + a[2] * b[2]) / (Sqrt(a[1] ** 2 + a[2] ** 2) * Sqrt(b[1] ** 2 + b[2] ** 2))

            standard := this.Standard
            lastRow := this[-1]

            this.Push(newRow := this.RowTemplate.Clone())
            loop standard.Length
                newRow.Push(Distance(newVector, standard[A_Index]) + Min(newRow[A_Index], lastRow[A_Index], lastRow[A_Index + 1]))
        }

        TraceBack() {
            i := this.Length - 1 , j := this[1].Length - 1 , count := 1
            while i > 1 && j > 1 {
                switch min(a := this[i][j], b := this[i][j + 1], this[i + 1][j]) {
                    case a: i--, j--
                    case b: i--
                    default: j--
                }
                count++
            }
            return this[-1][-1] / (count + i + j - 2)
        }

        Clear() => this.Length := 1
    }
}