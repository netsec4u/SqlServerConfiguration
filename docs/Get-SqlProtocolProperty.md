---
external help file: SqlServerConfiguration-help.xml
Module Name: SqlServerConfiguration
online version:
schema: 2.0.0
---

# Get-SqlProtocolProperty

## SYNOPSIS
Gets SQL protocol properties.

## SYNTAX

### ServerInstance (Default)
```
Get-SqlProtocolProperty
	-ServerInstance <String>
	[<CommonParameters>]
```

### SmoServerObject
```
Get-SqlProtocolProperty
	-SmoServerObject <Server>
	[<CommonParameters>]
```

## DESCRIPTION
Gets SQL protocol properties.

## EXAMPLES

### Example 1
```powershell
Get-SqlProtocolProperty -ServerInstance MyServer
```

Gets SQL protocol properties for myServer.

### Example 2
```powershell
$SmoServer = Connect-SmoServer -ServerInstance MyServer

Get-SqlProtocolProperty -SmoServerObject $SmoServer
```

Gets SQL protocol properties using SMO server session.

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

### SqlServerConfiguration.SqlProtocolProperty

## NOTES

## RELATED LINKS
