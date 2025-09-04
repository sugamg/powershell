$pat = ""

$collectionUrl = ""

$project = ""


function LogError {
    $exception = $_.Exception;
    Write-Host $exception  -ForegroundColor Red;
    if($_.ErrorDetails) {
        $errorDetails = ConvertFrom-Json $_.ErrorDetails
        Write-Host "ExceptionType: $($errorDetails.typeKey)`nExceptionMessage: $($errorDetails.message)`n"  -ForegroundColor Red;
    }
    if($exception.Response) {
        $resp = $exception.Response;
        Write-Host "Status Code: $($resp.StatusCode) $($resp.StatusDescription)`n" -ForegroundColor Red
        $sr = New-Object System.IO.StreamReader($resp.GetResponseStream());
        $sr.BaseStream.Position = 0
        $sr.DiscardBufferedData();
        $txt = $sr.ReadToEnd();
        Write-Host $txt -ForegroundColor Red;
    }
}

function SplitToChunks {
    param (
        $chunkSize,
        $array
    )

    $out = @();
    $parts = [math]::Ceiling($array.Length / $chunkSize);

    Write-Host "Chunk size: $chunkSize" ;
    Write-Host "Creating $($parts) chunk(s)." ;

    # Splitting the array to chunks of the same size
    for($i=0; $i -le $parts; $i++){
        $start = $i*$chunkSize
        $end = (($i+1)*$chunkSize)-1
        $out += ,@($array[$start..$end])
    }
    return $out;
}

function RemoveLeases {
    param (
        $ids
    )
    Write-Host "> Removing ids [$ids]" -ForegroundColor DarkGray;
    $ids = $ids -join ",";
    $ruri = "$collectionUrl/$project/_apis/build/retention/leases?ids=$ids&api-version=6.1-preview.1";
    Write-Host "> [DELETE] $ruri" -ForegroundColor DarkGray;
    Invoke-RestMethod -uri $ruri -method DELETE -Headers @{ Authorization = $accessToken } -ContentType "application/json";
}

try {
    $ids = @();
    $excludeDefinitionIds = @();

    $owner = "User:Legacy Retention Model";
    $chunkSize = 100;

    Write-Host "--------------------------------" -ForegroundColor Green;
    Write-Host "Retention Leases Removing Script" -ForegroundColor Green;
    Write-Host "--------------------------------" -ForegroundColor Green;
    Write-Host "CollectionUrl: $collectionUrl";
    Write-Host "Project: $project";
    Write-Host "Owner: $owner";

    if(!$collectionUrl -or !$project -or !$pat) { 
        Write-Host 'One of the required variables is undefined. Please, set the value for $org, $project and $pat and rerun the script again.' -ForegroundColor Red;
        Exit;
    }

    # Create ascess token
    $encoded = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes([string]::Format("{0}:{1}", "", $pat)));
    $accessToken = "Basic $encoded"

    # Request leases with ownerId = $owner
    $leasesUrl = "$collectionUrl/$project/_apis/build/retention/leases?ownerId=$owner&api-version=7.0";
    $response = Invoke-RestMethod -uri $leasesUrl -method GET -Headers @{ Authorization = $accessToken } -ContentType "application/json";

    if($response.count -eq 0) {
        Write-Host "No retention leases were found."  -ForegroundColor Yellow;
        Continue;
    }

    Write-Host "Found $response.count leases" -ForegroundColor DarkGray;

    $ids = $response.value | ForEach-Object { $_.leaseId };

    if($($ids.count) -eq 0) {
        Write-Host "No Leases found." -ForegroundColor Yellow; 
        Exit;    
    }
    else {
        Write-Host "Found $($ids.count) leases" -ForegroundColor DarkGray;
    }

    Write-Host "Are you sure you want to remove $($ids.count) lease(s)?" -ForegroundColor Yellow;    
    $confirm = Read-host "Please confirm [Y/N]";
    if($confirm -ne "Y") {
        Exit;    
    }

    # Split all leases into chunks and remove them one by one
    Write-Host "Removing $($ids.count) lease(s).";
    $chunks = SplitToChunks -array $ids -chunkSize $chunkSize;

    # remove leases in chunks
    for($i=0; $i -lt $chunks.length; $i++) {
        $chunk = $chunks[$i];
        if(!$chunk.length) { break };
        RemoveLeases -ids $chunk;
    }
    Write-Host "Done" -ForegroundColor Green;
} catch {
    LogError;
}
