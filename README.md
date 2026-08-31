.SYNOPSIS
    Monitors CPU and RAM metrics for a Meraki MX device in real-time with history.
.DESCRIPTION
    Fetches CPU performance score and RAM usage every minute, displays a live dashboard,
    and logs data to CSV for historical tracking.
.EXAMPLE
    .\Monitor-MerakiMXMetrics.ps1 -Serial "Q2YN-W3AD-VSTA" -OrgId "1278208"
