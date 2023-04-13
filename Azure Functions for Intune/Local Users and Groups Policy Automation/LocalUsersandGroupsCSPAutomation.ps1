# Authenticate to Graph
Connect-AzAccount -Identity
$Token = Get-AzAccessToken -ResourceUrl "https://graph.microsoft.com"
$BaseUrl = "https://graph.microsoft.com/beta"
$Headers = @{
    "Authorization" = "Bearer $($Token.Token)"
}
# Group Defintions
$Json = @"
[
    {
        "PolicyId": "",
        "Groups": [
            {
                "Desc": "Administrators",
                "AADGroupIds": [
                    ""
                ],
                "Replace": "False",
                "Enumerate": "False"
            },
            {
                "Desc": "Network Configuration Operators",
                "AADGroupIds": [
                    ""
                ],
                "Replace": "True",
                "Enumerate": "True"
            }
        ]
    }
]
"@

$Policies = $Json | ConvertFrom-Json
foreach ($Policy in $Policies) {

    #Create XML
    $XML = @"
    <GroupConfiguration>
    </GroupConfiguration>
"@
    $DocumentRoot = [xml]$XML
    $GroupConfiguration = $DocumentRoot.ChildNodes
    $PolicyId = $Policy.PolicyId
    foreach ($Group in $Policy.Groups) {
        $MemberArray = New-Object -TypeName System.Collections.ArrayList
        $Desc = $Group.Desc
        if ($Group.Replace -eq $True) {
            $Action = "R"
        }
        else {
            $Action = "U"
        } 
        $Enumerate = $Group.Enumerate
        foreach ($GroupId in [Array]($Group.AADGroupIds)) {
            # add group members or add group sid. Enumerate is only needed for groups outside of "well known groups" or RDP machines
            if ($Enumerate -eq $True) {
                $GroupMembers = (Invoke-RestMethod -Method GET -Uri "$BaseUrl/groups/$GroupId/members" -Headers $Headers).Value.Id
                foreach ($Member in $GroupMembers) {
                    Write-Host "$Member"
                    $Bytes = [Guid]::Parse($Member).ToByteArray()
                    $Array = New-Object 'UInt32[]' 4
                    [Buffer]::BlockCopy($Bytes, 0, $Array, 0, 16)
                    $SID = "S-1-12-1-$Array".Replace(' ', '-')
                    $MemberArray.add($SID)
                }
            }
            else {
                $Bytes = [Guid]::Parse($GroupId).ToByteArray()
                $Array = New-Object 'UInt32[]' 4
                [Buffer]::BlockCopy($Bytes, 0, $Array, 0, 16)
                $SID = "S-1-12-1-$Array".Replace(' ', '-')
                $MemberArray.add($SID)
            }
        }
        $AccessGroup = $DocumentRoot.CreateElement('accessgroup')
        $AccessGroup.SetAttribute('desc', $Desc)
        $GroupConfiguration.OuterXml
        $GroupConfiguration.AppendChild($AccessGroup)
        $GroupAction = $DocumentRoot.CreateElement('group')
        $GroupAction.SetAttribute('action', $Action)
        $AccessGroup.AppendChild($GroupAction)
        foreach ($Member in $MemberArray) {
            $add = $DocumentRoot.CreateElement('add')
            $add.SetAttribute('member', $Member)
            $AccessGroup.AppendChild($add)
        }
       
    }
    $ExistingOmaSettings = (Invoke-RestMethod -Uri "$BaseUrl/deviceManagement/deviceConfigurations/$PolicyId" -Headers $Headers).omaSettings | Where-Object { $_.displayName -ne "LocalUsersAndGroups" }
    $Body = [ordered]@{
        "@odata.type" = "#microsoft.graph.windows10CustomConfiguration"
        "omaSettings" = @( [ordered]@{
                "@odata.type"            = "#microsoft.graph.omaSettingString"
                "displayName"            = "LocalUsersAndGroups"
                "description"            = "DO NOT EDIT"
                "omaUri"                 = "./Device/Vendor/MSFT/Policy/Config/LocalUsersAndGroups/Configure"
                "secretReferenceValueId" = ""
                "value"                  = $GroupConfiguration.OuterXml
            })
    }
    $Body.omaSettings = $Body.omaSettings + $ExistingOmaSettings
    $Body | ConvertTo-Json
    Invoke-RestMethod -Method Patch -Uri "$BaseUrl/deviceManagement/deviceConfigurations/$PolicyId" -Body ($Body | ConvertTo-Json) -Headers $Headers -ContentType "application/json"
}



