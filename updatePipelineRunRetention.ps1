#Update your PAT here
$PAT = ""
$AuthHeader = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f "", $PAT)))

#Update your Organization name here
$organization = "sugam192"

#UPdate your project name here
$project = "BNF"


#update the build definition ID from URL here
$definitionId = “70”


#Update the Build ID's here which you don't want to delete
$retainBuilds = @("18005","17981")

 

#get all builds of your pipeline.

$url = "https://dev.azure.com/$organization/$project/_apis/build/builds?definitions=$definitionId&api-version=6.0"

$builds = Invoke-RestMethod -Uri $url -Method Get -Headers @{
            "content-type" = "application/json" 
            Authorization  = ("Basic {0}" -f $AuthHeader) 
        }


$builds.value | ForEach-Object {

    Write-Host "BuildId" $_.id "- retainedByRelease:" $_.retainedByRelease
    if ($retainBuilds -notcontains $_.id){
        Invoke-RestMethod `
        -Headers @{
            "content-type" = "application/json" 
            Authorization  = ("Basic {0}" -f $AuthHeader) 
        }`
            -Uri ("https://dev.azure.com/sugam192/BNF" + '/_apis/build/builds/' + $_.id + '?api-version=6.0') `
            -Method Patch `
            -Body (ConvertTo-Json @{"retainedByRelease" = 'false' }) | Out-Null

            Write-Host "BuildID" $_.id "- retainedByRelease set to false"
        }

        
}
