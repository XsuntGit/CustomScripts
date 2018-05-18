# set "Option Explicit" to catch subtle errors 
param
(
    [string]$InstanceName = $(Throw "Parameter missing: -InstanceName InstanceName"),
    [string]$Database = $(Throw "Parameter missing: -Database Database"),
    [string[]]$Tables =  $(Throw "Parameter missing (list): -Tables Tables"),
    [string]$FilePath = $(Throw "Parameter missing: -FilePath FilePath"),
    [string]$FileName = $(Throw "Parameter missing: -FileName FileName")
)

set-psdebug -strict
# a list of tables with possible schema or database qualifications 
# Adventureworks used for this example
$ErrorActionPreference = "stop" # you can opt to stagger on, bleeding, if an error occurs
 
# Load SMO assembly, and if we're running SQL 2008 DLLs load the SMOExtended and SQLWMIManagement libraries
$v = [System.Reflection.Assembly]::LoadWithPartialName( 'Microsoft.SqlServer.SMO')
if ((($v.FullName.Split(','))[1].Split('='))[1].Split('.')[0] -ne '9')
    {
        [System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMOExtended') | Out-Null
    }
# Handle any errors that occur
Trap
    {
        # Handle the error
        $err = $_.Exception
        Write-Host $err.Message
        while( $err.InnerException ) 
            {
                $err = $err.InnerException
                Write-Host $err.Message
            }
        # End the script.
        break
    }
 
# Connect to the specified instance
$Server = new-object ('Microsoft.SqlServer.Management.Smo.Server') $InstanceName
 
# Create the Database root directory if it doesn't exist
$homedir = "$FilePath\"
if (!(Test-Path -path $homedir))
  {
    Try 
        {
            New-Item $homedir -type directory | out-null
        }  
    Catch [system.exception]
        {
            Write-Error "Error while creating '$homedir'  $_"
            return
        }  
  }

$scripter = new-object ('Microsoft.SqlServer.Management.Smo.Scripter') $Server
$scripter.Options.ScriptSchema = $False; #no we're not scripting the schema
$scripter.Options.ScriptData = $true; #but we're scripting the data
$scripter.Options.NoCommandTerminator = $true;
$scripter.Options.FileName = $homedir + $FileName #writing out the data to file
$scripter.Options.ToFileOnly = $true #who wants it on the screen?
$ServerUrn=$Server.Urn #we need this to construct our URNs.
 
$UrnsToScript = New-Object Microsoft.SqlServer.Management.Smo.UrnCollection
#so we just construct the URNs of the objects we want to script
$Table=@()
foreach ($tablepath in $Tables -split ',')
    {
        $Tuple = "" | Select-Object Database, Schema, Table
        $TableName=$tablepath.Trim() -split '.',0,'SimpleMatch'
        switch ($TableName.count)
        { 
            1 { $Tuple.database=$database; $Tuple.Schema='dbo'; $Tuple.Table=$tablename[0];  break}
            2 { $Tuple.database=$database; $Tuple.Schema=$tablename[0]; $Tuple.Table=$tablename[1];  break}
            3 { $Tuple.database=$tablename[0]; $Tuple.Schema=$tablename[1]; $Tuple.Table=$tablename[2];  break}
            default {throw 'too many dots in the tablename'}
        }
        $Table += $Tuple
    }
foreach ($tuple in $Table)
    {
        $Urn="$ServerUrn/Database[@Name='$($tuple.database)']/Table[@Name='$($tuple.table)' and @Schema='$($tuple.schema)']"; 
        $UrnsToScript.Add($Urn) 
    }

#script them
$scripter.EnumScript($UrnsToScript)
"Saved to $homedir"+$FileName+' successfully'
