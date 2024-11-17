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

| Folder                             | Details                                                                                                                                                                        |
| ---------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| client_configuration               | Contains settings to edit trac.defaults                                                                                                                                        |
| install_general_config             | Contains settings like registry tagging and log folder for installer                                                                                                           |
| install_steps_after                | This folder contains actions that will be ran after installation of EPS.msi                                                                                                    |
| install_steps_before               | This folder contains actions that will be ran before installation of EPS.msi                                                                                                   |
| package_customization_msi          | Allows to change SDL and Fixed MAC (similar to VPNconfig.exe). NoKeep is the override trac.config option                                                                       |
| package_customization_post_actions | Actions ran at the end of package generation. Can be used to copy items ran during installation or generate an EXE runner that will run Install-CheckPointEndpointSecurity.ps1 |
| site                               | Contains VPN sites that can be included inside packages                                                                                                                        |

# How it works
Because of the way packages are made, steps are not exactly the same but similar
First step: open a powershell window
Then run 
```
.\CheckPoint_CustomizePackage.ps1
```
When you open the script for the first time, you will only be able to add an external file :
![image](https://github.com/user-attachments/assets/5b4f0b81-10be-4278-ac9e-1b877cb81ca7)

Press Enter or “o” to select another file
Then enter the file path of an Endpoint package generated through SmartEndpoint (or the webui version), and press enter:
![image](https://github.com/user-attachments/assets/485a6494-76db-4ccc-ae20-492d7ed77108)

Double quotes are not mandatory. They are added when you copy a file path using “Ctrl” + “Shift” + “C” under Windows 11, so I added support for path with double quotes.

Next steps will depend on if you selected a MSI or an EXE file

## MSI
The script will guess a package folder name. The package will be VPN (if this is not a managed package) or EPS (if it’s a package generated by SmartEndpoint), the package version and the SmartEdpoint server name (if the package is managed by an Endpoint server):
![image](https://github.com/user-attachments/assets/04e2b4f9-c617-4441-860f-ea04a636a291)

You can press Y or N, or use arrows and press enter to validate
If you press N, you will be asked to type the output package folder name

Then you can copy the input file selected in a repository for future usage (for example if you need to generate different packages with the same MSI):
![image](https://github.com/user-attachments/assets/28a73707-78fc-4998-9f85-101a3c2dfc0e)

You can press Y or N, or use arrows and press enter to validate
If you press Y, package will be copied to the “input\CheckPoint_package” folder
You will see these lines during file copy:
```
Copy EPS.msi to repository - start
Copy EPS.msi to repository - end
```
Then you will need to choose which site you will put inside generated package:
![image](https://github.com/user-attachments/assets/a916e5a4-019e-431c-a323-135863bc9524)

Please use arrows to select the site, and press enter to validate. 
You will have a confirmation about the site you selected:
![image](https://github.com/user-attachments/assets/094b0921-0378-400e-b7a8-220eada986b7)

This step is used to select some configuration used during Endpoint Security installation. At my company we use SCCM to deploy things and wanted to tag the registry at the end of installation, and we also wanted to change the path where logs are generated during installation
![image](https://github.com/user-attachments/assets/b7d2f3dd-e4fc-4a82-a86a-4e3f0ae20233)

Please use arrows and Enter to select the configuration you want. Then it will be displayed:
![image](https://github.com/user-attachments/assets/0f2fada7-39f4-4006-9d2f-f1141b4ec80e)

Then you have to select steps that will be ran before executing the final MSI:
![image](https://github.com/user-attachments/assets/4e35f0e3-8efa-476b-bf46-af170c49ef48)

Please use arrows and Enter to select the configuration you want. Then it will be displayed:
![image](https://github.com/user-attachments/assets/e1066616-b78a-4119-af5c-0833bf995bd3)

Then you have to select step that will be ran after executing the MSI
![image](https://github.com/user-attachments/assets/7e3d0131-12c0-4a0e-ad06-88710d71200f)

Please use arrows and Enter to select the configuration you want. Then it will be displayed:
![image](https://github.com/user-attachments/assets/71f8b9ad-d61c-46dc-af29-bfef68256a0e)

Then please select a configuration file that contains trac.defaults properties you want to apply:
![image](https://github.com/user-attachments/assets/272ba0e8-48e8-44b0-ad45-6d9cd29cf165)

Please use arrows and Enter to select the configuration you want. Then it will be displayed:
![image](https://github.com/user-attachments/assets/84fbdca7-612d-44ed-b987-19c7c9a8d2c7)

The selected properties above can be integrated inside the MSI (the default version of trac.defaults will be extracted from the package, edited and put inside the new MSI), or can be set after installation (the service will be terminated after installation, file will be edited and the service will be restarted) :
![image](https://github.com/user-attachments/assets/d6c81021-ba7a-49ad-85cd-beb7a78bb983)

I recommend editing the MSI. Please enter Y or N, or user arrows and Enter to validate.

When you use vpnconfig, several settings were possible: SDL_Enabled and FIXED_MAC (and an option to disable OfficeMode but I don’t think anybody will want to disable OfficeMode). This is also the step where you can choose if you want to override the currently installed trac.config.  
![image](https://github.com/user-attachments/assets/08a18dc1-ad16-4f0d-952b-7b45143b5412)

Please use arrows and press Enter to select a configuration file.
The option you selected will be displayed:
![image](https://github.com/user-attachments/assets/e88c94d5-47fa-4de3-a837-9787cc99871f)

This step allows to run actions at the end of package generation. I use it to copy the VPN session opening script, an exe to reconnect to a management and generate a runner: 
![image](https://github.com/user-attachments/assets/14afa4fd-21af-4f76-8527-a7b6e6aab5a0)

Here is a documentation about how to create an EXE to reconnect to a management server:
https://sc1.checkpoint.com/documents/Infinity_Portal/WebAdminGuides/EN/Harmony-Endpoint-Admin-Guide/Topics-HEP/Reconnect-Tool.htm
What I call a runner is an EXE that can be used by users with admin rights to run the whole setup (by running the generated PS1). If you choose to do it (at the next step), the runner can also integrate the uninstall password (mandatory when you do upgrades).
Please use arrows and Enter to select an option. Then the option you selected will be displayed:
![image](https://github.com/user-attachments/assets/a91b6538-709f-4e56-9666-35a8c8eedf96)

Now you can integrate the uninstall password in the generated package. When you use a MSI, the password can only be integrated in the runner created (if the actions after package generation contains a task to create a runner):
![image](https://github.com/user-attachments/assets/90f89400-3ecc-437e-bd9d-e99ccdbdfb5d)

You can choose not to integrate password. You can add the password by using the command line if you don’t integrate in the runner.
Then the package will be generated:
```
Copy MSI
Customize MSI - Add trac.config
Customize MSI - Apply MSI Properties
Copy install
Copy config.json
Running package customization post-actions
Copy vpn connection script
Generate EXE script to run the PS1 file
Package customization end
```
