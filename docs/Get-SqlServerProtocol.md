---
external help file: SqlServerConfiguration-help.xml
Module Name: SqlServerConfiguration
online version:
schema: 2.0.0
---

# Get-SqlServerProtocol

## SYNOPSIS
Gets SQL Server protocols.

## SYNTAX

### ServerInstance (Default)
```
Get-SqlServerProtocol
	-ServerInstance <String>
	[-Protocol <ServerProtocols>]
	[<CommonParameters>]
```

### SmoServerObject
```
Get-SqlServerProtocol
	-SmoServerObject <Server>
	[-Protocol <ServerProtocols>]
	[<CommonParameters>]
```

## DESCRIPTION
Gets SQL Server protocols.

## EXAMPLES

### Example 1
```powershell
Get-SqlServerProtocol -ServerInstance MyServer
```

Gets the SQL server protocols from MyServer.

### Example 2
```powershell
$SmoServer = Connect-SmoServer -ServerInstance MyServer

Get-SqlServerProtocol -SmoServerObject $SmoServer
```

Gets the SQL server protocols using SMO server session.

## PARAMETERS

### -Protocol
Specifies the SQL Server protocol.

```yaml
Type: ServerProtocols
Parameter Sets: (All)
Aliases:
Accepted values: Np, Sm, Tcp

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

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

### Microsoft.SqlServer.Management.Smo.Wmi.ServerProtocol

## NOTES

## RELATED LINKS
