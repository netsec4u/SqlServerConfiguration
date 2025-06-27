---
external help file: SqlServerConfiguration-help.xml
Module Name: SqlServerConfiguration
online version:
schema: 2.0.0
---

# Set-SqlProtocolProperty

## SYNOPSIS
Sets SQL protocol property settings.

## SYNTAX

### ServerInstance (Default)
```
Set-SqlProtocolProperty
	-ServerInstance <String>
	[-CertificateThumbprint <Object>]
	[-RequireEncryption <Boolean>]
	[-RequireStrictEncryption <Boolean>]
	[-HideInstance <Boolean>]
	[-ExtendedProtection <Boolean>]
	[-ServiceRestart]
	[-WhatIf]
	[-Confirm]
	[<CommonParameters>]
```

### SmoServerObject
```
Set-SqlProtocolProperty
	-SmoServerObject <Server>
	[-CertificateThumbprint <Object>]
	[-RequireEncryption <Boolean>]
	[-RequireStrictEncryption <Boolean>]
	[-HideInstance <Boolean>]
	[-ExtendedProtection <Boolean>]
	[-ServiceRestart]
	[-WhatIf]
	[-Confirm]
	[<CommonParameters>]
```

## DESCRIPTION
Sets SQL protocol property settings.

## EXAMPLES

### Example 1
```powershell
Set-SqlProtocolProperty -ServerInstance MyServer -HideInstance $true
```

Sets protocol property HideInstance on server MyServer.

### Example 2
```powershell
$SmoServer = Connect-SmoServer -ServerInstance MyServer

Set-SqlProtocolProperty -SmoServerObject $SmoServer -HideInstance $true
```

Sets protocol property HideInstance using SMO session.

## PARAMETERS

### -CertificateThumbprint
Specifies certificate thumbprint.

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ExtendedProtection
Specifies to enable/disable extended protection.

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -HideInstance
Specifies to enable/disable hide instance.

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -RequireEncryption
Specifies enable/disable encryption requirement.

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -RequireStrictEncryption
Specifies enable/disable strict encryption requirement.

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ServerInstance
SQL Server host name and instance name.

```yaml
Type: String
Parameter Sets: ServerInstance
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ServiceRestart
Restart SQL Server service.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SmoServerObject
SMO Server object

```yaml
Type: Server
Parameter Sets: SmoServerObject
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Confirm
Prompts you for confirmation before running the cmdlet.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: cf

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -WhatIf
Shows what would happen if the cmdlet runs.
The cmdlet is not run.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: wi

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None

## OUTPUTS

### System.Void

## NOTES

## RELATED LINKS
