# The beginning of this project

Since my new job (a few years ago), my company used to create pre-configured Endpoint Security packages with trac.config (an encrypted file that contains the VPN site config) included using AdminMode.bat.
Then we migrated to managed VPN clients by using SmartEndpoint (because of the firewall included)
Then we had to use vpnconfig (https://support.checkpoint.com/results/sk/sk122574) because we also edited trac.defaults file
But it was a difficult task to provide a new VPN client because of the steps amount:
-	Generate a package from SmartEndpoint
-	Install it (to generate trac.defaults new version)
-	Connect one time
-	Change several settings in trac.defaults and get trac.config 
-	Use vpnconfig to create a new msi
-	Uninstall Endpoint Security 
-	Install the newly vpnconfig generated msi to verify everything works as expected.

# First versions of the script I made
So at the beginning I created a script to automate trac.defaults edition after Endpoint Security installation (bacically I ran a powershell script that launched EPS.msi and modified trac.defaults after EPS.msi installation finished). 
This feature is still possible today, but I found a way to extract trac.defaults from the EC.cab included in the MSI, and I used autoit to automate the vpnconfig tool window.
Then I found that the embedded trac.config from a EPS.msi file generated through SmartEndpoint was not encrypted, but it did not contain the certificate fingerprint (so a popup appeared to accept the certificate). 
Then I found the perfect registry key:
HKLM:\Software\WOW6432Node\CheckPoint\accepted_cn
It contains all accepted certificates
I had everything ready to automate all what I was using inside vpnconfig.exe 

# Current version of the script
Packages generated using a MSI were huge for a VPN client and firewall. It was around 450MB. For an issue we had to try the newest version of Endpoint Security and I discovered only a MSI of 900MB, and all packages for previous versions were removed to only provide a 900MB MSI file.
This script also manages dynamic packages. 7zip is used to unpack the dynamic package, and used to recreate an EXE package
Antimalware signature is always included by packages generated through SmartEndpoint, even if there is no antivirus included, same for a CAB file used by FDE. The script asks if you want to keep these items, and remove them if you want. It allows generating a 100MB package including VPN and firewall.

# Folder/files structure
This project is composed of two scripts:
-	CheckPoint_CustomizePackage.ps1
-	Install-CheckPointEndpointSecurity.ps1
The first script is the one you wan to run. The second is copied automatically at the end of package generation, and you will use it to run setup on computers.
Here is the folder list:
| Folder  | Details                                         |
| ------- | ----------------------------------------------- |
| Input	  | Contains response files used by the script      |
| Sources | Will contain generated packets                  |
| Tools   | Contains 7-Zip                                  |
| UDF     | Contains generic functions used by the script   |

Let’s describe the most interesting folder, the “input” folder:
Folder	Details
client_configuration	Contains settings to edit trac.defaults
install_general_config	Contains settings like registry tagging and log folder for installer
install_steps_after	This folder contains actions that will be ran after installation of EPS.msi
install_steps_before	This folder contains actions that will be ran before installation of EPS.msi
package_customization_msi	Allows to change SDL and Fixed MAC (similar to VPNconfig.exe). NoKeep is the override trac.config option
package_customization_post_actions	Actions ran at the end of package generation. Can be used to copy items ran during installation or generate an EXE runner that will run Install-CheckPointEndpointSecurity.ps1 
site	Contains VPN sites that can be included inside packages
