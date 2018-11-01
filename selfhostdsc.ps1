Configuration SelfhostConfig {

	 param(
        [string]$ProfileShare
		)

	Import-DscResource -ModuleName 'PSDesiredStateConfiguration'

		$defaultProf = @(  @{path="HKLM:\TempDefault\Software\Microsoft\Office\16.0\common\Logging "; name="EnableLogging"; value = 1},
				@{path="HKLM:\TempDefault\Software\Microsoft\Office\16.0\common\OfficeInsider "; name="InsiderSlabBehavior"; value ="1"},
				@{path="HKLM:\TempDefault\software\policies\microsoft\office\16.0\outlook\cached mode"; name="enable"; value = 1},
				@{path="HKLM:\TempDefault\software\policies\microsoft\office\16.0\outlook\cached mode"; name="syncwindowsetting"; value=1})





	Node $AllNodes.Where.NodeName
	{



#FSLogix Keuys
		Registry ProfileEnable
		{
			Ensure      = "Present"
				Key         = "HKEY_LOCAL_MACHINE\SOFTWARE\FSLogix\Profiles"
				ValueName   = "Enabled"
				ValueData   = 1
		}
		Registry ProfileLocation
		{
			Ensure      = "Present"
				Key         = "HKEY_LOCAL_MACHINE\SOFTWARE\FSLogix\Profiles"
				ValueName   = "VHDLocations"
				ValueData   = $ProfileShare
		}
		Registry OfficeEnabled
		{
			Ensure      = "Present"
				Key         = "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\FSLogix\ODFC"
				ValueName   = "Enabled"
				ValueData   = 1
		}
		Registry OfficeLocation
		{
			Ensure      = "Present"
				Key         = "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\FSLogix\ODFC"
				ValueName   = "VHDLocations"
				ValueData   = $ProfileShare
		}



# 5k resolution
		Registry MaxMonitors
		{
			Ensure      = "Present"  # You can also set Ensure to "Absent"
				Key         = "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp"
				ValueName   = "MaxMonitors"
				ValueData   = 4
		}
		Registry MaxXResolution
		{
			Ensure      = "Present"  # You can also set Ensure to "Absent"
				Key         = "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp"
				ValueName   = "MaxXResolution"
				Hex         = $true
				ValueData   = "00001400"
		}
		Registry MaxYResolution
		{
			Ensure      = "Present"  # You can also set Ensure to "Absent"
				Key         = "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp"
				ValueName   = "MaxYResolution"
				Hex         = $true
				ValueData   = "00000b40"
		}
		Registry MaxMonitorsS
		{
			Ensure      = "Present"  # You can also set Ensure to "Absent"
				Key         = "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\rdp-sxs17713"
				ValueName   = "MaxMonitors"
				ValueData   = 4
		}
		Registry MaxXResolutionS
		{
			Ensure      = "Present"  # You can also set Ensure to "Absent"
				Key         = "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\rdp-sxs17713"
				ValueName   = "MaxXResolution"
				Hex         = $true
				ValueData   = "00001400"
		}
		Registry MaxYResolutionS
		{
			Ensure      = "Present"  # You can also set Ensure to "Absent"
				Key         = "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\rdp-sxs17713"
				ValueName   = "MaxYResolution"
				Hex         = $true
				ValueData   = "00000b40"
		}
# End of 5k Resolution

		`
			Group AddAdminGroups {
				GroupName        = 'administrators'
					Ensure           = 'Present'
					MembersToInclude = @('redmond\avdselfadmin','ntdev\avdselfadmin')
					MembersToExclude = 'redmond\selfhost'
			}


		Script OutlookCacheMode {

			SetScript = {
				reg load HKLM\TempDefault C:\Users\Default\NTUSER.DAT

					foreach ($a in $defaultProf)
					{

						if(Test-Path $a.path)
						{
							New-ItemProperty -Path $a.path -Name $a.name -Value $a.value -Force
						}
						else
						{
							New-Item -Path $a.path -Force
								New-ItemProperty -Path $a.path -Name $a.name -Value $a.value    
						}

					}

				Start-Sleep -Seconds 5

					reg unload HKLM\TempDefault
			}

			TestScript = {
				reg load HKLM\TempDefault C:\Users\Default\NTUSER.DAT

					$result = $true

					foreach ($a in $defaultProf)
					{

						if(!(Test-Path $a.path))
						{
							Write-Information -message '$($s.path) not found'
								$result = $false
						}
						else
						{

							$value = Get-ItemProperty -Path $a.path -Name $a.name  |Select-Object -ExpandProperty $a.name 
								if($value -ne $a.value)
								{ 
									Write-Information -message '$($s.path) has no compliant value $($a.name):$value'
																											  $result = $false
								}
								else
								{
									Write-Information -message 'Compliant:$($s.path) $($a.name):$value'
								}

						}

					}

				Start-Sleep -Seconds 5

					reg unload HKLM\TempDefault

					$result
			}

			GetScript = {@{Result="Ok"}}
		}

	}

}
