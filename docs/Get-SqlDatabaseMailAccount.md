---
document type: cmdlet
external help file: SqlServerConfiguration-Help.xml
HelpUri: ''
Locale: en-US
Module Name: SqlServerConfiguration
ms.date: 01/26/2026
PlatyPS schema version: 2024-05-01
title: Get-SqlDatabaseMailAccount
---

# Get-SqlDatabaseMailAccount

## SYNOPSIS

Retrieves SQL Database Mail Accounts from a SQL Server instance.

## SYNTAX

### ServerInstance (Default)

```
Get-SqlDatabaseMailAccount
  -ServerInstance <string>
  [-MailAccountName <string>]
  [<CommonParameters>]
```

### SmoServerObject

```
Get-SqlDatabaseMailAccount
  -SmoServerObject <Server>
  [-MailAccountName <string>]
  [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases:
  None

## DESCRIPTION

Retrieves SQL Database Mail Accounts from a specified SQL Server instance or SMO Server object.
You can optionally filter the results by specifying a Mail Account Name.

## EXAMPLES

### Example 1

```powershell
Get-SqlDatabaseMailAccount -ServerInstance "MyServer" -MailAccountName "MyMailAccount"
```

Retrieves the specified Database Mail account from the SQL Server instance "MyServer".

### Example 2

```powershell
$SmoServer = Connect-SmoServer -ServerInstance MyServer
Get-SqlDatabaseMailAccount -SmoServerObject $SmoServer -MailAccountName "MyMailAccount"
```

Retrieves the specified Database Mail account from the SQL Server instance using the SmoServer session.

## PARAMETERS

### -MailAccountName

The name of the Mail Account to retrieve.
If not specified, all Mail Accounts will be returned.

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

### Microsoft.SqlServer.Management.Smo.Mail.MailAccount



## NOTES



## RELATED LINKS

None

