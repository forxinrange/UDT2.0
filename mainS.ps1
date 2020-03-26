######################################
#                                    #
#    UCLan Drive Tool 2.0 | S Mode   #
#                                    #
#    2.0.0.2 - Michael Bradley       #
#                                    #
######################################

# Description: Silent version of UCLan Drive Tool 2.0

# Main Process Check #

# Exit if the main process is running
$mainDetector = Get-WmiObject Win32_Process -Filter "Name='powershell.exe' AND CommandLine LIKE '%UDT2\\main.ps1%'"
if([bool]$($mainDetector)){
	exit 0
}

$RootFolder = $PSScriptRoot

# Import Check Module #
Import-Module "$RootFolder\checks.psm1" -Force

# Hashtable Check Variables
$script:checkVars = [hashtable]::Synchronized(@{})
$script:checkVars.Add("ExtUrl", "1.1.1.1")
$script:checkVars.Add("userTunnel", "UCLan Network")
$script:checkVars.Add("domainName", "ntds.uclan.ac.uk")

# Drive maps share paths
$script:sharePaths = [hashtable]::Synchronized(@{})
$script:sharePaths.Add("N", "default")
$script:sharePaths.Add("S", "\\LSA-001\Share")
$script:sharePaths.Add("T", "\\LSA-002\Share")
$script:sharePaths.Add("U", "\\LSA-003\Share")
$script:sharePaths.Add("W", "\\LSA-201\Share")
$script:sharePaths.Add("Q", "\\ntds.uclan.ac.uk\Apps")

# MapType Flag
$script:MapType = 0

# AD Object #
$script:userObj = $null

function phaseOne(){
    # PHASE 1 - Check Internet
    # External check URL

    # Update Status
    if($(pingThis $script:checkVars.ExtUrl) -or $(testPort $script:checkVars.ExtUrl 80)){
        $null
    }
    else{
        # Both internet checks failed, terminate runspace
        return $false
    }

    # Checks passed! #
    return $true
}

function phaseTwo(){
    # PHASE 2 - Check UCLan Services

    ## VPN Checks ##

    # Check/Set SSTP VPN Strategy #
    vpnStrategy 5

    if($(vpnConnected $script:checkVars.userTunnel)){
        # Continue | reserved for logging
        $null
    }
    elseif($(vpnBypass $script:checkVars.domainName)){
        # Continue | reserved for logging
        $null
    }
    elseif($(vpnInactive $script:checkVars.userTunnel)){
        $nowTime = Get-Date
        $failed = while($(vpnConnected $script:checkVars.userTunnel) -eq $false){
            if($(vpnDisconnected $script:checkVars.userTunnel)){
                rasdial.exe "$($script:checkVars.userTunnel)"
            }

            if($(Get-Date) -gt $nowTime.AddMinutes(1)){                    
                return $false
            }

            Start-Sleep 1
        }

        if($failed -eq $false){
            return $false
        }
    }
    else{
        return $false
    }

    ## VPN Checks End ##

    ## Internal Network Checks ##
    if(-not(pingThis $script:checkVars.domainName)){
        return $false
    }

    $script:userObj = getADUser $env:USERNAME

    if($null -eq $script:userObj){
        return $false
    }
    else{
        $script:MapType = getAccType $userObj
    }

    if($null -eq $script:MapType){
        return $false
    }


    # Checks passed! #
    return $true
}

function phaseThree(){

    # Network Drives! #

    $script:sharePaths.N = $script:userObj.properties.homedirectory
            
    if($script:MapType -eq 2){
        $memStore = $script:sharePaths.T
        $script:sharePaths.T = $script:sharePaths.S
        $script:sharePaths.S = $memStore
    }

    if($null -eq $script:MapType){
        if($(mapDrive "N" "$($script:sharePaths.N)") -eq $false){
            return $false
        }
    }
    else{
        foreach($key in $script:sharePaths.Keys){
            if($(mapDrive $key $script:sharePaths["$key"]) -eq $false){
            return $false
            }
        }
    }

    # Checks complete! #
    return $true
}

function main(){
    # Disable Check Button / Prevents multiple function calls #
    if($(phaseOne) -eq $true){
        if($(phaseTwo) -eq $true){
            if($(phaseThree) -eq $true){
                #setStatus "$($script:StatusText.S1)"
            }
            else{
                exit 0
            }
        }
        else{
            exit 0
        }
    }
    else{
        exit 0
    }
}

# Runspace Entry 
main
