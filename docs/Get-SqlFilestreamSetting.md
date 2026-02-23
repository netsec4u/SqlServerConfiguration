---
document type: cmdlet
external help file: SqlServerConfiguration-Help.xml
HelpUri: ''
Locale: en-US
Module Name: SqlServerConfiguration
ms.date: 02/13/2026
PlatyPS schema version: 2024-05-01
title: Get-SqlFilestreamSetting
---

# Get-SqlFilestreamSetting

## SYNOPSIS

Gets the FILESTREAM configuration settings of a SQL Server instance.

## SYNTAX

### ServerInstance (Default)

```
Get-SqlFilestreamSetting
  -ServerInstance <string>
  [<CommonParameters>]
```

### SmoServerObject

```
Get-SqlFilestreamSetting
  -SmoServerObject <Server>
  [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases:
  None

## DESCRIPTION

Returns the FILESTREAM configuration settings of a SQL Server instance, including the access level and share name.

## EXAMPLES

### Example 1

```powershell
Get-SqlFilestreamSetting -ServerInstance MyServer
```

Returns the FILESTREAM settings of the SQL Server instance named.

### Example 2

```powershell
$SmoServer = Connect-SmoServer -ServerInstance MyServer
Get-SqlFilestreamSetting -SmoServerObject $SmoServer
```

Returns the FILESTREAM settings of the SQL Server using SMO session.

## PARAMETERS

### -ServerInstance

SQL Server host name and instance name.

```yaml
Type: System.String
DefaultValue: ''
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
DefaultValue: ''
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

### SqlServerConfiguration.SqlFilestreamSettings



## NOTES



## RELATED LINKS



