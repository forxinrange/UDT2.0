## UCLan Drive Tool 3 - GUI Module ##
Add-Type -Name Window -Namespace Console -MemberDefinition '
[DllImport("Kernel32.dll")]
public static extern IntPtr GetConsoleWindow();

[DllImport("user32.dll")]
public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);
'
function GUI_generate_window($setting){

    # Main Window #
    $m_window = New-Object System.Windows.Forms.Form
    $m_window.Text = $setting.Title
    $m_window.BackColor = "White"
    $m_window.Size = New-Object System.Drawing.Size([int]$setting.xS,[int]$setting.yS)
    $m_window.MaximizeBox = $setting.maximise
    $m_window.StartPosition = 'CenterScreen'
    $m_window.FormBorderStyle = 'Fixed3D'
    $m_window.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($setting.iconPath)
    $m_window.ControlBox = $setting.visible_controls

    # Return the built Form #
    return $m_window

}

function GUI_Hide_Console(){

    $consolePtr = [Console.Window]::GetConsoleWindow()
    [Console.Window]::ShowWindow($consolePtr, 0)

}

# Constructs a label object
function GUI_generate_label($text,$posX,$posY,$font){

    $label = New-Object System.Windows.Forms.Label
    $label.Location = New-object System.Drawing.Point([int]$posX,[int]$posY)
    $label.AutoSize = $true
    $label.Text = $text
    $label.Font = $font

    return $label

}

# Constructs an input object
function GUI_generate_input_box($posX,$posY,$sizX,$sizY){

    $box = New-Object System.Windows.Forms.TextBox
    $box.location = New-Object System.Drawing.Point([int]$posX,[int]$posY)
    $box.Size = New-Object System.Drawing.Size([int]$sizX,[int]$sizY)

    return $box

}

# Constructs a button object
function GUI_generate_button($posX,$posY,$sizX,$sizY,$text,$font){

    $btn = new-object System.Windows.Forms.Button
    $btn.Location = New-Object System.Drawing.Point([int]$posX,[int]$posY)
    $btn.Width = [int]$sizX
    $btn.Height = [int]$sizY
    $btn.Text = $text
    $btn.Font = $font

    return $btn

}

function GUI_generate_logo($posX,$posY,$filepath){

    $logo = [System.Drawing.Image]::FromFile($filepath)
    $logoBox = New-Object System.Windows.Forms.PictureBox
    $logoBox.Width = $logo.Size.Width
    $logoBox.Height = $logo.Size.Height
    $logoBox.Image = $logo
    $logoBox.Location = New-Object System.Drawing.Point([int]$posX,[int]$posY)

    return $logoBox

}

function GUI_generate_datatable($posX,$posY,$sizX,$sizY){

    $datatable = New-Object System.Windows.Forms.DataGridView
    $size_obj = New-Object System.Drawing.Size
    $size_obj.Width = [int]$sizX
    $size_obj.Height = [int]$sizY
    $datatable.Size = $size_obj
    $datatable.Location = New-Object System.Drawing.Point([int]$posX,[int]$posY)

    return $datatable
}

function GUI_Change_Row_Colour($GUI_ROOT, $rowNo, $colour){

    $GUI_ROOT["DataTable"].Rows[$rowNo].Cells | % {$_.Style.ForeColor="$colour"}
    

}

function GUI_update_form($form){

    $form.Refresh()

}

function GUI_change_element_text($element, $text){

    $element.Text = $text

}

function GUI_update_grid($grid,$check,$status,$help){

    $row = @("$check","$status","$help")
    $grid.Rows.Add($row)

    $grid.Rows | % {$_.HeaderCell.Value=($_.Index+1).ToString()}

}


function GUI_clear_grid($grid){

    $grid["DataTable"].Rows.Clear()

}

function GUI_Construct(){

    # Load Assembly #
    [reflection.assembly]::LoadWithPartialName( "System.Windows.Forms") | Out-Null
    [reflection.assembly]::LoadWithPartialName( "System.Drawing") | Out-Null


    # Elements Hash #
    $root_form = @{}

    # Settings Hash #
    $window_config = @{

        Title = "UCLan - Drive Tool 2.0";
        xS = 1280;
        yS = 600;
        maximise = $false;
        visible_controls = $true;
        iconPath = "$PSScriptRoot\resources\icon.ico" 
        logo_path = "$PSScriptRoot\resources\logo.png"
        sec_text = "$PSScriptRoot\resources\btex.png"

    }

    # Load the Main form Into HashTable #
    $root_form.Add("MainForm", $(GUI_generate_window $window_config))

    # Brush Objects #
    $root_form.Add("BrushObject", $(New-Object Drawing.SolidBrush LightGray))

    # Grey Rect #
    $root_form.Add("RectObject", $(New-Object Drawing.Rectangle 0, 170, 1280, 430))

    # Graphics Engine #
    $root_form.Add("GraphicsEngine", $($root_form["MainForm"].createGraphics()))

    # Font Constructs #
    $root_form.Add("HeaderFont", $(New-Object System.Drawing.Font("Helvetica",16,[System.Drawing.FontStyle]::Bold)))
    $root_form.Add("TableHeaderFont", $(New-Object System.Drawing.Font("Helvetica",10,[System.Drawing.FontStyle]::Bold)))
    $root_form.Add("BodyFont", $(New-Object System.Drawing.Font("Helvetica",10)))

    # Recheck Button
    $root_form.Add("RecheckBtn", $(GUI_generate_button 945 120 150 45 "Re-Check" $($root_form["HeaderFont"])))
    $root_form["RecheckBtn"].BackColor = "LightGray"
    $root_form["RecheckBtn"].ForeColor = "Black"

    # Exit Button
    $root_form.Add("ExitBtn", $(GUI_generate_button 1100 120 150 45 "Exit" $($root_form["HeaderFont"])))
    $root_form["ExitBtn"].BackColor = "LightGray"
    $root_form["ExitBtn"].ForeColor = "Black"
    $root_form["ExitBtn"].DialogResult = [System.Windows.Forms.DialogResult]::Cancel

    # Data Table
    $root_form.Add("DataTable", $(GUI_generate_datatable 10 180 1240 365))
    $root_form["DataTable"].BackgroundColor = "White"
    $root_form["DataTable"].ColumnCount = 3
    $root_form["DataTable"].ColumnHeadersVisible = $true
    $root_form["DataTable"].Columns[0].Name = "Task"
    $root_form["DataTable"].Columns[1].Name = "Result"
    $root_form["DataTable"].Columns[2].Name = "Help"
    $root_form["DataTable"].DefaultCellStyle.Font = $root_form["BodyFont"]
    $root_form["DataTable"].ColumnHeadersDefaultCellStyle.Font = $root_form["TableHeaderFont"]
    $root_form["DataTable"].AllowUserToAddRows = $false
    $root_form["DataTable"].AllowUserToDeleteRows = $false
    $root_form["DataTable"].AllowUserToOrderColumns = $false
    $root_form["DataTable"].ReadOnly = $true
    $root_form["DataTable"].Columns | % { $_.AutoSizeMode = [System.Windows.Forms.DataGridViewAutoSizeColumnMode]::Fill }
    $root_form["DataTable"].RowHeadersWidth = [int]50
    $root_form["DataTable"].Columns[0].Width = [int]200


    # Logo Object #
    $root_form.Add("LogoPic", $(GUI_generate_logo 20 20 "$($window_config.logo_path)"))

    # Status Title #
    $root_form.Add("StatusTitle", $(GUI_generate_label "Status:" 260 144 $($root_form["TableHeaderFont"])))

    # Status Label #
    $root_form.Add("StatusLabel", $(GUI_generate_label "Ready" 310 144 $($root_form["TableHeaderFont"])))

    # Username Label #
    $root_form.Add("UsernameLabel", $(GUI_generate_label "Username:" 500 20 $($root_form["TableHeaderFont"])))

    # Username Value #
    $root_form.Add("UsernameValue", $(GUI_generate_label "$(whoami)" 605 20 $($root_form["BodyFont"])))

    # Computer Name Label #
    $root_form.Add("ComputerNameLabel", $(GUI_generate_label "Computer Name:" 461 50 $($root_form["TableHeaderFont"])))

    # Computer Name Value #
    $root_form.Add("ComputerNameValue", $(GUI_generate_label "$($env:computername)" 605 50 $($root_form["BodyFont"])))

    # Windows Build Label #
    $root_form.Add("WindowsLabel", $(GUI_generate_label "Operating System:" 450 80 $($root_form["TableHeaderFont"])))

    # Windows Build Version #
    $build = $((Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name ReleaseId).ReleaseId)
    $OS = $(get-wmiobject -class win32_operatingsystem | select-object -ExpandProperty caption) -replace "Microsoft ", ""
    $root_form.Add("WindowsVersion", $(GUI_generate_label "$OS $build" 605 80 $($root_form["BodyFont"])))

    # UUID Label #
    $root_form.Add("UUIDLabel", $(GUI_generate_label "UUID:" 530 110 $($root_form["TableHeaderFont"])))

    # Mac Label #
    $root_form.Add("MacLabel", $(GUI_generate_label "Mac Address:" 480 140 $($root_form["TableHeaderFont"])))

    # Mac Value #
    $ActiveMac = Get-NetAdapter | where-object {$_.Status -eq "Up"} | select-object -ExpandProperty "MacAddress" -First 1
    $root_form.Add("MacValue", $(GUI_generate_label "$ActiveMac" 605 140 $($root_form["BodyFont"]))) 

    # UUID Version #
    $UUID = $(get-wmiobject Win32_ComputerSystemProduct  | Select-Object -ExpandProperty UUID)
    $root_form.Add("UUIDVersion", $(GUI_generate_label "$UUID" 605 110 $($root_form["BodyFont"])))


    # Don't try and append fonts, brushes, engines and rectangles... that would be silly
    foreach($key in $root_form.Keys){
        if($key -ne "MainForm" -and $key -ne "HeaderFont" -and $key -ne "BodyFont" -and $key -ne "BrushObject" -and $key -ne "GraphicsEngine" -and $key -ne "RectObject" -and $key -ne "TableHeaderFont"){
            $root_form["MainForm"].Controls.Add($root_form[$key])
        }
    }


    # Returns a monster to the poor thing that called this  #
    return $root_form

}

function GUI_Test_theme(){

    Write-Host "This is a test of the powermode simulatation"

}