---
document type: cmdlet
external help file: SqlServerConfiguration-Help.xml
HelpUri: ''
Locale: en-US
Module Name: SqlServerConfiguration
ms.date: 01/26/2026
PlatyPS schema version: 2024-05-01
title: Set-SqlDatabaseMailProfile
---

# Set-SqlDatabaseMailProfile

## SYNOPSIS

Modifies an existing Database Mail Profile on a SQL Server instance.

## SYNTAX

### ServerInstance (Default)

```
Set-SqlDatabaseMailProfile
  -ServerInstance <string>
  -MailProfileName <string>
  -NewMailProfileName <string>
  [-Description <string>]
  [<CommonParameters>]
```

### SmoServerObject

```
Set-SqlDatabaseMailProfile
  -SmoServerObject <Server>
  -MailProfileName <string>
  -NewMailProfileName <string>
  [-Description <string>]
  [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases:
  None

## DESCRIPTION

The Set-SqlDatabaseMailProfile cmdlet allows you to modify properties of an existing Database Mail Profile on a specified SQL Server instance.

## EXAMPLES

### Example 1

```powershell
Set-SqlDatabaseMailProfile -ServerInstance "MyServer" -MailProfileName "OldProfileName" -NewMailProfileName "NewProfileName" -Description "Updated description for the mail profile."
```

Sets the name and description of an existing SQL Database Mail profile on the specified server instance.

### Example 2

```powershell
$SmoServer = Connect-SmoServer -ServerInstance MyServer
Set-SqlDatabaseMailProfile -SmoServerObject $SmoServer -MailProfileName "OldProfileName" -NewMailProfileName "NewProfileName" -Description "Updated description for the mail profile."
```

Sets the name and description of an existing SQL Database Mail profile using the SmoServer session.

## PARAMETERS

### -Description

A new description for the Database Mail Profile.

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

The current name of the Database Mail Profile to be modified.

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

### -NewMailProfileName

The new name for the Database Mail Profile.

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

### Microsoft.SqlServer.Management.Smo.Mail.MailProfile



## NOTES



## RELATED LINKS

None

