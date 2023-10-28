if((Test-Path -Path C:\Users\$env:USERNAME\Desktop\nettest.log)){ 
    Remove-Item "C:\Users\$env:USERNAME\Desktop\nettest.log" 
}

New-Item C:\Users\$env:USERNAME\Desktop\nettest.log
$domaine = "webeex.net"

function VerifierConnexion{
   return Test-Connection 8.8.8.8 -count 1
}

function VerifierPort143{
    return Test-NetConnection -computername $domaine -Port 143 | where-object {$_.TcpTestSucceeded -eq $true}
}

function VerifierPort993{
    return Test-NetConnection -computername $domaine -Port 993 | where-object {$_.TcpTestSucceeded -eq $true}
}

for(;;){
$date = Get-Date -Format "yyyy/MM/dd HH:mm"

if(VerifierConnexion){
        if(VerifierPort143){ 
            Add-Content -Path "C:\Users\$env:USERNAME\Desktop\nettest.log" -Value "$date $domaine Port:143 = OK"
        }
        else{
            Add-Content -Path "C:\Users\$env:USERNAME\Desktop\nettest.log" -Value "$date $domaine Port:143 = FAILED"
        }

        if(VerifierPort993){ 
            Add-Content -Path "C:\Users\$env:USERNAME\Desktop\nettest.log" -Value "$date $domaine Port:993 = OK"
        }
        else{
            Add-Content -Path "C:\Users\$env:USERNAME\Desktop\nettest.log" -Value "$date $domaine Port:993 = FAILED"
        }
    }

else{
    Add-Content -Path "C:\Users\$env:USERNAME\Desktop\nettest.log" -Value "$date ECHEC DE LA CONNECTION INTERNET"
}

Start-Sleep 100
}