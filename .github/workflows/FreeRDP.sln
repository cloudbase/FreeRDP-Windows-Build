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

$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
. "$scriptPath\BuildUtils.ps1"

function BuildOpenSSL($buildDir, $outputPath, $opensslVersion, $cmakeGenerator, $platformToolset,
                      $dllBuild=$true, $runTests=$true, $hash=$null)
{
    $opensslBase = "openssl-$opensslVersion"
    $opensslPath = "$ENV:Temp\$opensslBase.tar.gz"
    $opensslUrl = "https://www.openssl.org/source/$opensslBase.tar.gz"

    pushd .
    try
    {
        cd $buildDir

        # Needed by the OpenSSL server 
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        ExecRetry { (new-object System.Net.WebClient).DownloadFile($opensslUrl, $opensslPath) }

        if($hash) { ChechFileHash $opensslPath $hash }

        Expand7z $opensslPath
        del $opensslPath
        Expand7z "$opensslBase.tar"
        del "$opensslBase.tar"

        cd $opensslBase
        &cmake . -G $cmakeGenerator -T $platformToolset

        &perl Configure VC-WIN32 --prefix="$ENV:OPENSSL_ROOT_DIR"
        if ($LastExitCode) { throw "perl failed" }

        &.\ms\do_nasm
        if ($LastExitCode) { throw "do_nasm failed" }

        if($dllBuild)
        {
            $makFile = "ms\ntdll.mak"
        }
        else
        {
            $makFile = "ms\nt.mak"
        }

        &nmake -f $makFile
        if ($LastExitCode) { throw "nmake failed" }

        if($runTests)
        {
            &nmake -f $makFile test
            if ($LastExitCode) { throw "nmake test failed" }
        }

        &nmake -f $makFile install
        if ($LastExitCode) { throw "nmake install failed" }

        copy "$ENV:OPENSSL_ROOT_DIR\bin\*.dll" $outputPath
        copy "$ENV:OPENSSL_ROOT_DIR\bin\*.exe" $outputPath
    }
    finally
    {
        popd
    }
}


function BuildFreeRDP($buildDir, $outputPath, $patchesPath, $cmakeGenerator, $platformToolset, $monolithicBuild=$true,
                      $buildSharedLibs=$true, $staticRuntime=$false, $setBuildEnvVars=$true, $platform="Win32", $branch="master")
{
    $freeRDPdir = "FreeRDP"
    $freeRDPUrl = "https://github.com/FreeRDP/FreeRDP.git"

    pushd .
    try
    {
        cd $buildDir
        ExecRetry { GitClonePull $freeRDPdir $freeRDPUrl $branch }
        cd $freeRDPdir

        if($monolithicBuild) { $monolithicBuildStr = "ON" } else { $monolithicBuildStr = "OFF" }
        if($buildSharedLibs) { $buildSharedLibsStr = "ON" } else { $buildSharedLibsStr = "OFF" }
        if($staticRuntime) { $runtime = "static" } else { $runtime = "dynamic" }

        &cmake . -DBUILD_SHARED_LIBS=ON -G $cmakeGenerator -T $platformToolset -DMONOLITHIC_BUILD="$monolithicBuildStr" -DBUILD_SHARED_LIBS="$buildSharedLibsStr" -DMSVC_RUNTIME="$runtime" -DWITH_SSE2=ON -DBUILD_TESTING=OFF
        if ($LastExitCode) { throw "cmake failed" }

        &msbuild FreeRDP.sln /m /p:Configuration=Release /p:Platform=$platform
        if ($LastExitCode) { throw "MSBuild failed" }

        copy "LICENSE" $outputPath
        copy "Release\*.dll" $outputPath
        copy "Release\*.exe" $outputPath

        # Verify that FreeRDP runs properly so when know that all dependencies are in place
        $p = Start-Process -Wait -PassThru -NoNewWindow "$outputPath\wfreerdp.exe"
        if($p.ExitCode -ne 1)
        {
            throw "wfreerdp test run failed with exit code: $($p.ExitCode)"
        }

        if($setBuildEnvVars)
        {
            $ENV:INCLUDE += ";$buildDir\$freeRDPdir\include"
            $ENV:INCLUDE += ";$buildDir\$freeRDPdir\winpr\include"
            $ENV:LIB += ";$buildDir\$freeRDPdir\Release"
        }
    }
    finally
    {
        popd
    }
}
