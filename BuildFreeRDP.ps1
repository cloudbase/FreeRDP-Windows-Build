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

param (
    [string]$branch="master",
    [string]$outputZipPath="wfreerdp.zip"
)

$ErrorActionPreference = "Stop"

$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
. "$scriptPath\BuildUtils.ps1"
. "$scriptPath\Dependencies.ps1"

# Make sure ActivePerl comes before MSYS Perl, otherwise
# the OpenSSL build will fail
$ENV:PATH = "C:\Perl\bin;$ENV:PATH"
$ENV:PATH += ";$ENV:ProgramFiles\7-Zip"
$ENV:PATH += ";${ENV:ProgramFiles(x86)}\Git\bin"
$ENV:PATH += ";${ENV:ProgramFiles(x86)}\CMake 2.8\bin"
$ENV:PATH += ";${ENV:ProgramFiles(x86)}\nasm"

$vsVersion = "12.0"
$opensslVersion = "1.0.1m"
$opensslSha1 = "4ccaf6e505529652f9fdafa01d1d8300bd9f3179"

$cmakeGenerator = "Visual Studio $($vsVersion.Split(".")[0])"
$platformToolset = "v$($vsVersion.Replace('.', ''))_xp"
SetVCVars $vsVersion

$basePath = "C:\Build\FreeRDP-$branch"
$buildDir = "$basePath\Build"
$outputPath = "$buildDir\bin"

$ENV:OPENSSL_ROOT_DIR="$outputPath\OpenSSL"

pushd .
try
{
    CheckRemoveDir $buildDir
    mkdir $buildDir
    cd $buildDir
    mkdir $outputPath

    BuildOpenSSL $buildDir $outputPath $opensslVersion $cmakeGenerator $platformToolset $false $true $opensslSha1
    BuildFreeRDP $buildDir $outputPath $scriptPath $cmakeGenerator $platformToolset $true $false $true $branch

    $freeRdpPsm1Path = Join-Path $scriptPath "Hyper-V\FreeRDP.psm1"
    $hypervOutputPath = "$outputPath\Hyper-V"

    mkdir $hypervOutputPath
    copy $freeRdpPsm1Path $hypervOutputPath

    &7z.exe a -tzip $outputZipPath "$outputPath\wfreerdp.exe" "$outputPath\LICENSE" "$hypervOutputPath"
    if ($LastExitCode) { throw "7z failed" }
}
finally
{
    popd
}
