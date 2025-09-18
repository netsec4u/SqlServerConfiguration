---
document type: cmdlet
external help file: SqlServerConfiguration-help.xml
HelpUri: ''
Locale: en-US
Module Name: SqlServerConfiguration
ms.date: 07/29/2025
PlatyPS schema version: 2024-05-01
title: Get-SqlProtocolProperty
---

# Get-SqlProtocolProperty

## SYNOPSIS

Gets SQL protocol properties.

## SYNTAX

### ServerInstance (Default)

```
Get-SqlProtocolProperty
  -ServerInstance <string>
  [<CommonParameters>]
```

### SmoServerObject

```
Get-SqlProtocolProperty
  -SmoServerObject <Server>
  [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases:
  None

## DESCRIPTION

Gets SQL protocol properties.

## EXAMPLES

### Example 1

Get-SqlProtocolProperty -ServerInstance MyServer

Gets SQL protocol properties for myServer.

### Example 2

$SmoServer = Connect-SmoServer -ServerInstance MyServer

Get-SqlProtocolProperty -SmoServerObject $SmoServer

Gets SQL protocol properties using SMO server session.

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

### SqlServerConfiguration.SqlProtocolProperty



## NOTES




## RELATED LINKS

None.

