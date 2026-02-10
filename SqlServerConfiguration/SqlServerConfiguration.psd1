@{

# Script module or binary module file associated with this manifest.
RootModule = 'SqlServerConfiguration.psm1'

# Version number of this module.
ModuleVersion = '1.1.0.0'

# Supported PSEditions
CompatiblePSEditions = @('Core', 'Desktop')

# ID used to uniquely identify this module
GUID = 'dc09a6b5-033c-457a-995a-ea12efd8eb80'

# Author of this module
Author = 'Robert Eder'

# Company or vendor of this module
CompanyName = ''

# Copyright statement for this module
Copyright = '(c) 2025 Robert Eder. All rights reserved.'

# Description of the functionality provided by this module
Description = 'Module provides function to configure SQL Server.'

# Minimum version of the Windows PowerShell engine required by this module
PowerShellVersion = '5.1'

# Name of the Windows PowerShell host required by this module
# PowerShellHostName = ''

# Minimum version of the Windows PowerShell host required by this module
# PowerShellHostVersion = ''

# Minimum version of Microsoft .NET Framework required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# DotNetFrameworkVersion = ''

# Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# CLRVersion = ''

# Processor architecture (None, X86, Amd64) required by this module
# ProcessorArchitecture = ''

# Modules that must be imported into the global environment prior to importing this module
RequiredModules = @(
	@{ModuleName="SqlServerTools"; ModuleVersion="3.6.3.0"; GUID="0dbb8289-ae5b-4633-afc8-dfaf0acbe06c"}
)

# Assemblies that must be loaded prior to importing this module
# RequiredAssemblies = @()

# Script files (.ps1) that are run in the caller's environment prior to importing this module.
# ScriptsToProcess = @()

# Type files (.ps1xml) to be loaded when importing this module
TypesToProcess = @(
	'SqlServerConfiguration.Types.ps1xml'
)

# Format files (.ps1xml) to be loaded when importing this module
FormatsToProcess = @(
	'SqlServerConfiguration.Format.ps1xml'
)

# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
# NestedModules = @()

# Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
FunctionsToExport = @(
	'Add-SqlDatabaseMailAccount',
	'Add-SqlDatabaseMailProfileAccount',
	'Add-SqlDatabaseMailProfilePrincipal',
	'Add-SqlServerStartupParameter',
	'Connect-SmoWmiManagedComputer',
	'Disable-SqlDatabaseMail',
	'Disable-SqlServerProtocol',
	'Enable-SqlConnectionEncryption',
	'Enable-SqlDatabaseMail',
	'Enable-SqlServerProtocol',
	'Get-SqlDatabaseMailAccount',
	'Get-SqlDatabaseMailConfiguration',
	'Get-SqlDatabaseMailProfile',
	'Get-SqlDatabaseMailProfileAccount',
	'Get-SqlDatabaseMailProfilePrincipal',
	'Get-SqlServerProtocol',
	'Get-SqlProtocolProperty',
	'Get-SqlServerService',
	'Get-SqlServerStartupParameter',
	'New-SqlDatabaseMailProfile',
	'Remove-SqlDatabaseMailAccount',
	'Remove-SqlDatabaseMailProfile',
	'Remove-SqlDatabaseMailProfileAccount',
	'Remove-SqlDatabaseMailProfilePrincipal',
	'Remove-SqlServerStartupParameter',
	'Set-SqlDatabaseMailAccount',
	'Set-SqlDatabaseMailConfiguration',
	'Set-SqlDatabaseMailProfile',
	'Set-SqlProtocolProperty'
	'Set-SqlServerStartupParameter'
)

# Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
# CmdletsToExport = @()

# Variables to export from this module
# VariablesToExport = @()

# Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
# AliasesToExport = @()

# DSC resources to export from this module
# DscResourcesToExport = @()

# List of all modules packaged with this module
# ModuleList = @()

# List of all files packaged with this module
FileList = @(
	'SqlServerConfiguration.psm1',
	'SqlServerConfiguration.Format.ps1xml',
	'SqlServerConfiguration.Types.ps1xml'
)

# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{

	PSData = @{

		# Tags applied to this module. These help with module discovery in online galleries.
		Tags = @('SQLServerClient', 'Smo', 'SQLManagementObjects')

		# A URL to the license for this module.
		LicenseUri = 'https://raw.githubusercontent.com/netsec4u/SqlServerConfiguration/main/LICENSE'

		# A URL to the main website for this project.
		ProjectUri = 'https://github.com/netsec4u/SqlServerConfiguration'

		# A URL to an icon representing this module.
		# IconUri = ''

		# ReleaseNotes of this module
		ReleaseNotes = 'Release Notes
		Future Development
			* SQL Server Service Properties
				* Enable Filestream
				* Enable AlwaysOn ($WmiManagedComputer.Services.IsHadrEnabled)
				* Advanced Properties
			* Ability to configure network protocols.
		'

		# Prerelease string of this module
		# Prerelease = ''

		# Flag to indicate whether the module requires explicit user acceptance for install/update/save
		# RequireLicenseAcceptance = $true

		# External dependent modules of this module
		# ExternalModuleDependencies = @()
	} # End of PSData hashtable

} # End of PrivateData hashtable

# HelpInfo URI of this module
HelpInfoURI = 'https://github.com/netsec4u/SqlServerConfiguration/blob/main/docs/SqlServerConfiguration.md'

# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
# DefaultCommandPrefix = ''

}
