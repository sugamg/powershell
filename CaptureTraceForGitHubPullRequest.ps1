# Directory to store trace files
$traceDirectory = "..\traces"
if (-not (Test-Path $traceDirectory)) {
    New-Item -Path $traceDirectory -ItemType Directory | Out-Null
}

$counter = 1

gh repo clone sugamg/validateCICD #update repo name here
cd validateCICD #update the repo directory


while ($true) {
    Write-Host "----------------------------------------" -ForegroundColor Cyan
    $timer = Get-date -Format "HH:mm:ss"
    Write-Host "Iteration #$counter - Time: $timer - Starting netsh trace and checking webhook delivery..." -ForegroundColor Yellow

    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $traceFile = "$traceDirectory\trace_$timestamp.etl"
    $traceCabFile = "$traceDirectory\trace_$timestamp.cab"
    git checkout -b "release"

    git commit --allow-empty -m "testing empty commit"
    git push --set-upstream origin release
    
    # Start network trace
    Write-Host "Starting netsh trace..." -ForegroundColor Cyan
    netsh trace start capture=yes tracefile="$traceFile" persistent=no maxSize=500 overwrite=yes | Out-Null

    Start-Sleep -Seconds 5 # Let trace initialize

    try {
        Write-Host "Creating a new pull request..." -ForegroundColor Green
        $pr = gh pr create --title "Iteration $counter" --body "Testing PR creation"
        Write-Host $pr

        Start-Sleep -Seconds 10
        Write-Host "Stopping netsh trace..." -ForegroundColor Red
        netsh trace stop | Out-Null

        #update the webhook URL and ID
        $deliveries = gh api -H "Accept: application/vnd.github+json" `
                             -H "X-GitHub-Api-Version: 2022-11-28" `
                             /repos/sugamg/validateCICD/hooks/554637540/deliveries

        # Parse JSON and get first (latest) delivery
        $del = $deliveries | ConvertFrom-Json
        $statuscode = $del[0].status_code
        $status = $del[0].status
        $guid = $del[0].guid

        Write-Host "Latest delivery GUID: $guid"
        Write-Host "Status: $status"
        Write-Host "Status Code: $statuscode"

        if ($statuscode -eq 500) {
            Write-Host "❌ Status code is 500 - Trace saved: $traceFile" -ForegroundColor Red
            break
        }
        else {
            Write-Host "✅ Status code is $statuscode - Deleting trace..." -ForegroundColor Green
            if (Test-Path $traceFile) {
                Remove-Item $traceFile -Force
                Remove-Item $traceCabFile -Force
                Write-Host "Trace deleted (success)." -ForegroundColor DarkGray
            }
        }
        gh pr close $pr --delete-branch
    }
    catch {
        netsh trace stop | Out-Null
        Write-Host "⚠️ Exception occurred: $($_.Exception.Message)" -ForegroundColor Yellow
        if (Test-Path $traceFile) {
            Write-Host "Trace retained for analysis: $traceFile" -ForegroundColor Red
        }
    }

    $counter++
    Start-Sleep -Seconds 5

}
