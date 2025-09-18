---
document type: cmdlet
external help file: SqlServerConfiguration-help.xml
HelpUri: ''
Locale: en-US
Module Name: SqlServerConfiguration
ms.date: 07/29/2025
PlatyPS schema version: 2024-05-01
title: Get-SqlServerProtocol
---

# Get-SqlServerProtocol

## SYNOPSIS

Gets SQL Server protocols.

## SYNTAX

### ServerInstance (Default)

```
Get-SqlServerProtocol
  -ServerInstance <string>
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

## ALIASES

This cmdlet has the following aliases:
  None

## DESCRIPTION

Gets SQL Server protocols.

## EXAMPLES

### Example 1

Get-SqlServerProtocol -ServerInstance MyServer

Gets the SQL server protocols from MyServer.

### Example 2

$SmoServer = Connect-SmoServer -ServerInstance MyServer

Get-SqlServerProtocol -SmoServerObject $SmoServer

Gets the SQL server protocols using SMO server session.

## PARAMETERS

### -Protocol

Specifies the SQL Server protocol.

```yaml
Type: ServerProtocols
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

### Microsoft.SqlServer.Management.Smo.Wmi.ServerProtocol



## NOTES




## RELATED LINKS

None.

