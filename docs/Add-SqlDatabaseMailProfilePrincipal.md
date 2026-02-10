---
document type: cmdlet
external help file: SqlServerConfiguration-Help.xml
HelpUri: ''
Locale: en-US
Module Name: SqlServerConfiguration
ms.date: 01/26/2026
PlatyPS schema version: 2024-05-01
title: Add-SqlDatabaseMailProfilePrincipal
---

# Add-SqlDatabaseMailProfilePrincipal

## SYNOPSIS

Adds a principal to a Database Mail profile.

## SYNTAX

### ServerInstance (Default)

```
Add-SqlDatabaseMailProfilePrincipal
  -ServerInstance <string>
  -MailProfileName <string>
  -PrincipalName <string>
  [-DefaultProfile <bool>]
  [-WhatIf]
  [-Confirm]
  [<CommonParameters>]
```

### SmoServerObject

```
Add-SqlDatabaseMailProfilePrincipal
  -SmoServerObject <Server>
  -MailProfileName <string>
  -PrincipalName <string>
  [-DefaultProfile <bool>]
  [-WhatIf]
  [-Confirm]
  [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases:
  None

## DESCRIPTION

Adds a principal to a Database Mail profile.

## EXAMPLES

### Example 1

```powershell
Add-SqlDatabaseMailProfilePrincipal -ServerInstance 'MyServer' -MailProfileName 'MyProfile' -PrincipalName 'MyUser' -DefaultProfile $true
```

Adds the specified principal to the specified Database Mail profile and sets it as the default profile for that principal.

### Example 2

```powershell
$SmoServer = Connect-SmoServer -ServerInstance MyServer
Add-SqlDatabaseMailProfilePrincipal -SmoServerObject $SmoServer -MailProfileName 'MyProfile' -PrincipalName 'MyUser' -DefaultProfile $true
```

Adds the specified principal to the specified Database Mail profile and sets it as the default profile for that principal using the SmoServer session.

## PARAMETERS

### -Confirm

Prompts you for confirmation before running the cmdlet.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: ''
SupportsWildcards: false
Aliases:
- cf
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

### -DefaultProfile

Specifies whether the profile is the default profile for the principal.

```yaml
Type: System.Boolean
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

Specifies the Database Mail profile name.

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

Specifies the principal name to add.

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

### -WhatIf

Runs the command in a mode that only reports what would happen without performing the actions.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: ''
SupportsWildcards: false
Aliases:
- wi
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

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable,
-InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable,
-ProgressAction, -Verbose, -WarningAction, and -WarningVariable. For more information, see
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### System.Void



## NOTES



## RELATED LINKS

None

