param(
    [string]$Path = (Join-Path $PSScriptRoot "..\plugins.json")
)

$ErrorActionPreference = "Stop"
$market = Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json
if ($null -eq $market.plugins -or $market.plugins.Count -eq 0) {
    throw "plugins.json has no plugins"
}

$ids = @{}
$errors = New-Object System.Collections.Generic.List[string]

foreach ($item in $market.plugins) {
    if ([string]::IsNullOrWhiteSpace($item.id)) {
        $errors.Add("plugin without id")
        continue
    }
    if ($ids.ContainsKey($item.id)) {
        $errors.Add("duplicate id: $($item.id)")
    } else {
        $ids[$item.id] = $true
    }

    $provider = if ([string]::IsNullOrWhiteSpace($item.provider)) { "bundle" } else { $item.provider }
    switch ($provider) {
        "builtin" {
            if ([string]::IsNullOrWhiteSpace($item.builtin)) {
                $errors.Add("$($item.id): builtin requires builtin key")
            }
        }
        "bundle" {
            if ([string]::IsNullOrWhiteSpace($item.downloadUrl)) {
                $errors.Add("$($item.id): bundle requires downloadUrl")
            }
            if ([string]::IsNullOrWhiteSpace($item.sha256)) {
                $errors.Add("$($item.id): bundle requires sha256")
            }
        }
        "official-apk" {
            if ([string]::IsNullOrWhiteSpace($item.officialUrl)) {
                $errors.Add("$($item.id): official-apk requires officialUrl")
            }
        }
        "official-apk-java" {
            if ([string]::IsNullOrWhiteSpace($item.downloadUrl)) {
                $errors.Add("$($item.id): official-apk-java requires downloadUrl")
            }
            if ([string]::IsNullOrWhiteSpace($item.mainClass)) {
                $errors.Add("$($item.id): official-apk-java requires mainClass")
            }
            if ([string]::IsNullOrWhiteSpace($item.sha256)) {
                $errors.Add("$($item.id): official-apk-java requires sha256")
            }
        }
        default {
            $errors.Add("$($item.id): unknown provider $provider")
        }
    }
}

if ($errors.Count -gt 0) {
    $errors | ForEach-Object { Write-Error $_ }
    exit 1
}

$builtin = @($market.plugins | Where-Object { $_.provider -eq "builtin" }).Count
$bundle = @($market.plugins | Where-Object { $_.provider -eq "bundle" }).Count
$official = @($market.plugins | Where-Object { $_.provider -eq "official-apk" }).Count
$officialJava = @($market.plugins | Where-Object { $_.provider -eq "official-apk-java" }).Count
Write-Host "OK: total=$($market.plugins.Count), builtin=$builtin, bundle=$bundle, official-apk=$official, official-apk-java=$officialJava"
