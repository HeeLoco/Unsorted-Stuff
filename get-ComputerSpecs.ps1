#15.02.2018
#Version 0.1.8
#HeeLoco
#last edit: 20.02.2018

#Vorraussetzungen schaffen:
#z.b. Framework 4.5 um eine höhere Powershellversion aufspielen zu können
#     internetverbindung falls weitere Module nachträglich geladen werden müssen
#     oder einen Weg finden dass diese auch ohne Internet geladen werden können
#     alte Versionen von PS zu supporten brauchen viele Tests und gegebenenfalls Pflege

#RAID im Gerätemanager anfragen?

#zu testen:
# ein & mehrere Netzwerkadapter
# eine & mehrere Festplatten
# 

#Powershell scritp to collect data from the current PC
#The information are collected by WMI 
#all data will be put in xml files
#It is also possible to add functions such as network data collection.

<#
Windows Management Instrumentation
From Wikipedia, the free encyclopedia

Windows Management Instrumentation (WMI) consists of a set of extensions to the Windows Driver Model
that provides an operating system interface through which instrumented components provide information
and notification. WMI is Microsoft's implementation of the Web-Based Enterprise Management (WBEM) 
and Common Information Model (CIM) standards from the Distributed Management Task Force (DMTF).

WMI allows scripting languages (such as VBScript or Windows PowerShell) 
to manage Microsoft Windows personal computers and servers, both locally and remotely. 
WMI comes preinstalled in Windows 2000 and in newer Microsoft OSes. It is available as a 
download for Windows NT, Windows 95 and Windows 98.

Microsoft also provides a command-line interface to WMI called Windows Management
Instrumentation Command-line (WMIC).
#>

#Variables
$xmlfile = "++information.xml"
$txtfile = "++information.txt"
$xmlpath = "$env:windir"

$mydebug = 1

#Functions ######################################################################
function get-OSinfo {
    #Data source
    $myOSInfo = Get-WmiObject Win32_OperatingSystem

    #Prepare 
    $myRes = "" | select "OS", "Architecture", "Version", "Memory Size"

    #and fill object with the needed data
    $myRes.'Memory size' = [math]::round(($myOSInfo.TotalVisibleMemorySize /1MB),2)
    $myRes.OS = $myOSinfo.Caption
    $myRes.Architecture = $myOSinfo.OSArchitecture
    $myRes.Version = $myOSinfo.Version

    #return object
    return $myRes
}

function get-DiskInfo{
    #Data source
    $myVolume = Get-WmiObject Win32_Volume
    $myLogicalDisk = Get-WmiObject Win32_logicaldisk

    #Output Array
    $myOut = @()

     for($i = 0; $i -lt ($myVolume.Count); $i++){ 
        #prepare and fill object
        $res = "" | select "Name", "Description", "Size", "Free space", "Filesystem", "Blocksize"

        $res.Name = $myLogicalDisk[$i].DeviceID
        $res.Description = $myLogicalDisk[$i].Description
        $res.Size = [math]::round(($myVolume[$i].capacity /1GB),2)
        $res.'Free space' = [math]::round(($myVolume[$i].FreeSpace /1GB),2)
        $res.Filesystem = $myVolume[$i].Filesystem
        $res.Blocksize = $myVolume[$i].Blocksize

        #collect data in one object
        $myOut += $res
        $res = $null
    }
    return $myOut      
}

function get-myNetAdapter{
#data source
$myAdaptercfg = Get-WmiObject -class Win32_NetworkAdapterConfiguration | where-object {$_.IPEnabled -eq "True"}
$myAdapter = Get-WmiObject -Class win32_networkadapter 


#initialization of the arrays with the data type int and no content  => @null
[int[]]$myPosAdapter = @() 
[int[]]$myPosCfg = @() 


#Determine number of objects
switch(($myAdaptercfg | measure).count){

    0 {
        return 666 #dummy return code for information like "no adapters found!" ############################################################

    }

    1 {
        #One object found!
        #prepare and fill object
        $res = "" | select "Name", "Speed"   
        
        $res.Name = $myAdaptercfg.Description
        $res.Speed = [math]::round(($myadapter[$myAdaptercfg.Index].Speed /1GB),2)

        return $res # need a test for this case ##############################################################################################################
       

    }

    default {
        #More than one object
        
        #Output array 
        $myOut = @()

        #For the number and positions in the array
        $myCounter = 0

        #determine the index (DeviceID) from this objects
        for($j=0; $j -lt ($myAdaptercfg | measure).Count; $j++){
            for($i=0; $i -lt ($myAdapter | measure).Count; $i++){
            
                if($myAdaptercfg[$j].Index -eq $myAdapter[$i].deviceID){
                    
                    $myPosAdapter += $i
                    $myPosCfg += $j
                    $myCounter++;
                }
            }
        }

        #with two arrays #another method is with one array // needed values are side by side // e.g. a for with $i=$i+2
        for($i = 0; $i -lt $myCounter; $i++){

        #Temp, because "$myAdaptercfg[$myPosAdapter[$i]]" does not work
        $tempA = $myPosAdapter[$i]
        $tempB = $myPosCfg[$i]

        #prepare and fill object
        $res = "" | select "Name", "Speed"
       
        $res.Name = $myAdaptercfg[$tempB].Description
        $res.Speed = [math]::round(($myadapter[$tempA].Speed /1MB),2)

        #collect data in one object
        $myOut += $res    
        $res = $null       
        }

        return $myOut
    }
}

#Notes & todos:
#Auch eine andere Möglichkeit: "echte" Adapter überprüfen?

#welchen Wert, wenn gar keine ermittlung erfolgen kann? RETURN ERROR CODE 666
#beispiel: bei keinem Adapter mit Speed angabe 
#oder keiner eindeutigen zuordung
}

function get-CPUinfo {
    #Data source
    $myCPUinfo = Get-WmiObject -Class win32_processor

    #Output array if there more than one CPU
    $myOut = @()
  
    
    switch(($myCPUinfo | measure).Count){

        0 {}#not possible

        1 { #one object
            #prepare object
            $res = "" | select "Name", "Description", "Architecture", "Clock speed", "Cores", "UpgradeMethod" , "SocketDesignation"

            #Name, Description, Clock speed, Number of cores
            $res.Name = $myCPUinfo.Name 
            $res.Description = $myCPUinfo.Description
            $res.'Clock speed' = [math]::round(($myCPUinfo.MaxClockSpeed /1024),2)
            $res.Cores = $myCPUinfo.NumberofCores

            #socket" ### NEEDED ????################################################################################################
            $res.SocketDesignation = $myCPUinfo.SocketDesignation

            #Architecture
            switch($myCPUinfo.Architecture){
                0 {$temp = "x86"}
                1 {$temp = "MIPS"}
                2 {$temp = "Alpha"}
                3 {$temp = "PowerPC"}
                6 {$temp = "ia64"}
                9 {$temp = "x64"}
    
                default {$temp = "Architecture not in list!" }
                   }
            $res.Architecture = $temp

                #RAUSGENOMMEN!!!##########################################################################################
                #Family ### NOT USEFULL !!! FIND ANOTHER WAY ######################################
                                        # DESCRIPTION -split NEED defined levels!! ###########
                #It looks like the Win32_Processor.Family property is not to be trusted,
                #it does not return correct numbers in many cases (even for old
                #processor families known when Win2k or WinXP was released).
                switch($myCPUinfo.Family){
                    1 {$temp = "Other"}
                    2 {$temp = "Unknown"}
                    3 {$temp = "8086"}
                    4 {$temp = "80286"}
                    5 {$temp = "80386"}
                    6 {$temp = "80486"}
                    7 {$temp = "8087"}
                    8 {$temp = "80287"}
                    9 {$temp = "80387"}
                   10 {$temp = "80487"}
                   11 {$temp = "Pentium(R) brand"}
                   12 {$temp = "Pentium(R) Pro"}
                   13 {$temp = "Pentium(R) II"}
                   14 {$temp = "Pentium(R) processor with MMX(TM) technology"}
                   15 {$temp = "Celeron(TM)"}
                   16 {$temp = "Pentium(R) II Xeon(TM)"}
                   17 {$temp = "Pentium(R) III"}
                   18 {$temp = "M1 Family"}
                   19 {$temp = "M2 Family"}
                   24 {$temp = "K5 Family"}
                   25 {$temp = "K6 Family"}
                   26 {$temp = "K6-2"}
                   27 {$temp = "K6-3"}
                   28 {$temp = "AMD Athlon(TM) Processor Family"}
                   29 {$temp = "AMD(R) Duron(TM) Processor"}
                   30 {$temp = "AMD29000 Family"}
                   31 {$temp = "K6-2+"}
                   32 {$temp = "Power PC Family"}
                   33 {$temp = "Power PC 601"}
                   34 {$temp = "Power PC 603"}
                   35 {$temp = "Power PC 603+"}
                   36 {$temp = "Power PC 604"}
                   37 {$temp = "Power PC 620"}
                   38 {$temp = "Power PC X704"}
                   39 {$temp = "Power PC 750"}
                   48 {$temp = "Alpha Family"}
                   49 {$temp = "Alpha 21064"}
                   50 {$temp = "Alpha 21066"}
                   51 {$temp = "Alpha 21164"}
                   52 {$temp = "Alpha 21164PC"}
                   53 {$temp = "Alpha 21164a"}
                   54 {$temp = "Alpha 21264"}
                   55 {$temp = "Alpha 21364"}
                   64 {$temp = "MIPS Family"}
                   65 {$temp = "MIPS R4000"}
                   66 {$temp = "MIPS R4200"}
                   67 {$temp = "MIPS R4400"}
                   68 {$temp = "MIPS R4600"}
                   69 {$temp = "MIPS R10000"}
                   80 {$temp = "SPARC Family"}
                   81 {$temp = "SuperSPARC"}
                   82 {$temp = "microSPARC II"}
                   83 {$temp = "microSPARC IIep"}
                   84 {$temp = "UltraSPARC"}
                   85 {$temp = "UltraSPARC II"}
                   86 {$temp = "UltraSPARC IIi"}
                   87 {$temp = "UltraSPARC III"}
                   88 {$temp = "UltraSPARC IIIi"}
                   96 {$temp = "68040"}
                   97 {$temp = "68xxx Family"}
                   98 {$temp = "68000"}
                   99 {$temp = "68010"}
                  100 {$temp = "68020"}
                  101 {$temp = "68030"}
                  112 {$temp = "Hobbit Family"}
                  120 {$temp = "Crusoe(TM) TM5000 Family"}
                  121 {$temp = "Crusoe(TM) TM3000 Family"}
                  122 {$temp = "Efficeon(TM) TM8000 Family"}
                  128 {$temp = "Weitek"}
                  130 {$temp = "Itanium(TM) Processor"}
                  131 {$temp = "AMD Athlon(TM) 64 Processor Family"}
                  132 {$temp = "AMD Opteron(TM) Family"}
                  144 {$temp = "PA-RISC Family"}
                  145 {$temp = "PA-RISC 8500"}
                  146 {$temp = "PA-RISC 8000"}
                  147 {$temp = "PA-RISC 7300LC"}
                  148 {$temp = "PA-RISC 7200"}
                  149 {$temp = "PA-RISC 7100LC"}
                  150 {$temp = "PA-RISC 7100"}
                  160 {$temp = "V30 Family"}
                  176 {$temp = "Pentium(R) III Xeon(TM)"}
                  177 {$temp = "Pentium(R) III Processor with Intel(R) SpeedStep(TM) Technology"}
                  178 {$temp = "Pentium(R) 4"}
                  179 {$temp = "Intel(R) Xeon(TM)"}
                  180 {$temp = "AS400 Family"}
                  181 {$temp = "Intel(R) Xeon(TM) processor MP"}
                  182 {$temp = "AMD AthlonXP(TM) Family"}
                  183 {$temp = "AMD AthlonMP(TM) Family"}
                  184 {$temp = "Intel(R) Itanium(R) 2"}
                  185 {$temp = "Intel Pentium M Processor"}
                  190 {$temp = "K7"}
                  200 {$temp = "IBM390 Family"}
                  201 {$temp = "G4"}
                  202 {$temp = "G5"}
                  203 {$temp = "G6"}
                  204 {$temp = "z/Architecture base"}
                  250 {$temp = "i860"}
                  251 {$temp = "i960"}
                  260 {$temp = "SH-3"}
                  261 {$temp = "SH-4"}
                  280 {$temp = "ARM"}
                  281 {$temp = "StrongARM"}
                  300 {$temp = "6x86"}
                  301 {$temp = "MediaGX"}
                  302 {$temp = "MII"}
                  320 {$temp = "WinChip"}
                  350 {$temp = "DSP"}
                  500 {$temp = "Video Processor"}

                  default {$temp = "Family not in list!"}
                }
        
                ##########################################################################################################

                #UpgradeMethod ### NEEDED ?????############################################
                Switch($myCPUinfo.UpgradeMethod){

                    1 {$temp = "Other"}
                    2 {$temp = "Unknown"}
                    3 {$temp = "Daughter Board"}
                    4 {$temp = "ZIF Socket"}
                    5 {$temp = "Replacement/Piggy Back"}
                    6 {$temp = "None"}
                    7 {$temp = "LIF Socket"}
                    8 {$temp = "Slot 1"}
                    9 {$temp = "Slot 2"}
                   10 {$temp = "370 Pin Socket"}
                   11 {$temp = "Slot A"}
                   12 {$temp = "Slot M"}
                   13 {$temp = "Socket 423"}
                   14 {$temp = "Socket A (Socket 462"}
                   15 {$temp = "Socket 478"}
                   16 {$temp = "Socket 754"}
                   17 {$temp = "Socket 940"}
                   18 {$temp = "Socket 939"}

                   default {$temp = "Upgrademethod not in list!"}
                }
                $res.UpgradeMethod = $temp


                #collect data in one object
                $myOut += $res
                $res = $null       
        }

        default { #Determine number of object
            for($i = 0; $i -lt (($myCPUinfo | measure).Count); $i++){
    
                #prepare object
                $res = "" | select "Name", "Description", "Architecture", "Clock speed", "Cores", "UpgradeMethod" , "SocketDesignation"

                #Name, Description, Clock speed, Number of cores
                $res.Name = $myCPUinfo[$i].Name 
                $res.Description = $myCPUinfo[$i].Description
                $res.'Clock speed' = [math]::round(($myCPUinfo[$i].MaxClockSpeed /1024),2)
                $res.Cores = $myCPUinfo[$i].NumberofCores

                #socket" ### NEEDED ????##############################################
                $res.SocketDesignation = $myCPUinfo[$i].SocketDesignation

                #Architecture
                    switch($myCPUinfo[$i].Architecture){
                        0 {$temp = "x86"}
                        1 {$temp = "MIPS"}
                        2 {$temp = "Alpha"}
                        3 {$temp = "PowerPC"}
                        6 {$temp = "ia64"}
                        9 {$temp = "x64"}
    
                        default {$temp = "Architecture not in list!" }
                    }
                $res.Architecture = $temp

                #RAUSGENOMMEN!!!##########################################################################################
                #Family ### NOT USEFULL !!! FIND ANOTHER WAY ######################################
                                        # DESCRIPTION -split NEED defined levels!! ###########
                #It looks like the Win32_Processor.Family property is not to be trusted,
                #it does not return correct numbers in many cases (even for old
                #processor families known when Win2k or WinXP was released).
                switch($myCPUinfo[$i].Family){
                    1 {$temp = "Other"}
                    2 {$temp = "Unknown"}
                    3 {$temp = "8086"}
                    4 {$temp = "80286"}
                    5 {$temp = "80386"}
                    6 {$temp = "80486"}
                    7 {$temp = "8087"}
                    8 {$temp = "80287"}
                    9 {$temp = "80387"}
                   10 {$temp = "80487"}
                   11 {$temp = "Pentium(R) brand"}
                   12 {$temp = "Pentium(R) Pro"}
                   13 {$temp = "Pentium(R) II"}
                   14 {$temp = "Pentium(R) processor with MMX(TM) technology"}
                   15 {$temp = "Celeron(TM)"}
                   16 {$temp = "Pentium(R) II Xeon(TM)"}
                   17 {$temp = "Pentium(R) III"}
                   18 {$temp = "M1 Family"}
                   19 {$temp = "M2 Family"}
                   24 {$temp = "K5 Family"}
                   25 {$temp = "K6 Family"}
                   26 {$temp = "K6-2"}
                   27 {$temp = "K6-3"}
                   28 {$temp = "AMD Athlon(TM) Processor Family"}
                   29 {$temp = "AMD(R) Duron(TM) Processor"}
                   30 {$temp = "AMD29000 Family"}
                   31 {$temp = "K6-2+"}
                   32 {$temp = "Power PC Family"}
                   33 {$temp = "Power PC 601"}
                   34 {$temp = "Power PC 603"}
                   35 {$temp = "Power PC 603+"}
                   36 {$temp = "Power PC 604"}
                   37 {$temp = "Power PC 620"}
                   38 {$temp = "Power PC X704"}
                   39 {$temp = "Power PC 750"}
                   48 {$temp = "Alpha Family"}
                   49 {$temp = "Alpha 21064"}
                   50 {$temp = "Alpha 21066"}
                   51 {$temp = "Alpha 21164"}
                   52 {$temp = "Alpha 21164PC"}
                   53 {$temp = "Alpha 21164a"}
                   54 {$temp = "Alpha 21264"}
                   55 {$temp = "Alpha 21364"}
                   64 {$temp = "MIPS Family"}
                   65 {$temp = "MIPS R4000"}
                   66 {$temp = "MIPS R4200"}
                   67 {$temp = "MIPS R4400"}
                   68 {$temp = "MIPS R4600"}
                   69 {$temp = "MIPS R10000"}
                   80 {$temp = "SPARC Family"}
                   81 {$temp = "SuperSPARC"}
                   82 {$temp = "microSPARC II"}
                   83 {$temp = "microSPARC IIep"}
                   84 {$temp = "UltraSPARC"}
                   85 {$temp = "UltraSPARC II"}
                   86 {$temp = "UltraSPARC IIi"}
                   87 {$temp = "UltraSPARC III"}
                   88 {$temp = "UltraSPARC IIIi"}
                   96 {$temp = "68040"}
                   97 {$temp = "68xxx Family"}
                   98 {$temp = "68000"}
                   99 {$temp = "68010"}
                  100 {$temp = "68020"}
                  101 {$temp = "68030"}
                  112 {$temp = "Hobbit Family"}
                  120 {$temp = "Crusoe(TM) TM5000 Family"}
                  121 {$temp = "Crusoe(TM) TM3000 Family"}
                  122 {$temp = "Efficeon(TM) TM8000 Family"}
                  128 {$temp = "Weitek"}
                  130 {$temp = "Itanium(TM) Processor"}
                  131 {$temp = "AMD Athlon(TM) 64 Processor Family"}
                  132 {$temp = "AMD Opteron(TM) Family"}
                  144 {$temp = "PA-RISC Family"}
                  145 {$temp = "PA-RISC 8500"}
                  146 {$temp = "PA-RISC 8000"}
                  147 {$temp = "PA-RISC 7300LC"}
                  148 {$temp = "PA-RISC 7200"}
                  149 {$temp = "PA-RISC 7100LC"}
                  150 {$temp = "PA-RISC 7100"}
                  160 {$temp = "V30 Family"}
                  176 {$temp = "Pentium(R) III Xeon(TM)"}
                  177 {$temp = "Pentium(R) III Processor with Intel(R) SpeedStep(TM) Technology"}
                  178 {$temp = "Pentium(R) 4"}
                  179 {$temp = "Intel(R) Xeon(TM)"}
                  180 {$temp = "AS400 Family"}
                  181 {$temp = "Intel(R) Xeon(TM) processor MP"}
                  182 {$temp = "AMD AthlonXP(TM) Family"}
                  183 {$temp = "AMD AthlonMP(TM) Family"}
                  184 {$temp = "Intel(R) Itanium(R) 2"}
                  185 {$temp = "Intel Pentium M Processor"}
                  190 {$temp = "K7"}
                  200 {$temp = "IBM390 Family"}
                  201 {$temp = "G4"}
                  202 {$temp = "G5"}
                  203 {$temp = "G6"}
                  204 {$temp = "z/Architecture base"}
                  250 {$temp = "i860"}
                  251 {$temp = "i960"}
                  260 {$temp = "SH-3"}
                  261 {$temp = "SH-4"}
                  280 {$temp = "ARM"}
                  281 {$temp = "StrongARM"}
                  300 {$temp = "6x86"}
                  301 {$temp = "MediaGX"}
                  302 {$temp = "MII"}
                  320 {$temp = "WinChip"}
                  350 {$temp = "DSP"}
                  500 {$temp = "Video Processor"}

                  default {$temp = "Family not in list!"}
                }
        
                ##########################################################################################################

                #UpgradeMethod ### NEEDED ?????############################################
                Switch($myCPUinfo[$i].UpgradeMethod){

                    1 {$temp = "Other"}
                    2 {$temp = "Unknown"}
                    3 {$temp = "Daughter Board"}
                    4 {$temp = "ZIF Socket"}
                    5 {$temp = "Replacement/Piggy Back"}
                    6 {$temp = "None"}
                    7 {$temp = "LIF Socket"}
                    8 {$temp = "Slot 1"}
                    9 {$temp = "Slot 2"}
                   10 {$temp = "370 Pin Socket"}
                   11 {$temp = "Slot A"}
                   12 {$temp = "Slot M"}
                   13 {$temp = "Socket 423"}
                   14 {$temp = "Socket A (Socket 462"}
                   15 {$temp = "Socket 478"}
                   16 {$temp = "Socket 754"}
                   17 {$temp = "Socket 940"}
                   18 {$temp = "Socket 939"}

                   default {$temp = "Upgrademethod not in list!"}
                }
                $res.UpgradeMethod = $temp


                #collect data in one object
                $myOut += $res
                $res = $null
            }
        }
    }
return $myOut  
}

#Version 1: Nachträglich ergänzen
#Add-Member -InputObject $test -Name $Name -Value $myDISK[$i].Name -MemberType NoteProperty

#Version 2: vor dem erzeugen des Objects die Hashtable manipulieren
#$myHash += @{$Name = $myDISK[$i].Name}

function add-Hash-CPU{
    #Set the number of CPU
    $myHash.CPUCount = ($myCPU | measure).Count

    #loop for every additional CPU
    for($i = 1; $i -lt($myCPU | Measure).Count; $i++){

        #define array with extensions and names
        $Ext = @("Name", "Description", "Cores", 'Clock speed')
        $help = @("Name", "Description", "Cores", "Clock")

        #loop for every extension and value
        for($j = 0; $j -lt $Ext.Count ; $j++){
            #prepare name for property
            $Name = "CPU$i" + $help[$j]
                
            #manipuliate the hashtable 
            $temp = $Ext[$j]             
            $myHash += @{$Name = $myDISK[$i].$temp}
        }                       
    }
}

function add-Hash-NET{
    #set the number of Adapter
    $myHash.NETCount = ($myNET | measure).Count

    #define array with extensions
    $Ext = @("Name", "Speed")

    #loop for every additional NETAdapter
    for($i = 1; $i -lt($myNET | Measure).Count; $i++){
        
        #loop for every extension and value
        for($j = 0; $j -lt $Ext.Count ; $j++){
            #prepare name for property
            $Name = "NET$i" + $Ext[$j]
            
            #manipuliate the hashtable 
            $temp = $Ext[$j]             
            $myHash += @{$Name = $myNET[$i].$temp}
        }               
    }
}

function add-Hash-DISK{
    $myHash.DISKCount = ($myDISK | measure).Count

    #define array with extensions and names
    $Ext = @("Name", "Description", "Size", 'Free space', "FileSystem", "Blocksize")
    $help = @("Name", "Description", "Size", "Freespace" ,"System", "Blocksize")

    #loop for every additional DISK
    for($i = 1; $i -lt($myDISK | Measure).Count; $i++){ #last DISK avaiable ?!?!?! need a test!###############################

        #loop for every extension and value
        for($j = 0; $j -lt $Ext.Count ; $j++){
            #prepare name for property
            $Name = "DISK$i" + $help[$j]
                
            #manipuliate the hashtable 
            $temp = $Ext[$j]             
            $myHash += @{$Name = $myDISK[$i].$temp}
        }               
    }
}
#Functions END #################################################################

#Main
#debug zone #################################################################################################
if($mydebug){ 
Write-Warning "OS information"
& Get-OSinfo | Format-List

Write-Warning "Disk information"

& get-DiskInfo | Format-List

Write-Warning "Net information"

& get-myNetAdapter | Format-List

Write-Warning "CPU information"

& get-CPUinfo | Format-List 
}
#debug zone end ################################################################################################

#Put Information in vars
# auch ( & get-osinfo) möglich
$myOS = & Get-OSinfo
$myDISK = & get-DiskInfo
$myNET = & get-myNetAdapter
$myCPU = & get-CPUinfo

#set default hastable for object with values for OS and CPU
$myHash =[Ordered] @{
    OS = $myOS.OS
    OSVersion = $myOS.Version
    OSArchitecture = $myOS.Architecture
    Memory = $myOS.'Memory Size'

    #further information for CPU
    CPUCount = 1
    CPU0Name = $myCPU[0].Name
    CPU0Description = $myCPU[0].Description
    CPU0Cores = $myCPU[0].Cores
    CPU0Clock = $myCPU[0].'Clock speed'    
}

If(($myCPU | measure).Count -gt 1){

    #& add-Hash-CPU

    #NOT in function!
    ####################################################################################
    #Set the number of CPU
    $myHash.CPUCount = ($myCPU | measure).Count

    #loop for every additional CPU
    for($i = 1; $i -lt($myCPU | Measure).Count; $i++){

        #define array with extensions and names
        $Ext = @("Name", "Description", "Cores", 'Clock speed')
        $help = @("Name", "Description", "Cores", "Clock")

        #loop for every extension and value
        for($j = 0; $j -lt $Ext.Count ; $j++){
            #prepare name for property
            $Name = "CPU$i" + $help[$j]
                
            #manipuliate the hashtable 
            $temp = $Ext[$j]             
            $myHash += @{$Name = $myCPU[$i].$temp}
        }                       
    }
    ####################################################################################
}

$myHash += [Ordered] @{ #pepare the default hash further with normal values for NET

    NETCount = 1
    NET0Name = $myNET[0].Name
    NET0Speed = $myNET[0].Speed
}

#If there more than one NETAdapter
If(($myNET | Measure).Count -gt 1){
   
    #& add-Hash-NET
    # NOT in function #################################################################
    #set the number of Adapter
    $myHash.NETCount = ($myNET | measure).Count

    #define array with extensions
    $Ext = @("Name", "Speed")

    #loop for every additional NETAdapter
    for($i = 1; $i -lt($myNET | Measure).Count; $i++){
        
        #loop for every extension and value
        for($j = 0; $j -lt $Ext.Count ; $j++){
            #prepare name for property
            $Name = "NET$i" + $Ext[$j]
            
            #manipuliate the hashtable 
            $temp = $Ext[$j]             
            $myHash += @{$Name = $myNET[$i].$temp}
        }               
    }
    ####################################################################################
}


$myHash += [Ordered] @{ #pepare the default hash further with normal values for DISK

    DISKCount = 1
    DISK0Name =$myDISK[0].Name
    DISK0Description = $myDISK[0].Description
    DISK0Size = $myDISK[0].Size
    DISK0FreeSpace = $myDISK[0].'Free space'
    DISK0System = $myDISK[0].Filesystem
    DISK0Blocksize = $myDISK[0].Blocksize
}

#If there more than one DISK
If(($myDISK | Measure).Count -gt 1){

    #& add-Hash-DISK
    # NOT IN FUNCTION
    ####################################################################################
    $myHash.DISKCount = ($myDISK | measure).Count

    #define array with extensions and names
    $Ext = @("Name", "Description", "Size", 'Free space', "FileSystem", "Blocksize")
    $help = @("Name", "Description", "Size", "Freespace" ,"System", "Blocksize")

    #loop for every additional DISK
    for($i = 1; $i -lt($myDISK | Measure).Count; $i++){   #####maybeeeeeee ######################################

        #loop for every extension and value
        for($j = 0; $j -lt $Ext.Count ; $j++){
            #prepare name for property
            $Name = "DISK$i" + $help[$j]
                
            #manipuliate the hashtable 
            $temp = $Ext[$j]             
            $myHash += @{$Name = $myDISK[$i].$temp}
        }               
    }
    ####################################################################################
}

# debug zone #########################################################################################################
if($mydebug){
    Write-Warning("My created object")
    $test = New-Object -TypeName psobject -Property $myHash
    $test | Select-Object -Property *

    Export-Clixml -InputObject $test -Path "$xmlpath\$xmlfile" 

    #Export-Clixml -InputObject $b -Path "$xmlpath\++Disk.xml"

    #Export-Csv -InputObject $a -Path "$xmlpath\$txtfile"
    #Export-Csv -InputObject $b -Path "$xmlpath\$txtfile" -Append

    }
    else{
    New-Object -TypeName psobject -Property $myHash | Export-Clixml -Path "$xmlpath\$xmlfile"
    }
# debug zone end #####################################################################################################
