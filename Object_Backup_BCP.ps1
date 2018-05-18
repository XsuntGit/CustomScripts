<#
.Synopsis
   Bulk Copy Query Data to CSV file
.DESCRIPTION
   Bulk Copy Data from a query against a SQL Server Database into a CSV file
.EXAMPLE
   bcp-data -ServerInstance localhost -Database mssqltips -Query "select * from dbo.MyTable -FilePath c:\temp\mytable.txt -Trim Y
.INPUTS
   None
    You cannot pipe objects into BCP-Data
.OUTPUTS
   No output
#>

Param
(
    # SQL Server Instance name with default to local servername
    [Parameter(Mandatory=$false)] [string]$ServerInstance,
    # Database name with default to 'master'
    [Parameter(Mandatory=$false)] [string] $Database,
    # Query, the query will return a result set
    [Parameter(Mandatory=$true)]  [String] $Query,
    # FilePath, the full path name
    [Parameter(Mandatory=$true)]  [String] $FilePath,
    # FieldTerminator, the separator between columns, default to "|"
    [Parameter(Mandatory=$false)]  [String] $FieldTerminator="|",
    # RowTerminator, the separator between rows, default to a new line "`r`n"
    [Parameter(Mandatory=$false)]  [String] $RowTerminator="`r`n",
    # QuoteMark, the quoting marks around columns, default to none
    [Parameter(Mandatory=$false)]  [String] $QuoteMark="",
    # NoHeader, a switch parameter to decide whether column header are included in the csv file, by default, there is always a header unless this switch parameter is present
    [Parameter(Mandatory=$false)]  [switch] $NoHeader,
    # Trim, decides whether to trim the column of string data type, N = no trim, Y=trim both left and right of the string, L=left trim, R=right trim
    [Parameter(Mandatory=$false)]  
    [ValidateSet('N', 'Y', 'L', 'R')] [String] $Trim='N'
)

#Requires -Version 3.0
add-type -AssemblyName "System.Data";

#we assume use windows authentication, otherwise, you need to provide User and PassWord for connection
$conn = new-object System.Data.SQLClient.SqlConnection ("server=$ServerInstance; database=$Database; trusted_connection=true"); 
$sqlcmd = New-Object System.Data.SqlClient.SqlCommand($query, $conn)
$conn.Open();

$dr = $sqlcmd.ExecuteReader();
$dt = New-Object System.Data.DataTable;
$dt.Load($dr);

$sw = new-object System.IO.StreamWriter($FilePath, $false);

#we first write the header

if (-not $NoHeader)
{    
    [string]$head=$dt.Columns.columnname -join $FieldTerminator;
    $sw.Write($head);
    $sw.write($RowTerminator);
}

foreach ( $r in $dt.rows)
{
    [string]$tf = $FieldTerminator;
    for ([int]$i=0; $i -lt $dt.Columns.count; $i++)
    {
        if ($i -eq $dt.Columns.count -1 ) #last column does not need to be followed by $FieldTerminator
        { [string]$tf='';}
        
        if ($r[$i] -ne [System.DBNull]::Value)
        {
            if ($r[$i].GetType().name -ne 'Boolean')
            {
                $col_val = $r[$i].ToString() ;
            }
            else
            {
                if($r[$i] -eq $true) {  $col_val= '1' } else {$col_val='0'}  
            }  
            $col_val = $QuoteMark + $(
                switch ($trim)
                {
                    'Y' { $col_val.Trim() }
                    'N' { $col_val }
                    'R' { $col_val.TrimEnd()}
                    'L' { $col_val.TrimStart()}
                }
            ) + $QuoteMark + $tf;
            $sw.Write($col_val);
        }
        else
        { $sw.Write($QuoteMark+$QuoteMark+$tf);}
    } #loop through columns

    $sw.Write($RowTerminator);

}#loop through rows

#clean up
$sw.Close();
$dr.Close();
