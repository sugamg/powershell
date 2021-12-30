#This script is to update a release definition in an organization to set the approvals on the fly
#Create a PAT with Full Access
#Set the PAT and Organization name in the params


$Organization = "https://vsrm.dev.azure.com/sugamgupta/Git-Training/"
$ApiVersion = '6.0'
$DefinitionId = 4
 
function Get-Authentication {
        Write-Host "Initialize authentication context"
        $Header = @{authorization = "Bearer $env:SYSTEM_ACCESSTOKEN"}
        return $Header
}

$Header = Get-Authentication

function Get-ReleaseDefinition {

        $Uri = "$($Organization)_apis/release/definitions/$($DefinitionId)?api-version=$($ApiVersion)"

        Write-Host "Getting the release definition with ID $DefinitionId"

        try 
        {
            $Response = Invoke-RestMethod -Uri $Uri `
                                          -Method Get `
                                          -ContentType "application/json" `
        } 
        catch 
        {
            Write-Host "URI": $Uri
            Write-Host "Status code:" $_.Exception.Response.StatusCode.value__ 
            Write-Host "Exception reason:" $_.Exception.Response.ReasonPhrase
            Write-Host "Exception message:" $_.Exception.Message
        }                              
        
        Write-Host "Returning the response for release definition"
        return $Response
}

$ReleaseDefinition = Get-ReleaseDefinition

function Get-jsonFile {
param ( $FilePath )
    $file = Get-Content $FilePath
    $Json = $file | ConvertFrom-Json
    return $Json
}


Write-Host "checking isAutomated"
If($ReleaseDefinition.environments.preDeployApprovals.approvals.isAutomated){
    Write-Host "Approvals not present in release definition. Will Add now."
    $JsonFile = Get-jsonFile -FilePath ".\release.json"
}
else{
    Write-Host "Approvals already present in release definition. Removing approvals."
    $JsonFile = Get-jsonFile -FilePath ".\releaseNoApproval.json"
}

Write-Host "Updating revision on Json. Current revision is $($ReleaseDefinition.revision)"
$JsonFile.revision = $ReleaseDefinition.revision
Write-Host "Revision set to $($JsonFile.revision) on Json file"
$JsonFile = $JsonFile | ConvertTo-Json -Depth 50

function Update-ReleaseDefinition {
        param ( $ReleaseJson )
        
        $Uri = "$($Organization)_apis/release/definitions/$($DefinitionId)?api-version=$($ApiVersion)"

        try 
        {
            $ReleaseJson
            $Response = Invoke-RestMethod -Uri $Uri -Method Put -Headers $Header -ContentType "application/json" -Body ([System.Text.Encoding]::UTF8.GetBytes($ReleaseJson)) -UseBasicParsing
        } 
        catch 
        {
            Write-Host "URI": $Uri
            Write-Host "Status code:" $_.Exception.Response.StatusCode.value__ 
            Write-Host "Exception reason:" $_.Exception.Response.ReasonPhrase
            Write-Host "Exception message:" $_.Exception.Message
        }   
}

Update-ReleaseDefinition -ReleaseJson $JsonFile
