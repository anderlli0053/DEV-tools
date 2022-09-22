# Copyright 2022 Christopher K. "Shmish" Schmitt
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


# Base cuDNN archive url as well as specific archives that should be excluded
# from the final output.
$root = "https://developer.download.nvidia.com/compute/redist/cudnn/"
$exclude = 
    "https://developer.download.nvidia.com/compute/redist/cudnn/v7.5.1/9.0_20190418/cudnn-9.0-windows7-x64-v7.5.1.10.zip",
    "https://developer.download.nvidia.com/compute/redist/cudnn/v7.5.1/9.0_20190418/cudnn-9.0-windows10-x64-v7.5.1.10.zip",
    "https://developer.download.nvidia.com/compute/redist/cudnn/v7.5.1/9.2_20190418/cudnn-9.2-windows7-x64-v7.5.1.10.zip",
    "https://developer.download.nvidia.com/compute/redist/cudnn/v7.5.1/9.2_20190418/cudnn-9.2-windows10-x64-v7.5.1.10.zip"


# .SYNOPSIS
# Recursively tranverses links, collecting any zip archive files along the way.
# Takes as input the base url to start scanning.  All located archives are
# appened to this base url.
# .PARAMETER path
# The base url to scan from
function Get-Archives {
    param (
        [String] $path
    )

    switch -Wildcard ($path) {
        "*/" { 
            return Invoke-WebRequest -Uri $path |
                ForEach-Object { $_.links } |
                ForEach-Object { $_.href } |
                ForEach-Object { Get-Archives ($path + $_) }
         }

        "*.zip" {
            return $path
        }
        
        Default { 
            return $()
        }
    }
}


# Exclude old, release candidate, and null values from the archive list.  Also
# exclude any archives explicity defined at the top of this file.
$archives = Get-Archives $root |
    Where-Object { $_ -NotIn $exclude } |
    Where-Object { $_ -NotLike "*rc.zip" } |
    Where-Object { $_ -NotLike "*old.zip" } |
    Where-Object { $_ -ne $null }


# Filter archives and process each file.  Create a manifest for every archive
# found by Get-Archives.  Write each manifest to the bucket directory.
foreach ($archive in $archives) {
    # Define the target triple.  A target triple is made up of the cuDNN
    # library version, the CUDA version it is built for, and the platform it is
    # compatable with (eg. windows10).
    [String] $cudnn_version = ""
    [String] $cuda_version = ""
    [String] $platform = ""

    # Discover platform triple by deconstructing the archive path.
    switch -Regex ($archive) {
        "cudnn/v(.*?)/" { $cudnn_version = $matches[1] }
        "cudnn-(.*?)-" { $cuda_version = $matches[1] }
        "local_installers/(.*?)/" { $cuda_version = $matches[1] }
        "(win.*?)-" { $platform = $matches[1] }
    }

    # Define the manifest file name.  This name should represent the target
    # triple in (cuDNN-CUDA-platform) order
    $name = "bucket/cuDNNv$cudnn_version-CUDAv$cuda_version-$platform.json"

    # Define the manifest itself.  This istructs scoop to install the cuDNN
    # triple and defines the uninstaller.
    $manifest = @{
        "version" = $cudnn_version
        "description" = "NVIDIA CUDA Deep Neural Network (cuDNN) is a GPU-accelerated library of primitives for deep neural networks."
        "homepage" = "https://developer.nvidia.com/rdp/cudnn-download"
        "depends" = @("cuda")
        "architecture" = @{
            "64bit" = @{
                "url" = $archive
            }
        }
        "extract_dir" = "cuda"
        "installer" = @{
            "script" =
                "if (-not `$env:CUDA_PATH) {",
                "   Write-Error 'Environment variable `"CUDA_PATH`" not set.'",
                "   return",
                "}",
                "Get-ChildItem -LiteralPath `$dir |",
                "   ForEach-Object { `$_.fullname } |",
                "   Copy-Item -Destination `$env:CUDA_PATH -Recurse -Force"
        }
        "uninstaller" = @{
            "script" =
                "if (-not `$env:CUDA_PATH) {",
                "   Write-Error 'Environment variable `"CUDA_PATH`" not set.'",
                "   return",
                "}",
                "`$files = Get-ChildItem -LiteralPath `$env:CUDA_PATH -File -Recurse | Where-Object {",
                "   `$_.name -Like `"cudnn64.*.dll`" -or",
                "   `$_.name -Like `"cudnn.h`" -or",
                "   `$_.name -Like `"cudnn.lib`"",
                "}",
                "Remove-Item -LiteralPath `$files -Force"
        }
    }

    # Write the manifest to the bucket directory
    ConvertTo-Json $manifest | Out-File $name -Encoding utf8
}
