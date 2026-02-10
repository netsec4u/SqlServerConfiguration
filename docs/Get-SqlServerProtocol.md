---
document type: cmdlet
external help file: SqlServerConfiguration-Help.xml
HelpUri: ''
Locale: en-US
Module Name: SqlServerConfiguration
ms.date: 07/29/2025
PlatyPS schema version: 2024-05-01
title: Get-SqlServerProtocol
---

# Get-SqlServerProtocol

## SYNOPSIS

Retrieves the protocol settings for a SQL Server instance.

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

The Get-SqlServerProtocol cmdlet connects to a specified SQL Server instance and retrieves the protocol settings, such as TCP/IP, Named Pipes, and Shared Memory.
It returns a Microsoft.SqlServer.Management.Smo.Wmi.ServerProtocol object that contains information about the protocol configuration.

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

### Microsoft.SqlServer.Management.Smo.Wmi.ServerProtocol



## NOTES




## RELATED LINKS

None.

