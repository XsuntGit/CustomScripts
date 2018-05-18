param
(
    [string]$FileToUnZip = $(Throw "Missing parameter: -FileToUnZip"),
    [string]$OutputPath = $(Throw "Missing parameter: -OutputPath"),
    [string]$Passw = $(Throw "Missing parameter: -Passw")
)
$pathTo64Bit7Zip = "C:\Program Files\7-Zip\7z.exe";
$Params = "e ""$FileToUnZip"" -o""$OutputPath"" -p""$Passw"" -aoa"
Start-Process $pathTo64Bit7Zip -ArgumentList $Params -Wait -PassThru -NoNewWindow
