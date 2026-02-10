---
document type: cmdlet
external help file: SqlServerConfiguration-Help.xml
HelpUri: ''
Locale: en-US
Module Name: SqlServerConfiguration
ms.date: 01/26/2026
PlatyPS schema version: 2024-05-01
title: Get-SqlDatabaseMailConfiguration
---

# Get-SqlDatabaseMailConfiguration

## SYNOPSIS

Retrieves SQL Database Mail Configuration values from a SQL Server instance.

## SYNTAX

### ServerInstance (Default)

```
Get-SqlDatabaseMailConfiguration
  -ServerInstance <string>
  [-MailConfigurationName <DatabaseMailConfiguration>]
  [<CommonParameters>]
```

### SmoServerObject

```
Get-SqlDatabaseMailConfiguration
  -SmoServerObject <Server>
  [-MailConfigurationName <DatabaseMailConfiguration>]
  [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases:
  None

## DESCRIPTION

This cmdlet connects to a specified SQL Server instance and retrieves the Database Mail Configuration values.
It can return all configuration values or a specific one based on the provided name.

## EXAMPLES

### Example 1

```powershell
Get-SqlDatabaseMailConfiguration -ServerInstance "MyServer"
```

Retrieves all Database Mail configuration values from the SQL Server instance "MyServer".

### Example 2

```powershell
$SmoServer = Connect-SmoServer -ServerInstance MyServer
Get-SqlDatabaseMailConfiguration -SmoServerObject $SmoServer
```

Retrieves all Database Mail configuration values sing the SmoServer session.

## PARAMETERS

### -MailConfigurationName

The name of the specific Database Mail Configuration value to retrieve.
If not provided, all configuration values will be returned.

```yaml
Type: DatabaseMailConfiguration
DefaultValue: ''
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

### SqlServerConfiguration.SqlDatabaseMailConfiguration



## NOTES



## RELATED LINKS

None

