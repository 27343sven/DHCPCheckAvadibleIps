$ips = @()
$range_start = @()
$range_end = @()
[int]$total_ips = 0
foreach ($line in $(netsh dhcp server scope 192.168.1.0 show iprange)){
	if ($line[3] -match '[0-9]'){
		$range_start += [int]$($line.Replace(' ', '').split("-")[0].split(".")[3])
		$range_end += [int]$($line.Replace(' ', '').split("-")[1].split(".")[3])
		$total_ips += [int]$($line.Replace(' ', '').split("-")[1].split(".")[3]) - [int]$($line.Replace(' ', '').split("-")[0].split(".")[3]) + 1
		
	}
}
foreach ($line in $(netsh dhcp server scope 192.168.1.0 show clients)){
	if ($line -match '^[0-9]'){
		$ip = $line.split('')[0]
		[int]$number = $line.split('')[0].split(".")[3]
		$valid = 0
		for ($i=0; $i -lt $range_start.length; $i++){
			if ($number -gt $range_start[$i] -And $number -lt $range_end[$i]){
				$valid = 1
			}
		}
		if ($valid -eq 1){
			$ips += $ip
		}
	}
}

[int]$ips_left = $total_ips - $ips.length
$severety = 14
$hostname = "192.168.1.3"
$time = Get-Date -Format "yyyy:MM:dd:-HH:mm:ss zzz"
$message = ""
$UDPClient = New-Object System.Net.Sockets.UDPClient
$UDPClient.Connect('192.168.1.52', '514')
if ([int]$ips_left -gt 10){
	$message = "IP addresses left: " + $ips_left.ToString()
} elseif ([int]$ips_left -gt 0){
	$message = "Warning! number of avadible ip's getting low! IP addresses left: " + $ips_left.ToString()
	$severety = 12
} else {
	$message = "Error! No ip's left! IP addresses left: " + $ips_left.ToString()
	$severety = 11
}

$fullSysLogMessage = "<{0}><{1}><{2}> {3}" -f $severety, $time, $hostname, $message
$byteMessage = $([System.Text.Encoding]::ASCII).GetBytes($fullSysLogMessage)
$UDPClient.Send($byteMessage, $byteMessage.length) | Out-Null