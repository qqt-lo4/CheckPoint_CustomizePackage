# CheckPoint_CustomizePackage
A tool that can customize Check Point Endpoint Security packages

Since my new job (a few years ago), my company used to create pre-configured Endpoint Security packages with trac.config (an encrypted file that contains the VPN site config) included using AdminMode.bat.
Then we migrated to managed VPN clients by using SmartEndpoint (because of the firewall included)
Then we had to use vpnconfig (https://support.checkpoint.com/results/sk/sk122574) because we also edited trac.defaults file
But it was a difficult task to provide a new VPN client because of the steps amount:
-	Generate a package from SmartEndpoint
-	Install it (to generate trac.defaults new version)
-	Connect one time (to generate trac.config)
-	Change several settings in trac.defaults and get trac.config 
-	Use vpnconfig to create a new msi
-	Uninstall Endpoint Security 
-	Install the newly vpnconfig generated msi to verify everything works as expected.

The main goal of this script is to re-create a vpnconfig alternative that can automate all steps. Dynamic packages are also managed by this script (because since they upgraded the antimalware blade, now the MSI minimum size is 900MB...).
Dynamic packages are also minimized to remove useless things if like us you only use VPN and firewall.

More details here: [doc](DOC.md)

## Licence
CC-BY-NC-SA
