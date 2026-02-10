---
document type: cmdlet
external help file: SqlServerConfiguration-Help.xml
HelpUri: ''
Locale: en-US
Module Name: SqlServerConfiguration
ms.date: 01/26/2026
PlatyPS schema version: 2024-05-01
title: Get-SqlDatabaseMailProfile
---

# Get-SqlDatabaseMailProfile

## SYNOPSIS

Retrieves Database Mail profiles from a SQL Server instance.

## SYNTAX

### ServerInstance (Default)

```
Get-SqlDatabaseMailProfile
  -ServerInstance <string>
  [-MailProfileName <string>]
  [<CommonParameters>]
```

### SmoServerObject

```
Get-SqlDatabaseMailProfile
  -SmoServerObject <Server>
  [-MailProfileName <string>]
  [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases:
  None

## DESCRIPTION

The Get-SqlDatabaseMailProfile cmdlet connects to a specified SQL Server instance and retrieves Database Mail profiles.
You can specify a particular profile by name or retrieve all profiles available on the server.

## EXAMPLES

### Example 1

```powershell
Get-SqlDatabaseMailProfile -ServerInstance "MyServer" -MailProfileName "DefaultProfile"
```

Retrieves the specified Database Mail profile from the SQL Server instance "MyServer".

### Example 2

```powershell
$SmoServer = Connect-SmoServer -ServerInstance MyServer
Get-SqlDatabaseMailProfile -SmoServerObject $SmoServer -MailProfileName "DefaultProfile"
```

Retrieves the specified Database Mail profile from the SQL Server using the SmoServer session.

## PARAMETERS

### -MailProfileName

The name of the Database Mail profile to retrieve. If not specified, all profiles will be returned

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

### Microsoft.SqlServer.Management.Smo.Mail.MailProfile



## NOTES



## RELATED LINKS

None

