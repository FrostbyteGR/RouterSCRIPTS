# RouterSCRIPTS Uninstaller
# Version 1.0.0

#Error handling functions
local notify do={local msg "[RouterSCRIPTS][Info]: $1";put $msg;log info $msg}
local execStatus 0

#Remove the scripts
foreach systemScript in={"mod-gateway";"mod-failover";"mod-dyndns";"mod-resolvefqdn";"mod-livestream"} do={
	/system script remove [find name=$systemScript]
}

#Deprovision the router
execute ("global provision;\$provision purge;set provision;global scriptsVersion;set scriptsVersion")

#Cleanup
/system script remove [find name="mod-provision"]
/system scheduler remove [find name="init-provision"]
/file remove [find name="RouterSCRIPTS_Uninstaller.rsc"]

#Notify
$notify ("Uninstall finished.")