#Requires AutoHotkey v2.0
#SingleInstance Force
CoordMode "Mouse", "Screen"

; Separate Fortnite menu-loop macro by Krstic.
; It only runs at 1920x1080 and searches supplied PLAY AGAIN and lobby PLAY images.

requiredImages := [
    A_ScriptDir "\images\PlayAgainLeaveTeam.png",
    A_ScriptDir "\images\PlayAgainNormal.png",
    A_ScriptDir "\images\PlayAgain.png",
    A_ScriptDir "\images\LobbyPlay.png",
    A_ScriptDir "\images\PirateShopAccess.png"
]
for imagePath in requiredImages {
    if !FileExist(imagePath) {
        MsgBox "The macro image files are missing. Right-click the ZIP, choose Extract All, then run Fortnite Queue Loop.ahk from the extracted folder with its images folder beside it.", "Extract the macro first", "Icon!"
        ExitApp
    }
}
if (A_ScreenWidth != 1920 || A_ScreenHeight != 1080) {
    MsgBox "Fortnite Queue Loop requires a 1920 x 1080 display. Current display: " A_ScreenWidth " x " A_ScreenHeight ".", "Resolution required", "Icon!"
    ExitApp
}

running := false
lastActionKind := ""
lastActionAt := 0
imageVariation := 55
gamesCompleted := 0
sessionStart := 0
sessionElapsedMs := 0
webhookUrl := ""
notifyEachGame := false
sendSummaryOnStop := true
tokenNoticeEnabled := true
tokenWasVisible := false

statsGui := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20", "Fortnite session stats")
statsGui.BackColor := "173B6C"
statsGui.SetFont("s8 Bold cD9E7F5", "Segoe UI")
statsGui.AddText("x10 y8 w240 h18 Center", "FORTNITE SESSION")
statsGui.SetFont("s10 Bold cFFFFFF", "Segoe UI")
statsState := statsGui.AddText("x10 y29 w240 h20 Center", "STOPPED")
statsGui.SetFont("s9 cFFFFFF", "Segoe UI")
statsGames := statsGui.AddText("x10 y52 w240 h18 Center", "Games completed: 0")
statsRuntime := statsGui.AddText("x10 y72 w240 h18 Center", "Running time: 00:00:00")

app := Gui("", "Fortnite Queue Loop | By Krstic")
app.BackColor := "F3F6FA"
app.MarginX := 18
app.MarginY := 16
app.SetFont("s17 Bold c173B6C", "Segoe UI")
app.AddText("w360 h30", "FORTNITE QUEUE LOOP")
app.SetFont("s9 c637184", "Segoe UI")
app.AddText("w360 h38", "Clicks PLAY AGAIN in either results layout, or PLAY in the lobby. It ignores STAY WITH TEAM.")
startButton := app.AddButton("x18 y100 w170 h36", "Start  (F9)")
startButton.OnEvent("Click", StartLoop)
stopButton := app.AddButton("x198 y100 w170 h36 Disabled", "Stop  (F10)")
stopButton.OnEvent("Click", StopLoop)
app.SetFont("s9 c243247", "Segoe UI")
statusLabel := app.AddText("x18 y146 w360 h38", "Ready · Focus Fortnite, then start the loop.")
statsMainLabel := app.AddText("x18 y184 w360 h22", "Games: 0    Runtime: 00:00:00")
app.SetFont("s9 Bold c173B6C", "Segoe UI")
app.AddText("x18 y215 w360 h20", "DISCORD WEBHOOK  (OPTIONAL)")
app.SetFont("s8 c637184", "Segoe UI")
app.AddText("x18 y238 w360 h18", "Paste URL here; it stays in memory and is not saved.")
webhookInput := app.AddEdit("x18 y259 w272 h28 Password", "")
testWebhookButton := app.AddButton("x298 y258 w80 h30", "Test")
testWebhookButton.OnEvent("Click", TestWebhook)
gameNotifyCheckbox := app.AddCheckbox("x18 y296 w360 h22", "Send a Discord message for each finished game")
tokenNotifyCheckbox := app.AddCheckbox("x18 y320 w360 h22 Checked", "Notify Discord when Pirate Shop Access appears")
summaryCheckbox := app.AddCheckbox("x18 y344 w360 h22 Checked", "Send a session summary to Discord when stopped")
app.SetFont("s8 c8793A3", "Segoe UI")
app.AddText("x18 y374 w360 h18 Center", "BY KRSTIC  |  1920 × 1080 ONLY")
app.OnEvent("Close", CloseApp)
app.Show("w400 h410")
Hotkey "F9", StartLoop, "On"
Hotkey "F10", StopLoop, "On"

StartLoop(*) {
    global app, running, startButton, stopButton, statusLabel, lastActionKind
    global gamesCompleted, sessionStart, sessionElapsedMs, webhookUrl, notifyEachGame, sendSummaryOnStop
    global webhookInput, gameNotifyCheckbox, tokenNotifyCheckbox, summaryCheckbox, testWebhookButton
    global tokenNoticeEnabled, tokenWasVisible
    if (A_ScreenWidth != 1920 || A_ScreenHeight != 1080) {
        statusLabel.Text := "Stopped: display must be exactly 1920 x 1080."
        return
    }
    if (running)
        return
    running := true
    lastActionKind := ""
    gamesCompleted := 0
    sessionElapsedMs := 0
    sessionStart := A_TickCount
    webhookUrl := Trim(webhookInput.Value)
    notifyEachGame := gameNotifyCheckbox.Value
    sendSummaryOnStop := summaryCheckbox.Value
    tokenNoticeEnabled := tokenNotifyCheckbox.Value
    tokenWasVisible := false
    startButton.Enabled := false
    stopButton.Enabled := true
    webhookInput.Enabled := false
    gameNotifyCheckbox.Enabled := false
    tokenNotifyCheckbox.Enabled := false
    summaryCheckbox.Enabled := false
    testWebhookButton.Enabled := false
    statusLabel.Text := "Running · Activate Fortnite. F10 stops the loop."
    SetTimer ScanScreen, 1000
    SetTimer UpdateStats, 1000
    ShowStatsOverlay()
    UpdateStats()
    if WinActive("ahk_id " app.Hwnd)
        WinMinimize "ahk_id " app.Hwnd
}

StopLoop(*) {
    global running, startButton, stopButton, statusLabel, statsState
    global webhookInput, gameNotifyCheckbox, tokenNotifyCheckbox, summaryCheckbox, testWebhookButton
    global sessionStart, sessionElapsedMs, webhookUrl, sendSummaryOnStop
    wasRunning := running
    SetTimer ScanScreen, 0
    SetTimer UpdateStats, 0
    if (wasRunning)
        sessionElapsedMs := A_TickCount - sessionStart
    running := false
    startButton.Enabled := true
    stopButton.Enabled := false
    webhookInput.Enabled := true
    gameNotifyCheckbox.Enabled := true
    tokenNotifyCheckbox.Enabled := true
    summaryCheckbox.Enabled := true
    testWebhookButton.Enabled := true
    statsState.Text := "STOPPED"
    statusLabel.Text := "Stopped. Games completed: " gamesCompleted "."
    UpdateStats()
    if (wasRunning && sendSummaryOnStop && webhookUrl != "")
        SendWebhook("Fortnite Queue Loop stopped. Games completed: " gamesCompleted ". Runtime: " FormatRuntime(sessionElapsedMs) ".")
}

CloseApp(*) {
    StopLoop()
    ExitApp()
}

ShowStatsOverlay() {
    global statsGui
    x := Max(0, A_ScreenWidth - 270)
    statsGui.Show("NoActivate x" x " y130 w260 h100")
}

UpdateStats(*) {
    global running, gamesCompleted, sessionStart, sessionElapsedMs, statsState
    global statsGames, statsRuntime, statsMainLabel
    if (running) {
        elapsed := A_TickCount - sessionStart
        statsState.Text := "RUNNING"
    } else {
        elapsed := sessionElapsedMs
        statsState.Text := "STOPPED"
    }
    duration := FormatRuntime(elapsed)
    statsGames.Text := "Games completed: " gamesCompleted
    statsRuntime.Text := "Running time: " duration
    statsMainLabel.Text := "Games: " gamesCompleted "    Runtime: " duration
}

FormatRuntime(milliseconds) {
    totalSeconds := Floor(milliseconds / 1000)
    hours := Floor(totalSeconds / 3600)
    minutes := Floor(Mod(totalSeconds, 3600) / 60)
    seconds := Mod(totalSeconds, 60)
    return Format("{:02}:{:02}:{:02}", hours, minutes, seconds)
}

TestWebhook(*) {
    global webhookInput, statusLabel
    url := Trim(webhookInput.Value)
    if (url = "") {
        statusLabel.Text := "Paste your Discord webhook URL first."
        return
    }
    if (SendWebhook("Fortnite Queue Loop test: Discord webhook connected.", url))
        statusLabel.Text := "Test message sent to Discord."
}

SendWebhook(message, url := "") {
    global webhookUrl, statusLabel
    if (url = "")
        url := webhookUrl
    if (!RegExMatch(url, "^https://(discord\.com|discordapp\.com)/api/webhooks/\d+/[A-Za-z0-9._-]+")) {
        statusLabel.Text := "Webhook URL format looks invalid. Check it and try Test again."
        return false
    }
    try {
        request := ComObject("WinHttp.WinHttpRequest.5.1")
        request.SetTimeouts(3000, 3000, 5000, 5000)
        if (InStr(url, "?"))
            url .= "&wait=true"
        else
            url .= "?wait=true"
        request.Open("POST", url, false)
        request.SetRequestHeader("Content-Type", "application/json")
        quote := Chr(34)
        backslash := Chr(92)
        safeMessage := StrReplace(message, backslash, backslash . backslash)
        safeMessage := StrReplace(safeMessage, quote, backslash . quote)
        safeMessage := StrReplace(safeMessage, "`r", backslash . "r")
        safeMessage := StrReplace(safeMessage, "`n", backslash . "n")
        body := "{" . quote . "content" . quote . ":" . quote . safeMessage . quote . "," . quote . "allowed_mentions" . quote . ":{" . quote . "parse" . quote . ":[]}}"
        request.Send(body)
        if (request.Status >= 200 && request.Status < 300)
            return true
        statusLabel.Text := "Discord returned HTTP " request.Status ". Check the webhook URL."
    } catch {
        statusLabel.Text := "Could not reach Discord. Check the URL and internet connection."
    }
    return false
}

ScanScreen() {
    global running, statusLabel, lastActionKind, lastActionAt, gamesCompleted
    global notifyEachGame, webhookUrl, tokenNoticeEnabled, tokenWasVisible
    if (!running)
        return
    foundX := 0, foundY := 0, foundW := 0, foundH := 0
    if (A_ScreenWidth != 1920 || A_ScreenHeight != 1080) {
        StopLoop()
        return
    }
    try {
        activeProcess := WinGetProcessName("A")
    } catch {
        statusLabel.Text := "Waiting for Fortnite to be active."
        return
    }
    if (!InStr(activeProcess, "FortniteClient")) {
        statusLabel.Text := "Waiting for Fortnite · active app: " activeProcess ". F10 stops the loop."
        return
    }

    tokenVisible := FindPirateShopToken(&tokenX, &tokenY, &tokenW, &tokenH)
    if (tokenVisible) {
        if (!tokenWasVisible && tokenNoticeEnabled && webhookUrl != "")
            SendWebhook("Fortnite Queue Loop: Pirate Shop Access appeared on screen!")
        tokenWasVisible := true
    } else {
        tokenWasVisible := false
    }

    sameActionVisible := false
    if (lastActionKind != "") {
        stillVisible := FindButton(lastActionKind, &foundX, &foundY, &foundW, &foundH)
        if (stillVisible) {
            sameActionVisible := true
            if (A_TickCount - lastActionAt < 6000)
                return
        } else {
            lastActionKind := ""
        }
    }

    if (FindButton("again", &foundX, &foundY, &foundW, &foundH)) {
        if (!(sameActionVisible && lastActionKind = "again")) {
            gamesCompleted += 1
            UpdateStats()
            if (notifyEachGame && webhookUrl != "")
                SendWebhook("Fortnite Queue Loop: finished game " gamesCompleted ". Runtime: " FormatRuntime(A_TickCount - sessionStart) ".")
        }
        Click foundX + foundW // 2, foundY + foundH // 2
        lastActionKind := "again"
        lastActionAt := A_TickCount
        statusLabel.Text := "Clicked PLAY AGAIN · completed " gamesCompleted " game(s)."
    } else if (FindButton("lobby", &foundX, &foundY, &foundW, &foundH)) {
        Click foundX + foundW // 2, foundY + foundH // 2
        lastActionKind := "lobby"
        lastActionAt := A_TickCount
        statusLabel.Text := "Clicked lobby PLAY. Waiting for matchmaking."
    } else {
        statusLabel.Text := "Running · Waiting for PLAY AGAIN or lobby PLAY."
    }
}

FindPirateShopToken(&foundX, &foundY, &foundW, &foundH) {
    global imageVariation
    foundW := 0, foundH := 0
    imagePath := A_ScriptDir "\images\PirateShopAccess.png"
    try {
        if (ImageSearch(&foundX, &foundY, 250, 250, 1670, 540, "*" imageVariation " " imagePath)) {
            foundW := 1041, foundH := 162
            return true
        }
    } catch {
    }
    return false
}

FindButton(kind, &foundX, &foundY, &foundW, &foundH) {
    global imageVariation
    foundW := 0
    foundH := 0
    if (kind = "again") {
        x1 := 1280, y1 := 180, x2 := 1918, y2 := 740
        images := [
            [A_ScriptDir "\images\PlayAgainLeaveTeam.png", 360, 70],
            [A_ScriptDir "\images\PlayAgainNormal.png", 360, 70],
            [A_ScriptDir "\images\PlayAgain.png", 482, 89]
        ]
    } else {
        x1 := 70, y1 := 800, x2 := 520, y2 := 1010
        images := [[A_ScriptDir "\images\LobbyPlay.png", 328, 80]]
    }
    for image in images {
        try {
            if (ImageSearch(&foundX, &foundY, x1, y1, x2, y2, "*" imageVariation " " image[1])) {
                foundW := image[2]
                foundH := image[3]
                return true
            }
        } catch {
            continue
        }
    }
    return false
}
