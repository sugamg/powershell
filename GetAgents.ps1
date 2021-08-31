#This script is to get the list of all the agents in an organization along with its version details
#Create a PAT with Full Access
#Set the PAT and Organization name in the params

Param
(
    [string]$PAT="",
    [string]$Organization=""
)
$SelfHostedAgentCapabilities = @()
$AzureDevOpsAuthenicationHeader = @{Authorization = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($PAT)")) }
$UriOrganization = "https://dev.azure.com/$($Organization)/"
$UriPools = $UriOrganization + '/_apis/distributedtask/pools?api-version=6.0'
$PoolsResult = Invoke-RestMethod -Uri $UriPools -Method get -Headers $AzureDevOpsAuthenicationHeader
$AgentDetails = @()
Foreach ($pool in $PoolsResult.value)
{
    if ($pool.agentCloudId -ne 1)
    {
        $uriAgents = $UriOrganization + "_apis/distributedtask/pools/$($pool.Id)/agents?api-version=6.0"
        $AgentsResults = Invoke-RestMethod -Uri $uriAgents -Method get -Headers $AzureDevOpsAuthenicationHeader
        Foreach ($agent in $AgentsResults.value)
        {
            $Row = "" | Select PoolName, AgentName, AgentVersion
            $Row.PoolName = $pool.name
            $Row.AgentName = $agent.name
            $Row.AgentVersion = $agent.version
            $AgentDetails += $Row
        }
    }
}
$AgentDetails | Export-Csv -Path C:\temp\AgentDetails.csv -NoTypeInformation 
