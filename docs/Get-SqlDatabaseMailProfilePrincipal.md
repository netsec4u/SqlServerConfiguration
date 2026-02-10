---
document type: cmdlet
external help file: SqlServerConfiguration-Help.xml
HelpUri: ''
Locale: en-US
Module Name: SqlServerConfiguration
ms.date: 01/26/2026
PlatyPS schema version: 2024-05-01
title: Get-SqlDatabaseMailProfilePrincipal
---

# Get-SqlDatabaseMailProfilePrincipal

## SYNOPSIS

Get the principals associated with a Database Mail profile.

## SYNTAX

### ServerInstance (Default)

```
Get-SqlDatabaseMailProfilePrincipal
  -ServerInstance <string>
  -MailProfileName <string>
  [-PrincipalName <string>]
  [<CommonParameters>]
```

### SmoServerObject

```
Get-SqlDatabaseMailProfilePrincipal
  -SmoServerObject <Server>
  -MailProfileName <string>
  [-PrincipalName <string>]
  [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases:
  None

## DESCRIPTION

Retrieves the principals (users or roles) that have access to a specified Database Mail profile on a SQL Server instance.

## EXAMPLES

### Example 1

```powershell
Get-SqlDatabaseMailProfilePrincipal -ServerInstance "MyServer" -MailProfileName "MyProfile"
```

Retrieves all principals for the specified Database Mail profile on the specified SQL Server instance.

### Example 2

```powershell
$SmoServer = Connect-SmoServer -ServerInstance MyServer
Get-SqlDatabaseMailProfilePrincipal -ServerInstance "MyServer" -MailProfileName "MyProfile"
```

Retrieves all principals for the specified Database Mail profile using the SmoServer session.

## PARAMETERS

### -MailProfileName

The name of the Database Mail profile for which to retrieve principals.

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

### -PrincipalName

The name of a specific principal to filter the results.
If not provided, all principals associated with the profile will be returned.

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

### SqlServerConfiguration.SqlDatabaseMailProfilePrincipal



## NOTES



## RELATED LINKS

None

