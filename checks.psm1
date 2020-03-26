# CheckModule #

function pingThis($url){

    if($(Test-Connection $url -Quiet -Count 2)){
        return $true
    }
    else{
        return $false
    }

}

function testPort($url, $port){
    $net_test = Test-NetConnection -ComputerName $url -Port $port
    return $net_test.TcpTestSucceeded
}

function mapDrive($letter, $path){
    $attemptNo = 3
    $status = while($attemptNo -gt 0){
        if($(Test-Path -Path "$($letter):\")){
            return $true
        }
        else{
            net use "$($letter):" "$path" /persistent:yes
            if($attemptNo -le 0){
                return $false
            }
        }
    }
    return $status
}


function getAccType($userObject){

    $OU_Array = $($userObject.properties.distinguishedname).split(",=")
    if($OU_Array -contains "FACULTIES" -or $OU_Array -contains "XB"){
        return 2
    }
    elseif($OU_Array -contains "SERVICES" -or $OU_Array -contains "EXT" -or $OU_Array -contains "XA"){
        return 1
    }
    else{
        return $null
    }

}

function getADUser($username){

    $ADSI = [ADSI]''
    $ADSI_Searcher = New-Object System.DirectoryServices.DirectorySearcher($ADSI)
    $ADSI_Searcher.Filter = "(&(objectClass=user)(sAMAccountName=$username))"

    try{

        $ADSI_Results = $ADSI_Searcher.FindOne()

    }
    catch [Exception] {
        Write-Host $_.Exception | Format-List -force
        $ADSI_Results = $null

    }
    
    return $ADSI_Results

}

function vpnStrategy([int]$val){
    $rasphoneLoc = "$env:APPDATA\Microsoft\Network\Connections\Pbk\rasphone.pbk"
    if(Test-Path $rasphoneLoc){
        $rasphonePbk = Get-Content $rasphoneLoc
        for($i = 0; $i -lt $rasphonePbk.Length; $i++){
            if($rasphonePbk[$i] -like "VpnStrategy=*" -and $rasphonePbk[$i] -ne "VpnStrategy=$val"){
                $rasphonePbk[$i] = "VpnStrategy=$val"
            }
        }
        Set-Content $rasphoneLoc -Value $rasphonePbk -Force
    }
}

function vpnInactive($name){
    return [bool]$(Get-VpnConnection | Where-Object {$_.Name -eq "$name" -and ($_.ConnectionStatus -eq "Disconnected" -or $_.ConnectionStatus -eq "Connecting")})
}

function vpnDisconnected($name){
    return [bool]$(Get-VpnConnection | Where-Object {$_.Name -eq "$name" -and $_.ConnectionStatus -eq "Disconnected"})
}

function vpnConnecting($name){
    return [bool]$(Get-VpnConnection | Where-Object {$_.Name -eq "$name" -and $_.ConnectionStatus -eq "Connecting"})
}

function vpnConnected($name){
    return [bool]$(Get-VpnConnection | Where-Object {$_.Name -eq "$name" -and $_.ConnectionStatus -eq "Connected"})
}

function vpnBypass($domainName){
    return [bool]$(Get-NetConnectionProfile | where-object {$_.name -eq $domainName -and $_.InterfaceAlias -like "*Ethernet*"})
}