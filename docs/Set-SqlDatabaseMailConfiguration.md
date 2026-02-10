---
document type: cmdlet
external help file: SqlServerConfiguration-Help.xml
HelpUri: ''
Locale: en-US
Module Name: SqlServerConfiguration
ms.date: 01/26/2026
PlatyPS schema version: 2024-05-01
title: Set-SqlDatabaseMailConfiguration
---

# Set-SqlDatabaseMailConfiguration

## SYNOPSIS

Updates a SQL Database Mail Account configuration.

## SYNTAX

### ServerInstance (Default)

```
Set-SqlDatabaseMailConfiguration
  -ServerInstance <string>
  -MailConfigurationName <DatabaseMailConfiguration>
  -MailConfigurationValue <string>
  [<CommonParameters>]
```

### SmoServerObject

```
Set-SqlDatabaseMailConfiguration
  -SmoServerObject <Server>
  -MailConfigurationName <DatabaseMailConfiguration>
  -MailConfigurationValue <string>
  [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases:
  None

## DESCRIPTION

Updates a SQL Database Mail Account configuration on a specified SQL Server instance.

## EXAMPLES

### Example 1

```powershell
Set-SqlDatabaseMailConfiguration -ServerInstance "MyServer" -MailConfigurationName "MaxFileSize" -Value "10240"
```

Set the Database Mail configuration option MaxFileSize to 10240 KB on the specified SQL Server instance.

### Example 2

```powershell
$SmoServer = Connect-SmoServer -ServerInstance MyServer
Set-SqlDatabaseMailConfiguration -SmoServerObject $SmoServer -MailConfigurationName "MaxFileSize" -Value "10240"
```

Set the Database Mail configuration option MaxFileSize to 10240 KB using the SmoServer session.

## PARAMETERS

### -MailConfigurationName

Specifies the name of the Database Mail configuration to update.

```yaml
Type: DatabaseMailConfiguration
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -MailConfigurationValue

Specifies the new value for the Database Mail configuration.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: true
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



