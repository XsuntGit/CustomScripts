param
(
    [string]$InstanceName = $(Throw "Parameter missing: -InstanceName InstanceName"),
    [string]$Database =  $(Throw "Parameter missing: -Database Database"),
    [string]$Table =  $(Throw "Parameter missing: -Table Table"),
    [string]$FilePath =  $(Throw "Parameter missing: -FilePath FilePath")
)
 
$smoversions = "14.0.0.0", "13.0.0.0", "12.0.0.0", "11.0.0.0", "10.0.0.0", "9.0.242.0", "9.0.0.0"
foreach ($smoversion in $smoversions)
{
    try
    {
        Add-Type -AssemblyName "Microsoft.SqlServer.Smo, Version=$smoversion, Culture=neutral, PublicKeyToken=89845dcd8080cc91" -ErrorAction Stop
        $smoadded = $true
    }
    catch
    {
        $smoadded = $false
    }
    if ($smoadded -eq $true) { break }
}
if ($smoadded -eq $false) { throw "Can't load SMO assemblies. You must have SQL Server Management Studio installed to proceed." }
$assemblies = "Management.Common", "Dmf", "Instapi", "SqlWmiManagement", "ConnectionInfo", "SmoExtended", "SqlTDiagM", "Management.Utility",
"SString", "Management.RegisteredServers", "Management.Sdk.Sfc", "SqlEnum", "RegSvrEnum", "WmiEnum", "ServiceBrokerEnum", "Management.XEvent",
"ConnectionInfoExtended", "Management.Collector", "Management.CollectorEnum", "Management.Dac", "Management.DacEnum", "Management.IntegrationServices"
foreach ($assembly in $assemblies)
{
    try
    {
        Add-Type -AssemblyName "Microsoft.SqlServer.$assembly, Version=$smoversion, Culture=neutral, PublicKeyToken=89845dcd8080cc91" -ErrorAction Stop
    }
    catch
    {
        # don't matter
    }
}

$SQLConnection = New-Object System.Data.SqlClient.SQLConnection
try 
    {

        $SQLConnection.ConnectionString = "Server = $InstanceName;Integrated Security = True;"
        Write-Host "Trying to connect to SQL Server instance on $InstanceName..." -NoNewline
        $SQLConnection.Open | Out-Null
        Write-Host -ForegroundColor Green "Success."
        $SQLConnection.Close();

        $server = new-object -TypeName "Microsoft.SqlServer.Management.Smo.Server" -ArgumentList $InstanceName;

        $scripter = new-object Microsoft.SQLServer.Management.SMO.Scripter $server;
        $scripter.Options.ScriptData = $true;
        $scripter.Options.Indexes = $true;
        
        $DB = $server.Databases[$Database]
        
        if (Test-Path -Path $FilePath)
        { Remove-Item $FilePath; }

        $tbl = $DB.Tables | Where-Object {($_.schema +'.' +$_.name) -in $Table}
        $scripter.EnumScriptWithList($tbl) | Out-File -FilePath $FilePath;
    }
catch 
    {
        Write-Host -BackgroundColor Red -ForegroundColor White "Fail"
        $ErrText = $Error[0].ToString()
        if ($ErrText.Contains("network-related"))
        {
            Write-Host "Connection error. Check the name of the instance."
        }
        Write-Host -BackgroundColor Red -ForegroundColor White $ErrText
    }

