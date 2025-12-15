# PowerShell script to create zip (Windows)
$Out = "A-De4t_financial_starter.zip"
$Temp = Join-Path $env:TEMP ("a-de4t-starter-" + [guid]::NewGuid().ToString())
New-Item -ItemType Directory -Path $Temp | Out-Null

# Minimal set (to keep script readable) - in practice use the full files provided above
Set-Content -Path (Join-Path $Temp "README.md") -Value "# A-De4t 模拟金融交易 Starter（商品类，单一卖家）`n`n请参考提供的模板文件。"

# package.json
Set-Content -Path (Join-Path $Temp "package.json") -Value '{
  "name": "a-de4t-financial-starter",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "dev": "next dev -p 3000",
    "build": "next build",
    "start": "next start -p 3000",
    "lint": "next lint"
  },
  "dependencies": {
    "@supabase/supabase-js": "^2.31.0",
    "next": "13.5.4",
    "react": "18.2.0",
    "react-dom": "18.2.0"
  }
}'

# create zip
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::CreateFromDirectory($Temp, $Out)
Remove-Item -Recurse -Force $Temp
Write-Host "Created $Out"