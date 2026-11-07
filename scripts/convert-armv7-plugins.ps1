param(
    [string]$OfficialPluginDir = 'D:\codex1\project-053-宝盒手机版TV版对比\tmp\official387-plugins',
    [string]$OriginalTvDir = 'D:\codex1\project-053-宝盒手机版TV版对比\src\original-tv-upgrade\work-apktool',
    [string]$MergedArmv7Dir = 'D:\codex1\project-053-宝盒手机版TV版对比\src\box-armv7-enhanced\app\build\intermediates\merged_native_libs\armeabiGenericNormalDebug\out\lib\armeabi-v7a',
    [string]$FfmpegJniV7 = 'D:\codex1\project-053-宝盒手机版TV版对比\tmp\gradle-home\caches\transforms-3\0058c35432cb1e29f88ea422398c4896\transformed\jetified-lib-decoder-ffmpeg-release\jni\armeabi-v7a\libffmpegJNI.so',
    [string]$Media3ExtV7 = 'D:\codex1\project-053-宝盒手机版TV版对比\tmp\gradle-home\caches\transforms-3\19a9ecc4ddc170ff2d793645f24c9021\transformed\jetified-nextlib-media3ext-0.7.1\jni\armeabi-v7a',
    [string]$MpvV7Dir = 'D:\codex1\project-036-tvwall-mpv-player\src\app\src\main\jniLibs\armeabi-v7a',
    [string]$RuntimeDir = 'D:\codex1\project-053-宝盒手机版TV版对比\artifacts\box-armv7-plugins\runtime\runtime-armv7-20261106',
    [string]$RepoRoot = 'D:\codex1\project-053-宝盒手机版TV版对比\artifacts\box-armv7-plugins',
    [string]$RawBase = 'https://raw.githubusercontent.com/CHEN2222152/box-armv7-plugins/main/plugins/armv7'
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem

$outputDir = Join-Path $RepoRoot 'plugins\armv7'
New-Item -ItemType Directory -Path $outputDir -Force | Out-Null

function Get-RequiredFile {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Required file not found: $Path"
    }
    return $Path
}

function Remove-EntryPrefix {
    param(
        [IO.Compression.ZipArchive]$Archive,
        [string]$Prefix
    )
    $entries = @($Archive.Entries | Where-Object {
        $_.FullName.StartsWith($Prefix, [StringComparison]::OrdinalIgnoreCase)
    })
    foreach ($entry in $entries) {
        $entry.Delete()
    }
}

function Set-ZipEntry {
    param(
        [IO.Compression.ZipArchive]$Archive,
        [string]$EntryName,
        [string]$SourcePath
    )
    $old = $Archive.GetEntry($EntryName)
    if ($null -ne $old) {
        $old.Delete()
    }
    $entry = $Archive.CreateEntry($EntryName, [IO.Compression.CompressionLevel]::Optimal)
    $input = [IO.File]::OpenRead((Get-RequiredFile $SourcePath))
    try {
        $output = $entry.Open()
        try {
            $input.CopyTo($output)
        } finally {
            $output.Dispose()
        }
    } finally {
        $input.Dispose()
    }
}

function Copy-Plugin {
    param(
        [string]$SourceName,
        [string]$OutputName
    )
    $source = Join-Path $OfficialPluginDir $SourceName
    $target = Join-Path $outputDir $OutputName
    Copy-Item -LiteralPath (Get-RequiredFile $source) -Destination $target -Force
    return $target
}

function Convert-Plugin {
    param(
        [string]$SourceName,
        [string]$OutputName,
        [hashtable]$Libraries = @{},
        [hashtable]$Assets = @{},
        [string[]]$RemoveAssetPrefixes = @()
    )

    $target = Copy-Plugin -SourceName $SourceName -OutputName $OutputName
    $zip = [IO.Compression.ZipFile]::Open($target, [IO.Compression.ZipArchiveMode]::Update)
    try {
        foreach ($abi in @('lib/arm64-v8a/', 'lib/x86/', 'lib/x86_64/')) {
            Remove-EntryPrefix -Archive $zip -Prefix $abi
        }
        foreach ($prefix in $RemoveAssetPrefixes) {
            Remove-EntryPrefix -Archive $zip -Prefix $prefix
        }
        foreach ($name in $Libraries.Keys) {
            Set-ZipEntry -Archive $zip -EntryName "lib/armeabi-v7a/$name" -SourcePath $Libraries[$name]
        }
        foreach ($entryName in $Assets.Keys) {
            Set-ZipEntry -Archive $zip -EntryName $entryName -SourcePath $Assets[$entryName]
        }
    } finally {
        $zip.Dispose()
    }
    return $target
}

$originalV7 = Join-Path $OriginalTvDir 'lib\armeabi-v7a'
$originalAssets = Join-Path $OriginalTvDir 'assets'

$generated = @()
$generated += Copy-Plugin 'catspider.apk' 'catspider-armv7.apk'
$generated += Copy-Plugin 'drpysspider.apk' 'drpysspider-armv7.apk'
$generated += Copy-Plugin 'legado.apk' 'legado-armv7.apk'
$generated += Copy-Plugin 'lxmusic.apk' 'lxmusic-armv7.apk'
$generated += Copy-Plugin 'phpspider.apk' 'phpspider-armv7.apk'
$generated += Copy-Plugin 'youtube.apk' 'youtube-armv7.apk'

$generated += Convert-Plugin `
    -SourceName 'aliplayer.apk' `
    -OutputName 'aliplayer-armv7.apk' `
    -Libraries @{
        'libalivcffmpeg.so' = (Join-Path $MergedArmv7Dir 'libalivcffmpeg.so')
        'libsaasCorePlayer.so' = (Join-Path $MergedArmv7Dir 'libsaasCorePlayer.so')
        'libsaasDownloader.so' = (Join-Path $MergedArmv7Dir 'libsaasDownloader.so')
    }

$generated += Convert-Plugin `
    -SourceName 'exoplayer.apk' `
    -OutputName 'exoplayer-armv7.apk' `
    -Libraries @{
        'libavcodec.so' = (Join-Path $Media3ExtV7 'libavcodec.so')
        'libavutil.so' = (Join-Path $Media3ExtV7 'libavutil.so')
        'libffmpegJNI.so' = $FfmpegJniV7
        'libswresample.so' = (Join-Path $Media3ExtV7 'libswresample.so')
        'libswscale.so' = (Join-Path $Media3ExtV7 'libswscale.so')
    }

$generated += Convert-Plugin `
    -SourceName 'goproxy.apk' `
    -OutputName 'goproxy-armv7.apk' `
    -Assets @{
        'assets/go_proxy_video' = (Join-Path $originalAssets 'go_proxy_video')
    }

$generated += Convert-Plugin `
    -SourceName 'ijkplayer.apk' `
    -OutputName 'ijkplayer-armv7.apk' `
    -Libraries @{
        'libijkffmpeg.so' = (Join-Path $originalV7 'libijkffmpeg.so')
        'libijkplayer.so' = (Join-Path $originalV7 'libijkplayer.so')
        'libijksdl.so' = (Join-Path $originalV7 'libijksdl.so')
    }

$generated += Convert-Plugin `
    -SourceName 'jianpian.apk' `
    -OutputName 'jianpian-armv7.apk' `
    -Libraries @{
        'libjpa.so' = (Join-Path $originalV7 'libjpa.so')
    }

$generated += Convert-Plugin `
    -SourceName 'mpvplayer.apk' `
    -OutputName 'mpvplayer-armv7.apk' `
    -Libraries @{
        'libavcodec.so' = (Join-Path $MpvV7Dir 'libavcodec.so')
        'libavdevice.so' = (Join-Path $MpvV7Dir 'libavdevice.so')
        'libavfilter.so' = (Join-Path $MpvV7Dir 'libavfilter.so')
        'libavformat.so' = (Join-Path $MpvV7Dir 'libavformat.so')
        'libavutil.so' = (Join-Path $MpvV7Dir 'libavutil.so')
        'libc++_shared.so' = (Join-Path $MpvV7Dir 'libc++_shared.so')
        'libmpv.so' = (Join-Path $MpvV7Dir 'libmpv.so')
        'libplayer.so' = (Join-Path $MpvV7Dir 'libplayer.so')
        'libswresample.so' = (Join-Path $MpvV7Dir 'libswresample.so')
        'libswscale.so' = (Join-Path $MpvV7Dir 'libswscale.so')
    }

$generated += Convert-Plugin `
    -SourceName 'qjsspider.apk' `
    -OutputName 'qjsspider-armv7.apk' `
    -Libraries @{
        'libquickjs-android-wrapper.so' = (Join-Path $originalV7 'libquickjs-android-wrapper.so')
    }

$chaquopyAssetMap = @{}
Get-ChildItem -LiteralPath (Join-Path $originalAssets 'chaquopy') -Recurse -File | ForEach-Object {
    $relative = $_.FullName.Substring((Join-Path $originalAssets 'chaquopy').Length).TrimStart('\', '/')
    $chaquopyAssetMap[('assets/chaquopy/' + ($relative -replace '\\', '/'))] = $_.FullName
}

$generated += Convert-Plugin `
    -SourceName 'pyspider.apk' `
    -OutputName 'pyspider-armv7.apk' `
    -Libraries @{
        'libchaquopy_java.so' = (Join-Path $originalV7 'libchaquopy_java.so')
        'libcrypto_chaquopy.so' = (Join-Path $originalV7 'libcrypto_chaquopy.so')
        'libpython3.8.so' = (Join-Path $originalV7 'libpython3.8.so')
        'libsqlite3_chaquopy.so' = (Join-Path $originalV7 'libsqlite3_chaquopy.so')
        'libssl_chaquopy.so' = (Join-Path $originalV7 'libssl_chaquopy.so')
    } `
    -Assets $chaquopyAssetMap `
    -RemoveAssetPrefixes @('assets/chaquopy/')

$generated += Convert-Plugin `
    -SourceName 'thunder.apk' `
    -OutputName 'thunder-armv7.apk' `
    -Libraries @{
        'libxl_stat.so' = (Join-Path $originalV7 'libxl_stat.so')
        'libxl_thunder_sdk.so' = (Join-Path $originalV7 'libxl_thunder_sdk.so')
    }

Copy-Item -LiteralPath (Join-Path $RuntimeDir 'node-armv7.apk') -Destination (Join-Path $outputDir 'node-armv7.apk') -Force
Copy-Item -LiteralPath (Join-Path $RuntimeDir 'php-armv7.apk') -Destination (Join-Path $outputDir 'php-armv7.apk') -Force
$generated += (Join-Path $outputDir 'node-armv7.apk')
$generated += (Join-Path $outputDir 'php-armv7.apk')

$rows = Get-ChildItem -LiteralPath $outputDir -File -Filter '*.apk' | Sort-Object Name | ForEach-Object {
    [pscustomobject]@{
        File = $_.Name
        Bytes = $_.Length
        SHA256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $_.FullName).Hash
        Url = "$RawBase/$($_.Name)"
    }
}

$rows | Export-Csv -LiteralPath (Join-Path $outputDir 'CONVERTED.csv') -NoTypeInformation -Encoding UTF8
$rows | ForEach-Object { "$($_.SHA256)  $($_.File)" } |
    Set-Content -LiteralPath (Join-Path $outputDir 'SHA256SUMS.txt') -Encoding ASCII

$rows | Format-Table -AutoSize
