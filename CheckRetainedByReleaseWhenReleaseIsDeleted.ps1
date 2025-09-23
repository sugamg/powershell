#Requires -Version 5.1
    [string] $ServerUrl="http://singa2022/"
    [string] $OrgName="DefaultCollection2022"
    [String] $Username="DummyAccountDoesNotNeedtobeValid"
    [String] $PAT="ENTERYOURPAT"
    [Boolean] $DryRun = $True

$ErrorActionPreference = "Stop"

$AuthHeader = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $Username, $PAT)))

function Invoke-AdoRest() {
    Param($CallToMake)
    
    try {
        & Invoke-RestMethod -Headers @{Authorization = ("Basic {0}" -f $AuthHeader) } @Args
    }
    catch {
        Write-Host "StatusCode:" $_.Exception.Response.StatusCode.value__ 
        Write-Host "StatusDescription:" $_.Exception.Response.StatusDescription
    }
}

$CollectionURL = "${ServerUrl}/${OrgName}"

$Projects = (Invoke-AdoRest -Uri ($CollectionURL + "/_apis/projects?api-version=6.0") -Method GET).value

$CollectionTotalCount=0

foreach ($project in $Projects)
{

Write-Output "Team Project: $($project.name)"
Write-Output "------------"

$URL = "${ServerUrl}/${OrgName}/$($project.name)"

#Write-Output $URL 

$BuildDefintionsResult = (Invoke-AdoRest -Uri ($URL + "/_apis/build/definitions?api-version=6.0") -Method GET).value

$ProjectTotalCount=0

foreach ($definitionName in $BuildDefintionsResult) {
    $all = $false

        #Write-Output "Searching for builds retained by deleted releases produced by pipeline $($definitionName.name)"
        $Builds = (Invoke-AdoRest -Uri ($URL + '/_apis/build/builds?definitions=' + $definitionName.id + '&statusFilter=completed&api-version=6.0') -Method GET).value | Where-Object { $_.retainedByRelease -eq $true }

        $count=0
        foreach ($build in $Builds) {
            $deployments = Invoke-AdoRest -Uri ($URL + '/_apis/release/releases?artifactTypeId=Build&artifactVersionId=' + $build.id + '&api-version=6.0') -Method GET
          
            if (($deployments.count -eq 0)) {
               # Write-Output "`Build $URL/_build/results?buildId=$($build.id)&view=results of $($Builddefiniton.name) is marked retained by release which doesn't exist anymore"
               $count++
               $CollectionTotalCount++
               $ProjectTotalCount++
                If (-not $DryRun) {
                    if (-not $all) {
                        $confirmation = Read-Host "Do you want to unretain the build ${build.id} [A (all)/y (yes)/n (no)]?"
                        $all = $confirmation -eq 'A'
                    }
                    
                    if ($confirmation -eq 'y' -or $all) {
                        Invoke-RestMethod `
                            -Headers @{
                            "content-type" = "application/json" 
                            Authorization  = ("Basic {0}" -f $AuthHeader) 
                        }`
                            -Uri ($URL + '/_apis/build/builds/' + $build.id + '?api-version=6.0') `
                            -Method Patch `
                            -Body (ConvertTo-Json @{"retainedByRelease" = 'false' }) | Out-Null
                        #Write-Host "Build ${build.id} from pipeline ${Builddefinition.name} retained by a release that doesn't exist anymore has been unretained" 
                    }
                }
            }
            Write-Output "DEFINITION:$($definitionName.name) =  $count"
        }
        

 } 
 Write-Output ""
 Write-Output "Total Project Count:$ProjectTotalCount"
 Write-Output ""
 Write-Output ""

 }

 Write-Output "Total Collection Count:$CollectionTotalCount"
