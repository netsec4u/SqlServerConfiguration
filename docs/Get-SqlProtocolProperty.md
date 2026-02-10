---
document type: cmdlet
external help file: SqlServerConfiguration-Help.xml
HelpUri: ''
Locale: en-US
Module Name: SqlServerConfiguration
ms.date: 07/29/2025
PlatyPS schema version: 2024-05-01
title: Get-SqlProtocolProperty
---

# Get-SqlProtocolProperty

## SYNOPSIS

Retrieves the protocol properties for a SQL Server instance.

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

This cmdlet connects to a specified SQL Server instance and retrieves the protocol properties, such as TCP/IP, Named Pipes, and Shared Memory settings.

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

The name of the SQL Server instance to connect to.

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

### SqlServerConfiguration.SqlProtocolProperty



## NOTES




## RELATED LINKS

None.

