############################################################
# 
#
# Usage:
#   check_dhcp_scopes.ps1 -Warning <VALUE> -Critical <VALUE>
#
# Author:  Huixiao Fu (fuhuixiao@gmail.com)
# 
############################################################

Param (
	[ValidateRange(0,100)][Int]
	$Warning = 80,
	
	[ValidateRange(0,100)][Int]
	$Critical = 95
)

$Message = "DHCPServer`tScopeName`tIPRange`tSubnetMask`tIPUsed (%)`tRemainingIP`tState`n"
$IsWarning  = 0
$IsCritical = 0
$DHCPServers = Get-DhcpServerInDC

foreach ( $DHCPServer in $DHCPServers.DnsName)
{
    if (Test-Connection -ComputerName $DHCPServer -Quiet -Count 1 -Delay 1) {
        $ActiveScopes = Get-DhcpServerv4Scope -ComputerName $DHCPServer
        Write-Output $DHCPServer
        Write-Output $ActiveScopes
    
            if ($ActiveScopes) {
	            $ActiveScopes | Foreach {
		            $Scope = $_
                    Write-Output $Scope
                    $Stats = ""
		            $Stats = Get-DhcpServerv4ScopeStatistics  -ComputerName $DHCPServer $Scope.ScopeId
		            Write-Output $Stats
                    if ($Stats){
		                $Used = [Int] $Stats.PercentageInUse
		                $Free = [Int] $Stats.Free

		                switch ($Used) {
			                {$_ -ge $Critical} { $IsCritical = $IsCritical + 1
				             $Message += "$DHCPServer`t$($Scope.Name)`t$($Scope.ScopeID)`t$($Scope.SubnetMask)`t$Used`t$Free IP's available)`t$($Scope.State)`nCritical`n"
			                }
			                {$_ -ge $Warning} { $IsWarning = $IsWarning + 1
		            		$Message += "$DHCPServer`t$($Scope.Name)`t$($Scope.ScopeID)`t$($Scope.SubnetMask)`t$Used`t$Free IP's available`t$($Scope.State)`nWarning`n"
		                	}
    
		                }
                    }else{
                    Write-Output "$($Scope.Name)($($Scope.ScopeID)) info is not available on $DHCPServer`t`t`t`t`t`t`n"
                    $Message += "$($Scope.Name)($($Scope.ScopeID)) info is not available on $DHCPServer`t`t`t`t`t`t`n"
                    }
	            }
             }
      }else {
      Write-Output "$DHCPServer is not available`t`t`t`t`t`t`n"
      $Message += "$DHCPServer is not available`t`t`t`t`t`t`n"
        }
}

if ($Message) {
	Write-Output $Message | Out-File C:\DHCP.csv
}


if ($Critical -ge 1) {
Send-MailMessage -From <YOUREMAILADDRESS> -To <YOUREMAILADDRESS> -Subject "DHCP Scope on $env:computername" -Body "Please see attached CSV file with the current DHCP scope information on $env:computername" -Attachments "C:\DHCP.csv" -SmtpServer <YOURSMTPSERVER>
}
