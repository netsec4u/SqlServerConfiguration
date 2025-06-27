---
external help file: SqlServerConfiguration-help.xml
Module Name: SqlServerConfiguration
online version:
schema: 2.0.0
---

# Get-SqlServerStartupParameter

## SYNOPSIS
Get SQL Server startup parameters.

## SYNTAX

### ServerInstance (Default)
```
Get-SqlServerStartupParameter
	-ServerInstance <String>
	[<CommonParameters>]
```

### SmoServerObject
```
Get-SqlServerStartupParameter
	-SmoServerObject <Server>
	[<CommonParameters>]
```

## DESCRIPTION
Get SQL Server startup parameters.

## EXAMPLES

### Example 1
```powershell
Get-SqlServerStartupParameter -ServerInstance MyServer
```

Gets SQL Server startup parameters from MyServer.

### Example 2
```powershell
$SmoServer = Connect-SmoServer -ServerInstance MyServer

Get-SqlServerStartupParameter -SmoServerObject $SmoServer
```

Gets SQL Server startup parameters using SMO server session.

## PARAMETERS

### -ServerInstance
SQL Server host name and instance name.

```yaml
Type: String
Parameter Sets: ServerInstance
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SmoServerObject
SMO Server object

```yaml
Type: Server
Parameter Sets: SmoServerObject
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None

## OUTPUTS

### SqlServerConfiguration.SqlStartupParameter

## NOTES
https://learn.microsoft.com/en-us/sql/database-engine/configure-windows/database-engine-service-startup-options?view=sql-server-ver16

## RELATED LINKS
