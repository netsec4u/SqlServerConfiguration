---
document type: cmdlet
external help file: SqlServerConfiguration-help.xml
HelpUri: ''
Locale: en-US
Module Name: SqlServerConfiguration
ms.date: 07/29/2025
PlatyPS schema version: 2024-05-01
title: Get-SqlServerStartupParameter
---

# Get-SqlServerStartupParameter

## SYNOPSIS

Get SQL Server startup parameters.

## SYNTAX

### ServerInstance (Default)

```
Get-SqlServerStartupParameter
  -ServerInstance <string>
  [<CommonParameters>]
```

### SmoServerObject

```
Get-SqlServerStartupParameter
  -SmoServerObject <Server>
  [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases:
  None

## DESCRIPTION

Get SQL Server startup parameters.

## EXAMPLES

### Example 1

Get-SqlServerStartupParameter -ServerInstance MyServer

Gets SQL Server startup parameters from MyServer.

### Example 2

$SmoServer = Connect-SmoServer -ServerInstance MyServer

Get-SqlServerStartupParameter -SmoServerObject $SmoServer

Gets SQL Server startup parameters using SMO server session.

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

### -SmoServerObject

SMO Server object

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

### SqlServerConfiguration.SqlStartupParameter



## NOTES

https://learn.microsoft.com/en-us/sql/database-engine/configure-windows/database-engine-service-startup-options?view=sql-server-ver16


## RELATED LINKS

None.

