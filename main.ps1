######################################
#                                    #
#    UCLan Drive Tool 2.0            #
#                                    #
#    2.0.0.2 - Michael Bradley       #
#                                    #
######################################

# Description: This is a re-write of UCLan Drive Tool 1 created by Gareth Edwards.
#              Its main purpose is to check network services and drives are functioning as intended
#              for UCLan Enterprise mobility devices.
#
#              All operations within this codebase operate in the user context.

# Silent Process Checker #

# Kill the silent process if it is running
$silentDetector = Get-WmiObject Win32_Process -Filter "Name='powershell.exe' AND CommandLine LIKE '%UDT2\\mainS.ps1%'"
if([bool]$($silentDetector)){
	$silentDetector.Terminate()
}

# Load WPF Frameworks
Add-Type -AssemblyName PresentationFramework, PresentationCore

# Load Console Definitions
Add-Type -Name Window -Namespace Console -MemberDefinition '
[DllImport("Kernel32.dll")]
public static extern IntPtr GetConsoleWindow();

[DllImport("user32.dll")]
public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);
'

# Hide the console
$consolePtr = [Console.Window]::GetConsoleWindow()
[Console.Window]::ShowWindow($consolePtr, 0)

# Store working directory
$script:RootFolder = $PSScriptRoot

# Load Loading Animation dll
[System.Reflection.Assembly]::LoadFrom("$PSScriptRoot\LoadingIndicators.WPF.dll") | out-null

# Master synced hashtable for UI
$script:hRoot = [hashtable]::Synchronized(@{})

# Hashtable Check Variables
$script:checkVars = [hashtable]::Synchronized(@{})
$script:checkVars.Add("ExtUrl", "1.1.1.1")
$script:checkVars.Add("userTunnel", "UCLan Network")
$script:checkVars.Add("domainName", "ntds.uclan.ac.uk")

# Hashtable Text Responses
$script:statusText = [hashtable]::Synchronized(@{})
$script:statusText.Add("S1", "All services connected and ready for use.")
$script:StatusText.Add("VE1", "VPN Error: could not establish user tunnel connection.")
$script:StatusText.Add("VE2", "VPN Error: could not connect to VPN.")
$script:StatusText.Add("VE3", "UCLan Ethernet connection, bypassing VPN check.")

# Drive maps share paths
$script:sharePaths = [hashtable]::Synchronized(@{})
$script:sharePaths.Add("N", "default")
$script:sharePaths.Add("S", "\\LSA-001\Share")
$script:sharePaths.Add("T", "\\LSA-002\Share")
$script:sharePaths.Add("U", "\\LSA-003\Share")
$script:sharePaths.Add("W", "\\LSA-201\Share")
$script:sharePaths.Add("Q", "\\ntds.uclan.ac.uk\Apps")


# Hashtable for external elements
$script:extResources = [hashtable]::Synchronized(@{})
$script:extResources.Add("ErrorImg", "$RootFolder\error.png")

# Create a runspace and initialise it with the core hashtables
function createRunspace(){

    $rSpace = [runspacefactory]::CreateRunspace()
    $powerShell = [powershell]::Create()
    $powerShell.runspace = $rSpace
    $rSpace.Open()
    $rSpace.SessionStateProxy.SetVariable("hRoot", $script:hRoot)
    $rSpace.SessionStateProxy.SetVariable("statusText", $script:statusText)
    $rSpace.SessionStateProxy.SetVariable("checkVars", $script:checkVars)
    $rSpace.SessionStateProxy.SetVariable("extResources", $script:extResources)
    $rSpace.SessionStateProxy.SetVariable("sharePaths", $script:sharePaths)

    # Load the working directory
    $rSpace.SessionStateProxy.SetVariable("RootFolder", $script:RootFolder)
    return $powerShell
}

function getOS(){
    $build = $((Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name ReleaseId).ReleaseId)
    $OS = $(get-wmiobject -class win32_operatingsystem | select-object -ExpandProperty caption) -replace "Microsoft ", ""
    return "$OS $build"
}

function setMachineInfo(){
    
    $csProduct = Get-Wmiobject -class win32_computersystemproduct
    $script:hRoot.UsrVal.Content = $(Get-WmiObject -class win32_computersystem).UserName.Split('\')[1]
    $script:hRoot.CompVal.Content = $csProduct.PSComputerName
    $script:hRoot.OSVal.Content = $(getOS)
    $script:hRoot.UUIDVal.Content = $csProduct | select -ExpandProperty UUID -First 1
    $script:hRoot.MACVal.Content = $(Get-WmiObject -Class win32_networkadapterconfiguration | where-object {$null -ne $_.ipaddress} | select -expandproperty macaddress -First 1)
    if($($script:hRoot.MACVal.Content).length -eq 0){
        $script:hRoot.MACVal.Content = "No active interface."
    }
}

function setDefault(){

    # Set Icon
    $script:hRoot.Window.Icon = "$PSSCriptRoot\icon.ico"

    # Set Window Location
    $script:hRoot.Window.WindowStartupLocation = "CenterScreen"

    # Set Image Sources
    $script:hRoot.Section1Img.Source = "$PSScriptRoot\tick.png"
    $script:hRoot.Section2Img.Source = "$PSScriptRoot\tick.png"
    $script:hRoot.Section3Img.Source = "$PSScriptRoot\tick.png"
    $script:hRoot.ULogo.Source = "$PSScriptRoot\logo.png"

    # Set Image Default Visibility
    $script:hRoot.Section1Img.Visibility = "Hidden"
    $script:hRoot.Section2Img.Visibility = "Hidden"
    $script:hRoot.Section3Img.Visibility = "Hidden"

    # Progress Default Positions
    $script:hRoot.ArcsStyle1.Margin = "-373,-106,0,0"
    $script:hRoot.ArcsStyle2.Margin = "452,-106,0,0"
    $script:hRoot.ArcsStyle3.Margin = "10,-106,0,0"

    # Progress Default Visibility
    $script:hRoot.ArcsStyle1.Visibility = "Hidden"
    $script:hRoot.ArcsStyle2.Visibility = "Hidden"
    $script:hRoot.ArcsStyle3.Visibility = "Hidden"
}

function runChecks($flag){
    $powerShell = createRunspace

    [void]$powerShell.AddScript({

        # Import Check Module #
        Import-Module "$RootFolder\checks.psm1" -Force

        # Silent Check #

        # MapType Flag
        $script:MapType = 0

        # AD Objecg #
        $script:userObj = $null

        function setStatus($text){
            $script:hRoot.RLabel.Dispatcher.Invoke([action]{
                $script:hRoot.RLabel.Content = $text
            })
        }

        function changeIMG($img, $path){
            $script:hRoot["$img"].Dispatcher.Invoke([action]{
                $script:hRoot["$img"].Source = $path
            })
        }

        function toggleVisible($element){
            if($script:hRoot["$element"].Visibility -eq "Visible"){
                $script:hRoot["$element"].Dispatcher.Invoke([action]{
                    $script:hRoot["$element"].Visibility = "Hidden"
                })
            }
            else{
                $script:hRoot["$element"].Dispatcher.Invoke([action]{
                    $script:hRoot["$element"].Visibility = "Visible"
                })
            }
        }

        function criticalFailure($phase){
            for($i = $phase;$i -lt 4;$i++){
                if($i -le $phase){
                    $arcName = -join("ArcsStyle","$i")
                    toggleVisible $arcName
                }
                $imgName = -join("Section","$i","Img")
                changeIMG $imgName $script:extResources.ErrorImg
                toggleVisible $imgName
            }
        }

        function phaseOne(){
            # PHASE 1 - Check Internet

            # Activate Loading Icon
            toggleVisible "ArcsStyle1"

            # External check URL

            # Update Status
            setStatus "Checking Internet..."
            if($(pingThis $script:checkVars.ExtUrl) -or $(testPort $script:checkVars.ExtUrl 80)){
                $null
            }
            else{
                # Both internet checks failed, terminate runspace
                setStatus "You have no internet connection.  Please check your Wireless or docked connection."
                return $false
            }

            # Checks passed! #
            toggleVisible "ArcsStyle1"
            toggleVisible "Section1Img"
            return $true
        }

        function phaseTwo(){
            # PHASE 2 - Check UCLan Services

            # Activate Loading Icon
            toggleVisible "ArcsStyle2"
            setStatus "Checking UCLan Services..."


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
                setStatus $script:StatusText.VE2
                return $false
            }

            ## VPN Checks End ##

            ## Internal Network Checks ##
            if(-not(pingThis $script:checkVars.domainName)){
                return $false
            }

            $script:userObj = getADUser $env:USERNAME

            if($null -eq $script:userObj){
                setStatus "Failed to see AD"
                return $false
            }
            else{
                $script:MapType = getAccType $userObj
            }

            if($null -eq $script:MapType){
                setStatus "No type defined"
                return $false
            }


            # Checks passed! #
            toggleVisible "ArcsStyle2"
            toggleVisible "Section2Img"
            return $true
        }

        function phaseThree(){

            # Network Drives! #
            toggleVisible "ArcsStyle3"
            setStatus "Checking network drives..."

            $script:sharePaths.N = $script:userObj.properties.homedirectory
            
            if($script:MapType -eq 2){
                $memStore = $script:sharePaths.T
                $script:sharePaths.T = $script:sharePaths.S
                $script:sharePaths.S = $memStore
            }

            if($null -eq $script:MapType){
                if($(mapDrive "N" "$($script:sharePaths.N)") -eq $false){
                    setStatus "Could not map $key drive."
                    return $false
                }
            }
            else{
                foreach($key in $script:sharePaths.Keys){
                    if($(mapDrive $key $script:sharePaths["$key"]) -eq $false){
                    setStatus "Could not map $key drive."
                    return $false
                    }
                }
            }

            # Checks complete! #
            toggleVisible "ArcsStyle3"
            toggleVisible "Section3Img"
            return $true
        }

        function main(){
            # Disable Check Button / Prevents multiple function calls #
            toggleVisible "CheckBtn"
            if($(phaseOne) -eq $true){
                if($(phaseTwo) -eq $true){
                    if($(phaseThree) -eq $true){
                        setStatus "$($script:StatusText.S1)"
                        toggleVisible "CheckBtn"
                    }
                    else{
                        toggleVisible "CheckBtn"
                        criticalFailure 3
                        exit 0
                    }
                }
                else{
                    toggleVisible "CheckBtn"
                    criticalFailure 2
                    exit 0
                }
            }
            else{
                toggleVisible "CheckBtn"
                criticalFailure 1
                exit 0
            }
        }

        # Runspace Entry 
        main

    })
    $job = $powerShell.BeginInvoke()
}

function main($argValue){

    # Load GUI
    [xml]$XAML = Get-Content "$PSScriptroot\gui.xml"
    $xamlReader = $(New-Object System.Xml.XmlNodeReader $XAML)
    try{
        $script:hRoot.Add("Window",$([Windows.Markup.XamlReader]::Load($xamlReader)))
        $XAML.SelectNodes("//*[@Name]") | % {$script:hRoot.Add($_.Name, $script:hRoot.Window.FindName($_.Name))}
    }
    catch{
        write-host "Failed to parse/build hashtable error below:"
        $_.Exception
        exit 1
    }

    # Set Element Defaults
    setDefault

    # Set Machine Info
    setMachineInfo

    # Switch case
    if($argValue -ne "silent"){

        $script:hRoot.Window.add_ContentRendered({
            
            runChecks
        })

        $script:hRoot.CheckBtn.add_Click({
            setDefault
            runChecks
        })

        $script:hRoot.ExitBtn.add_Click({
            $script:hRoot.Window.Close()
        })

        $script:hRoot.HelpBtn.add_Click({
            [System.Diagnostics.Process]::Start("https://uclan.topdesk.net/tas/public/ssp")
        })

        # Initiate graphics engine
        $script:hRoot.Window.ShowDialog()

    }
    else{

        exit 0

    }

    exit 0
}

# Entry Point #
main $args[0]