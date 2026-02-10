---
document type: cmdlet
external help file: SqlServerConfiguration-Help.xml
HelpUri: ''
Locale: en-US
Module Name: SqlServerConfiguration
ms.date: 01/26/2026
PlatyPS schema version: 2024-05-01
title: Remove-SqlDatabaseMailProfilePrincipal
---

# Remove-SqlDatabaseMailProfilePrincipal

## SYNOPSIS

Removes a principal from a SQL Database Mail Profile.

## SYNTAX

### ServerInstance (Default)

```
Remove-SqlDatabaseMailProfilePrincipal
  -ServerInstance <string>
  -MailProfileName <string>
  [-PrincipalName <string>]
  [-WhatIf]
  [-Confirm]
  [<CommonParameters>]
```

### SmoServerObject

```
Remove-SqlDatabaseMailProfilePrincipal
  -SmoServerObject <Server>
  -MailProfileName <string>
  [-PrincipalName <string>]
  [-WhatIf]
  [-Confirm]
  [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases:
  None

## DESCRIPTION

Removes a principal from a SQL Database Mail Profile.

## EXAMPLES

### Example 1

```powershell
Remove-SqlDatabaseMailProfilePrincipal -ServerInstance "MyServer" -MailProfileName "SupportProfile" -PrincipalName "DBAGroup"
```

Removes the principal "DBAGroup" from the Database Mail profile "SupportProfile" on the SQL Server instance "MyServer".

### Example 2

```powershell
$SmoServer = Connect-SmoServer -ServerInstance MyServer
Remove-SqlDatabaseMailProfilePrincipal -SmoServerObject $SmoServer -MailProfileName "SupportProfile" -PrincipalName "DBAGroup"
```

Removes the principal "DBAGroup" from the Database Mail profile "SupportProfile" on the SQL Server instance using the SmoServer session.

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

### -MailProfileName

The name of the Database Mail Profile to remove the principal from.

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

The name of the principal to remove from the Database Mail Profile.

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

