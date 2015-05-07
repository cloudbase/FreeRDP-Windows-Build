#REQUIRES -Version 2.0

# Copyright 2012 Cloudbase Solutions Srl
# All Rights Reserved.
#
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.

function GetVMConsole($host, $filter, $fullscreen, $wait) {

    if([Environment]::OSVersion.Version -ge (new-object 'Version' 6, 2)) {
        $ns = "root\virtualization\v2"
    }
    else {
        $ns = "root\virtualization"
    }

    $vm = Get-WmiObject -Class Msvm_ComputerSystem -Namespace $ns -ComputerName $host -Filter ("Description <> 'Microsoft Hosting Computer System' AND " + $filter)
    if(!$vm) {
        throw "Virtual machine not found"
    }
    if($vm.EnabledState -ne 2) {
        throw "The virtual machine """ + $vm.ElementName + """ is not running"
    }

    $wFreeRdpPath = "$ENV:SystemRoot\wfreerdp.exe"

    $args = @("/vmconnect:" + $vm.Name, "/v:$host", "/t:" + $vm.ElementName)
    if($fullscreen) {
        $args += "/toggle-fullscreen"
    }

    if($wait) {
        $retVal = (Start-Process -FilePath $wFreeRdpPath -ArgumentList $args -Wait -Passthru).ExitCode
        if($retVal -ne 0) {
            throw "wfreerdp exited with return value: $retVal"
        }
    }
    else {
        Start-Process -FilePath $wFreeRdpPath -ArgumentList $args
    }
}

<#
.DESCRIPTION
    This Cmdlet starts a Hyper-V console session by using FreeRDP. It is highly portable, works on any Hyper-V version and doesn't require installation.
    Use cmdkey to setup the credentials to a remote server.
.NOTES
    Copyright 2012 - Cloudbase Solutions Srl
.LINK
    http://www.cloudbase.it
.EXAMPLE
    Get-VMConsole MyVM
.EXAMPLE
    cmdkey /add:MyHyperVHost /user:MyUserName /pass
    Get-VMConsole MyVM -HyperVHost MyHyperVHost
.EXAMPLE
    Get-VM | where {$_.State -eq "Running"} | Get-VMConsole
#>
function Get-VMConsole {
    [CmdletBinding(DefaultParameterSetName="VMName")]
    param (

        [parameter(Mandatory=$true,Position=0,ParameterSetName="VMName")]
        [string[]]$VMName,

        [parameter(Mandatory=$false,Position=0,ParameterSetName="VM", ValueFromPipeline=$true)]
        [PSObject[]]$VM,

        [parameter(Mandatory=$false,Position=1)]
        [string]$HyperVHost = "127.0.0.1",

        [parameter(Mandatory=$false,Position=2)]
        [switch]$Wait = $false
    )
    PROCESS {
        if($VM) {
            $name = $VM.Id
            GetVMConsole $HyperVHost "Name = '$name'" $false $Wait
        }
        else {
            foreach($ElementName in $VMName) {
                GetVMConsole $HyperVHost "ElementName = '$ElementName'" $false $Wait
            }
        }
    }
}
