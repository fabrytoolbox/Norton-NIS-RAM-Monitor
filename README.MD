# 🛡️ Norton NIS RAM Monitor

Monitora l'uso della RAM dei processi di Norton 360/NIS con un grafico in tempo reale.

## ✨ Feature

- ✅ **Monitoraggio in tempo reale** dei 5 processi principali di Norton
- ✅ **Grafico live** (ultimi 5 minuti) per vedere l'andamento della RAM
- ✅ **Soglia di allarme** configurabile (default: 800 MB)
- ✅ **Esportazione CSV** in `Documents\NortonMonitor.csv`
- ✅ **Log su file** per tenere traccia degli eventi
- ✅ **Basso consumo CPU** (aggiornamento ogni 5 secondi)

## 📋 Processi monitorati

| Processo | Nome eseguibile |
|---|---|
| Servizio principale | `NortonSvc` |
| Interfaccia utente | `Norton`, `NortonSecurity`, `NortonUI` |
| Firewall | `afwServ` |
| Tools Service | `nllToolsSvc` |
| VPN Service | `VpnSvc` |

## 📋 Requisiti

- **Windows 10 / 11**
- **PowerShell 7+** (scarica da https://aka.ms/powershell)
- **Norton 360 / NIS** installato

## 🚀 Quick start

```powershell
git clone https://github.com/fabrytoolbox/Norton-RAM-Monitor.git
cd Norton-RAM-Monitor
Unblock-File .\Norton-RAM-Monitor.ps1
.\Norton-RAM-Monitor.ps1

Oppure doppio click su avvia.bat.

🎯 Casi d'uso
Capire quale processo di Norton consuma più RAM

Verificare se Norton causa rallentamenti al PC

Tenere traccia nel tempo dell'uso della RAM (con il CSV)

Diagnosticare problemi di memoria legati a Norton

⚠️ Attenzione
Questo tool è specifico per Norton 360/NIS. Se non usi Norton, non ti serve.

Se i nomi dei processi cambiano in future versioni di Norton, il tool potrebbe non rilevarli. In quel caso, modifica la mappa $data nello script.

📜 Licenza
MIT (vedi LICENSE).

🙏 Crediti
Fabry Toolbox

PowerShell 7 + WinForms + DataVisualization