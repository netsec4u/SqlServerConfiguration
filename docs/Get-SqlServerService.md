---
external help file: SqlServerConfiguration-help.xml
Module Name: SqlServerConfiguration
online version:
schema: 2.0.0
---

# Get-SqlServerService

## SYNOPSIS
Gets SQL Server Service.

## SYNTAX

### ServerInstance (Default)
```
Get-SqlServerService
	-ServerInstance <String>
	[-ServiceName <String>]
	[<CommonParameters>]
```

### SmoServerObject
```
Get-SqlServerService
	-SmoServerObject <Server>
	[-ServiceName <String>]
	[<CommonParameters>]
```

## DESCRIPTION
Gets SQL Server Service.

## EXAMPLES

### Example 1
```powershell
Get-SqlServerService -ServerInstance MyServer
```

Gets SQL Services from MyServer.

### Example 2
```powershell
$SmoServer = Connect-SmoServer -ServerInstance MyServer

Get-SqlServerService -SmoServerObject $SmoServer
```

Gets SQL Services using SMO Server session.

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

### -ServiceName
Specifies the service name.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
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

### Microsoft.SqlServer.Management.Smo.Wmi.ServerProtocol

## NOTES

## RELATED LINKS
