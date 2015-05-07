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

function CheckRemoveDir($path)
{
    if (Test-Path $path) {
        Remove-Item -Recurse -Force $path
    }
}

function GitClonePull($path, $url, $branch="master")
{
    Write-Host "Cloning / pulling: $url, branch: $branch"

    $needspull = $true

    if (!(Test-Path -path $path))
    {
        git clone -b $branch $url
        if ($LastExitCode) { throw "git clone failed" }
        $needspull = $false
    }

    if ($needspull)
    {
        pushd .
        try
        {
            cd $path

            $branchFound = (git branch)  -match "(.*\s)?$branch"
            if ($LastExitCode) { throw "git branch failed" }

            git reset --hard
            if ($LastExitCode) { throw "git reset failed" }

            git clean -f -d
            if ($LastExitCode) { throw "git clean failed" }

            if($branchFound)
            {
                git checkout $branch
                if ($LastExitCode) { throw "git checkout failed" }
            }
            else
            {
                git checkout -b $branch origin/$branch
                if ($LastExitCode) { throw "git checkout failed" }
            }

            git pull
            if ($LastExitCode) { throw "git pull failed" }
        }
        finally
        {
            popd
        }
    }
}

function Expand7z($archive, $outputDir = ".")
{
    pushd .
    try
    {
        cd $outputDir
        &7z.exe x -y $archive
        if ($LastExitCode) { throw "7z.exe failed on archive: $archive"}
    }
    finally
    {
        popd
    }
}

function SetVCVars($version="12.0")
{
    pushd "$ENV:ProgramFiles (x86)\Microsoft Visual Studio $version\VC\"
    try
    {
        cmd /c "vcvarsall.bat&set" |
        foreach {
          if ($_ -match "=") {
            $v = $_.split("="); set-item -force -path "ENV:\$($v[0])"  -value "$($v[1])"
          }
        }
    }
    finally
    {
        popd
    }
}

function ExecRetry($command, $maxRetryCount = 10, $retryInterval=2)
{
    $currErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"

    $retryCount = 0
    while ($true)
    {
        try
        {
            & $command
            break
        }
        catch [System.Exception]
        {
            $retryCount++
            if ($retryCount -ge $maxRetryCount)
            {
                $ErrorActionPreference = $currErrorActionPreference
                throw
            }
            else
            {
                Write-Error $_.Exception
                Start-Sleep $retryInterval
            }
        }
    }

    $ErrorActionPreference = $currErrorActionPreference
}

function DownloadFile($url, $dest)
{
    Write-Host "Downloading: $url"

    $webClient = New-Object System.Net.webclient
    $webClient.DownloadFile($url, $dest)
}

function ChechFileHash($path, $hash, $algorithm="SHA1") {
    $h = Get-Filehash -Algorithm $algorithm $path
    if ($h.Hash.ToUpper() -ne $hash.ToUpper()) {
        throw "Hash comparison failed for file: $path"
    }
}
