# Norton-RAM-Monitor.ps1 - v1.1
# Monitora l'uso della RAM dei processi Norton 360/NIS con grafico live
# Salva i dati in CSV e in un log testuale

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms.DataVisualization

$script:workDir = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
$script:logFile = $null
$script:csvPath = Join-Path ([Environment]::GetFolderPath("MyDocuments")) "NortonMonitor.csv"

# ============================================
# LOGGING E CSV
# ============================================
function Start-Log {
    $ts = Get-Date -Format "yyyyMMdd_HHmmss"
    $script:logFile = Join-Path $script:workDir "NortonMonitor_$ts.log"
    "--- NORTON RAM MONITOR LOG ---" | Set-Content -Path $script:logFile -Encoding UTF8
}

function Log-Event {
    param([string]$Message)
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $txtEvents.AppendText("$timestamp - $Message`r`n")
    $txtEvents.SelectionStart = $txtEvents.TextLength
    $txtEvents.ScrollToCaret()
    if ($script:logFile) { Add-Content -Path $script:logFile -Value "$timestamp - $Message" -Encoding UTF8 }
}

function Write-Csv {
    param([string]$Process, [double]$Value)
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $line = "$timestamp,$Process,$Value"
    for ($i = 1; $i -le 5; $i++) {
        try { Add-Content -Path $script:csvPath -Value $line -ErrorAction Stop; return }
        catch { Start-Sleep -Milliseconds 500 }
    }
}

function Get-RamMB {
    param([string[]]$ProcessNames)
    $total = 0
    foreach ($name in $ProcessNames) {
        $p = Get-Process -Name $name -ErrorAction SilentlyContinue
        if ($p) { $total += ($p | Measure-Object WorkingSet64 -Sum).Sum }
    }
    return [math]::Round($total / 1MB, 1)
}

# ============================================
# INIT CSV
# ============================================
if (-not (Test-Path $script:csvPath)) {
    "Timestamp,Process,RAM_MB" | Out-File -FilePath $script:csvPath -Encoding UTF8
}
Start-Log

# ============================================
# GUI
# ============================================
$form = New-Object System.Windows.Forms.Form
$form.Text = "Norton 360 RAM Monitor + Grafico Live"
$form.Size = New-Object System.Drawing.Size(800, 660)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false
$form.BackColor = [System.Drawing.Color]::FromArgb(240, 240, 245)

$lblTitle = New-Object System.Windows.Forms.Label
$lblTitle.Text = "Monitoraggio RAM Norton 360 + Grafico"
$lblTitle.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
$lblTitle.Location = New-Object System.Drawing.Point(20, 10)
$lblTitle.AutoSize = $true
$form.Controls.Add($lblTitle)

# Label valori
function New-ProcessLabel {
    param($text, $y)
    $lblName = New-Object System.Windows.Forms.Label
    $lblName.Text = $text
    $lblName.Location = New-Object System.Drawing.Point(20, $y)
    $lblName.Size = New-Object System.Drawing.Size(220, 30)
    $form.Controls.Add($lblName)

    $lblValue = New-Object System.Windows.Forms.Label
    $lblValue.Text = "0 MB"
    $lblValue.Location = New-Object System.Drawing.Point(250, $y)
    $lblValue.Size = New-Object System.Drawing.Size(100, 30)
    $lblValue.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $form.Controls.Add($lblValue)
    return $lblValue
}

$lblSVCValue   = New-ProcessLabel "Servizio principale" 50
$lblUIValue    = New-ProcessLabel "Interfaccia utente" 85
$lblFWValue    = New-ProcessLabel "Firewall" 120
$lblToolsValue = New-ProcessLabel "Tools Service" 155
$lblVPNValue   = New-ProcessLabel "VPN Service" 190
$lblTotalValue = New-ProcessLabel "TOTALE Norton" 225

# Grafico
$chart = New-Object System.Windows.Forms.DataVisualization.Charting.Chart
$chart.Location = New-Object System.Drawing.Point(20, 260)
$chart.Size = New-Object System.Drawing.Size(740, 220)
$chart.BackColor = "White"
$chart.BorderlineDashStyle = "Solid"
$chart.BorderlineWidth = 2
$chart.BorderlineColor = "Gray"

$chartArea = New-Object System.Windows.Forms.DataVisualization.Charting.ChartArea
$chartArea.AxisX.Title = "Tempo (ultimi 5 minuti)"
$chartArea.AxisY.Title = "RAM (MB)"
$chartArea.AxisY.Minimum = 0
$chartArea.AxisX.LabelStyle.Enabled = $false
$chart.ChartAreas.Add($chartArea)

$series = @{}
$colors = @("Blue", "Green", "Orange", "Purple", "Red", "DarkCyan")
$processes = @("Servizio principale", "Interfaccia utente", "Firewall", "Tools", "VPN", "TOTALE")
foreach ($i in 0..5) {
    $series[$processes[$i]] = New-Object System.Windows.Forms.DataVisualization.Charting.Series
    $series[$processes[$i]].ChartType = "Line"
    $series[$processes[$i]].BorderWidth = 3
    $series[$processes[$i]].Color = $colors[$i]
    $series[$processes[$i]].Name = $processes[$i]
    $chart.Series.Add($series[$processes[$i]])
}
$form.Controls.Add($chart)

# Log eventi
$txtEvents = New-Object System.Windows.Forms.TextBox
$txtEvents.Multiline = $true
$txtEvents.ReadOnly = $true
$txtEvents.ScrollBars = "Vertical"
$txtEvents.Location = New-Object System.Drawing.Point(20, 490)
$txtEvents.Size = New-Object System.Drawing.Size(740, 80)
$txtEvents.Font = New-Object System.Drawing.Font("Consolas", 9)
$form.Controls.Add($txtEvents)

# Soglia e pulsanti
$lblThreshold = New-Object System.Windows.Forms.Label
$lblThreshold.Text = "Soglia allarme (MB):"
$lblThreshold.Location = New-Object System.Drawing.Point(20, 580)
$form.Controls.Add($lblThreshold)

$txtThreshold = New-Object System.Windows.Forms.TextBox
$txtThreshold.Text = "800"
$txtThreshold.Location = New-Object System.Drawing.Point(160, 577)
$txtThreshold.Width = 80
$form.Controls.Add($txtThreshold)

$btnApply = New-Object System.Windows.Forms.Button
$btnApply.Text = "Applica"; $btnApply.Location = New-Object System.Drawing.Point(250, 575); $btnApply.BackColor = "DodgerBlue"; $btnApply.ForeColor = "White"; $btnApply.FlatStyle = "Flat"
$form.Controls.Add($btnApply)

$btnStart = New-Object System.Windows.Forms.Button
$btnStart.Text = "Start"; $btnStart.Location = New-Object System.Drawing.Point(380, 575); $btnStart.BackColor = "LightGreen"; $btnStart.FlatStyle = "Flat"
$form.Controls.Add($btnStart)

$btnStop = New-Object System.Windows.Forms.Button
$btnStop.Text = "Stop"; $btnStop.Location = New-Object System.Drawing.Point(480, 575); $btnStop.BackColor = "Tomato"; $btnStop.ForeColor = "White"; $btnStop.FlatStyle = "Flat"
$form.Controls.Add($btnStop)

$btnOpenCsv = New-Object System.Windows.Forms.Button
$btnOpenCsv.Text = "Apri CSV"; $btnOpenCsv.Location = New-Object System.Drawing.Point(580, 575); $btnOpenCsv.BackColor = "Orange"; $btnOpenCsv.FlatStyle = "Flat"
$form.Controls.Add($btnOpenCsv)

$btnExit = New-Object System.Windows.Forms.Button
$btnExit.Text = "Esci"; $btnExit.Location = New-Object System.Drawing.Point(680, 575); $btnExit.BackColor = "IndianRed"; $btnExit.ForeColor = "White"; $btnExit.FlatStyle = "Flat"
$form.Controls.Add($btnExit)

# Timer
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 5000
$script:thresholdMB = 800

$data = @{
    "Servizio principale" = @("NortonSvc")
    "Interfaccia utente"  = @("Norton", "NortonSecurity", "NortonUI")
    "Firewall"            = @("afwServ")
    "Tools"               = @("nllToolsSvc")
    "VPN"                 = @("VpnSvc")
}

function Monitor-Processes {
    $values = @{}
    $total = 0

    foreach ($key in $data.Keys) {
        $ram = Get-RamMB $data[$key]
        $values[$key] = $ram
        $total += $ram
    }
    $values["TOTALE"] = [math]::Round($total, 1)

    $lblSVCValue.Text   = "$($values['Servizio principale']) MB"
    $lblUIValue.Text    = "$($values['Interfaccia utente']) MB"
    $lblFWValue.Text    = "$($values['Firewall']) MB"
    $lblToolsValue.Text = "$($values['Tools']) MB"
    $lblVPNValue.Text   = "$($values['VPN']) MB"
    $lblTotalValue.Text = "$($values['TOTALE']) MB"
    $lblTotalValue.ForeColor = if ($values['TOTALE'] -gt $script:thresholdMB) { "Red" } else { "Black" }

    if ($script:thresholdMB -gt 0 -and $values['TOTALE'] -gt $script:thresholdMB) {
        Log-Event "TOTALE Norton ha superato la soglia: $($values['TOTALE']) MB"
        Write-Csv -Process "TOTALE" -Value $values['TOTALE']
    }

    $now = Get-Date
    foreach ($proc in $processes) {
        $series[$proc].Points.AddXY($now.ToString("HH:mm:ss"), $values[$proc])
        if ($series[$proc].Points.Count -gt 60) { $series[$proc].Points.RemoveAt(0) }
    }

    $maxY = ($values.Values | Measure-Object -Maximum).Maximum * 1.1
    if ($maxY -lt 100) { $maxY = 100 }
    $chart.ChartAreas[0].AxisY.Maximum = [math]::Ceiling($maxY / 100) * 100
}

$btnApply.Add_Click({
    $val = 0
    if ([int]::TryParse($txtThreshold.Text, [ref]$val)) {
        $script:thresholdMB = $val
        Log-Event "Soglia aggiornata: $script:thresholdMB MB"
    } else {
        [System.Windows.Forms.MessageBox]::Show("Inserire un numero valido", "Errore", "OK", "Error")
    }
})

$btnStart.Add_Click({ $timer.Start(); Log-Event "Monitoraggio avviato (ogni 5s)" })
$btnStop.Add_Click({ $timer.Stop(); Log-Event "Monitoraggio fermato" })
$btnOpenCsv.Add_Click({ if (Test-Path $script:csvPath) { Invoke-Item $script:csvPath } else { Log-Event "CSV non trovato" } })
$btnExit.Add_Click({ $timer.Stop(); $form.Close() })
$timer.Add_Tick({ Monitor-Processes })

Log-Event "Applicazione pronta. CSV: $script:csvPath"
$form.ShowDialog() | Out-Null