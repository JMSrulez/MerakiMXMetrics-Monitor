# 📡 Monitor-MerakiMXMetrics

A PowerShell script that displays real-time **CPU** and **RAM** metrics for a **Cisco Meraki MX** router/firewall, with a compact ASCII-style history chart and automatic CSV export.

![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue?logo=powershell)
![License](https://img.shields.io/badge/license-MIT-green)

---

## ✨ Features

- 🔄 **Automatic refresh** every 60 seconds
- 📊 **Visual history** of measurements as a mini ASCII chart
- 💾 **CSV export** of every measurement for later analysis
- 🛡️ **Resilient to network outages**: if the API call fails, the script displays a clear message (`API Call fail, no network`) and marks the measurement with a `*` in the history, without crashing
- 🎨 Color-coded output directly in the terminal

---

## 📋 Requirements

- Windows PowerShell 5.1+ or PowerShell 7+
- A valid Meraki API key ([how to generate a Meraki API key](https://developer.cisco.com/meraki/api-v1/authorization/))
- The **serial number** of the MX device to monitor
- The corresponding Meraki **organization ID**

---

## 🚀 Installation

1. Clone this repository:

   ```bash
   git clone https://github.com/<your-user>/Monitor-MerakiMXMetrics.git
   cd Monitor-MerakiMXMetrics
   ```

2. Create a `meraki_api_key.txt` file in the same folder as the script, containing only your Meraki API key:

   ```
   your_meraki_api_key_here
   ```

   > ⚠️ **Never commit this file!** It is already excluded via `.gitignore`.

---

## ▶️ Usage

```powershell
.\Monitor-MerakiMXMetrics.ps1 -Serial "Q2YN-W3AD-VSTA" -OrgId "1278208"
```

### Parameters

| Parameter      | Required | Description                                        | Default |
|-----------------|:--------:|-----------------------------------------------------|:-------:|
| `-Serial`       | ✅ Yes    | Serial number of the Meraki MX device                | —       |
| `-OrgId`        | ✅ Yes    | Meraki organization ID                                | —       |
| `-HistorySize`  | ❌ No     | Number of measurements shown in the history           | `80`    |

### Example with a longer history

```powershell
.\Monitor-MerakiMXMetrics.ps1 -Serial "Q2YN-W3AD-VSTA" -OrgId "1278208" -HistorySize 120
```

Stop monitoring at any time with **Ctrl+C**.

---

## 🖥️ Preview

```
=== Live Metrics for Q2YN-W3AD-VSTA (2026-08-31 14:32:00) ===
CPU Performance: 42%
[________________44]
RAM Usage: 61% (982.14 MB / 1610.55 MB)
[________________56]
```

During a network outage:

```
=== Live Metrics for Q2YN-W3AD-VSTA (2026-08-31 14:33:00) ===
CPU Performance: API Call fail, no network
[_______________44*]
RAM Usage: API Call fail, no network
[_______________56*]
```

---

## 📁 Generated CSV file

The script creates (or appends to) a `Meraki_Metrics_History.csv` file with the following columns:

| Column               | Description                              |
|------------------------|--------------------------------------------|
| `Timestamp`            | Date and time of the measurement           |
| `Serial`               | Device serial number                       |
| `OrgId`                | Organization ID                            |
| `PerfScore`            | CPU performance score (%)                  |
| `MemoryUsagePercent`   | RAM usage percentage                       |
| `UsedMemoryMb`         | Used memory (MB)                           |
| `TotalMemoryMb`        | Total memory (MB)                          |

> If the API call fails, the measurement columns contain `FAIL`.

---

## 🔒 Security

- The API key is read from a local file (`meraki_api_key.txt`), never hard-coded in the script.
- Make sure to add this file — as well as the generated CSV — to your `.gitignore`:

  ```gitignore
  meraki_api_key.txt
  Meraki_Metrics_History.csv
  ```

---

## 📄 License

This project is distributed under the [MIT](LICENSE) license.

---

## 🤝 Contributing

Suggestions and pull requests are welcome! Feel free to open an *issue* to report a bug or propose an improvement.
