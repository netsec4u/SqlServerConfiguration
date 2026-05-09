---
document type: cmdlet
external help file: SqlServerConfiguration-Help.xml
HelpUri: https://github.com/netsec4u/SqlServerConfiguration/blob/main/docs/Get-SqlServerService.md
Locale: en-US
Module Name: SqlServerConfiguration
ms.date: 05/08/2026
PlatyPS schema version: 2024-05-01
title: Get-SqlServerService
---

# Get-SqlServerService

## SYNOPSIS

Retrieves SQL Server services and their properties.

## SYNTAX

### ServerInstance (Default)

```
Get-SqlServerService
  -ServerInstance <string>
  [-ServiceName <string>]
  [<CommonParameters>]
```

### SmoServerObject

```
Get-SqlServerService
  -SmoServerObject <Server>
  [-ServiceName <string>]
  [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases:
  None

## DESCRIPTION

This cmdlet connects to a specified SQL Server instance and retrieves information about its services, including their status and configuration.

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
Type: System.String
DefaultValue: None
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: ServerInstance
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -ServiceName

The name of the SQL Server instance to connect to.

```yaml
Type: System.String
DefaultValue: None
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -SmoServerObject

An existing SMO Server object representing the SQL Server instance.

```yaml
Type: Microsoft.SqlServer.Management.Smo.Server
DefaultValue: None
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: SmoServerObject
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable,
-InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable,
-ProgressAction, -Verbose, -WarningAction, and -WarningVariable. For more information, see
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### Microsoft.SqlServer.Management.Smo.Wmi.ServerProtocol



## NOTES




## RELATED LINKS

