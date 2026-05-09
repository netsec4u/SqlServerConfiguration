---
document type: cmdlet
external help file: SqlServerConfiguration-Help.xml
HelpUri: https://github.com/netsec4u/SqlServerConfiguration/blob/main/docs/Get-SqlDatabaseMailProfileAccount.md
Locale: en-US
Module Name: SqlServerConfiguration
ms.date: 05/08/2026
PlatyPS schema version: 2024-05-01
title: Get-SqlDatabaseMailProfileAccount
---

# Get-SqlDatabaseMailProfileAccount

## SYNOPSIS

Retrieves Database Mail profile accounts from a SQL Server instance.

## SYNTAX

### ServerInstance (Default)

```
Get-SqlDatabaseMailProfileAccount
  -ServerInstance <string>
  -MailProfileName <string>
  [-AccountName <string>]
  [<CommonParameters>]
```

### SmoServerObject

```
Get-SqlDatabaseMailProfileAccount
  -SmoServerObject <Server>
  -MailProfileName <string>
  [-AccountName <string>]
  [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases:
  None

## DESCRIPTION

This cmdlet connects to a specified SQL Server instance and retrieves Database Mail profile accounts.
You can specify the server instance directly or provide an existing SMO Server object.
Additionally, you can filter the results by profile name and account name.

## EXAMPLES

### Example 1

```powershell
Get-SqlDatabaseMailProfileAccount -ServerInstance "MyServer" -MailProfileName "MyMailProfile"
```

Retrieves a specific Database Mail Profile Account from the specified SQL Server instance.

### Example 2

```powershell
$SmoServer = Connect-SmoServer -ServerInstance MyServer
Get-SqlDatabaseMailProfileAccount -SmoServerObject $SmoServer -MailProfileName "MyMailProfile"
```

Retrieves a specific Database Mail Profile Account using the SmoServer session.

## PARAMETERS

### -AccountName

The name of the Database Mail account to retrieve.

```yaml
Type: System.String
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

### -MailProfileName

The name of the Database Mail profile to filter the accounts.

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

### SqlServerConfiguration.SqlDatabaseMailProfileAccount



## NOTES



## RELATED LINKS

