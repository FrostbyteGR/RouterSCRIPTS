# RouterSCRIPTS

## I. DESCRIPTION:

A collection of scripts for RouterBOARD devices

Copyright (c) 2019 Frostbyte <frostbytegr@gmail.com>

## II. CREDITS:

* Marisb @ MikroTik wiki - orignal file parser code
* pablo @ MikroTik forum - original FQDN resolver code
* hacki @ MikroTik forum - original DynDNS updater code

## III. FEATURES:

* Configuration is read from external file
* Supports N amount of default gateways
* Detailed error messages for easy troubleshooting
* Easy install and uninstall

## IV. AVAILABLE MODULES:

* **Provision:** This is the core module responsible for the configuration and initialization of all other modules in this set
* **Gateway Selector:** A module that simplifies on-demand load balancing or default gateway selection, for devicess handling multiple gateways
* **Failover:** A module for automatic default gateway swapping upon failure, for devices handling multiple gateways. Fully interoperable with the Gateway Selector module
* **DynDNS Updater:** A module that simplifies dynamic DNS service updates
* **FQDN Resolver:** A module that resolves fully qualified domain names to address lists
* **Live Streaming:** A module that toggles policy routing or traffic prioritization/shaping rules to assist with live streaming

**NOTE:** Firewall mangle rules pertaining to load balancing or live streaming are not included, as everyone's configuration and needs may differ

## V. EXAMPLE CONFIGURATION FILE:

[Gateways]  
WANNames=Vodafone,Verizon  
WANGateways=192.168.1.1,192.168.2.1  
WANGatewayPrefix=Default route  
BalancingRulePrefix=LDBLNCR  
  
[Failover]  
FailoverTarget=8.8.8.8  
FailoverThreshold=3  
FailoverInterval=5  
  
[DynDNS]  
DDNSService=NoIP  
DDNSInterval=3600  
DDNSUsername=username  
DDNSPassword=password  
DDNSHostname=hostname.no-ip.org  
  
[Livestream]  
LVStreamList=TWITCH  
LVStreamFQDN=live-ams.twitch.tv  
LVStreamRulePrefix=LVSTRM  

**This configuration is an example to familiarize you with the required format**  
**Please use the supplied dist.cfg in the actual files, when creating your own**  

## VI. EXPLANATION OF THE CONFIGURATION FILE

**WANNames:** Comma separated list of default gateway names. Cannot contain spaces or duplicate values  
**WANGateways:** Comma separated list of default gateway addresses, as defined in your routing table. Must contain the same amount of entries as WANNames. Cannot contain spaces or duplicate values  
**WANGatewayPrefix:** The comment prefix to use for identifying default gateway routes in the routing table  
**BalancingRulePrefix:** The comment prefix to use for identifying load balancing rules in the mangle table. Must be defined even if no load balancing rules are present  
**FailoverTarget:** The IP address used to determine gateway availability status (ping) during WAN availability checks  
**FailoverThreshold:** The number of consecutive times a gateway can fail the WAN availability checks, before getting flagged as non-operational  
**FailoverInterval:** The time (in seconds) between each WAN availability check, when automatic WAN availability checks are enabled  
**DDNSService:** The dynamic DNS service provider. Can be configured as NoIP or DynDNS only  
**DDNSInterval:** The time (in seconds) between each dynamic DNS service update attempt, when automatic dynamic DNS service updates are enabled. No update will be performed if WAN address hasn't changed  
**DDNSUsername:** The username for the dynamic DNS service  
**DDNSPassword:** The password (NoIP) or secret (DynDNS) for the dynamic DNS service  
**DDNSHostname:** The hostname for the dynamic DNS service  
**LVStreamList:** The firewall address list name to put the resolved live streaming service ingest server addresses under  
**LVStreamFQDN:** The fully qualified domain name of the live streaming service ingest servers  
**LVStreamRulePrefix:** The comment prefix to use for identifying live streaming rules in the mangle table  

## VII. RESTRICTIONS AND IMPORTANT NOTES:

* **Take regular backups of your device**, including one prior the installation of these scripts
* Everything (configuration filename, commands, command arguments and so forth) is **case sensitive**
* While there is no limit on how many gateways one can define, the maximum route distance of your default gateway routes **must not exceed** the number of gateways defined in the configuration file
  - For example, if we assume the above configuration: the default gateway routes must have a distance of 1 and 2 respectively. Gateways with distances higher than 2 will be considered non-operational by the scripts
* You can only have one gateway per subnet. Multiple gateways over the same bridge/master-interface are **not supported**
* Characters like braces, brackets and parentheses **must be avoided** on the prefix configuration values. Prefixes are used to locate comments and can be interpreted as regular expressions
* You, or any other script/scheduler installed on the device, **must not edit or remove** any of the variables and routes managed by these scripts
* Should you need to make any changes to your default routes and/or gateway subnets, please do the following, in order:
  - If currently active, toggle the failover module off
  - Proceed with making any changes that you desire
  - Update and re-upload your configuration file
  - Reprovision with: **$provision auto**
  - Toggle the failover module back on, if previously enabled

## VIII. INSTALLATION/UNINSTALLATION:

1. Upload the configuration file on the device, created with the restrictions mentioned above and the following guidelines in mind:
   - Configuration filename **must contain** the hostname of the device and **end with** a cfg extension (i.e. if MikroTik is the hostname then your configuration file should be MikroTik.cfg)
   - For each of the installed modules (residing in /system scripts) the configuration file **must contain** the corresponding section **fully populated**
   - If you wish to remove any module(s) during the installation, please also refer to sections **IX** and **X (points 3 and 4)** of this documentation
2. Upload the installation script on the device and execute:
   - **/import RouterSCRIPTS_Installer.rsc**
   - **$provision auto**
3. Upload the uninstallation script on the device and execute:
   - **/import RouterSCRIPTS_Uninstaller.rsc**

## IX. MODULE DEPENDENCIES:

The following contains a list of the modules which are required to be present and fully configured, for each module

**Provision:** none  
**Gateway Selector:** Provision  
**Failover:** Provision, Gateway Selector  
**DynDNS:** Provision  
**ResolveFQDN:** Provision  
**Livestream:** Provision, ResolveFQDN  

## X. UNINSTALLING SPECIFIC MODULES:

1. If you wish to uninstall a module that you have no use for, first and foremost **consult** the aforementioned dependency list
2. Then, you can remove the module(s) from /system scripts and run: **$provision purge**
3. The same can be done during the initial installation, by removing the module(s) before running **$provision auto**
4. For any module(s) not present in /system scripts the corresponding configuration section(s) may be omitted
5. You should always follow this procedure for module(s) removal, as any changes made to the device by modules that contain an interval setting, will be gracefully rolled back during the module(s) purge

## XI. USAGE/COMMANDS:

* $provision auto|purge|failover|gateways|dyndns|resolver|livestream
  - **auto:** automatically provisions/re-provisions every module found under /system scripts
  - **purge:** automatically deprovisions every module missing from /system scripts
  - **all others:** provision/re-provision the requested module
* $gateway \<switch Balancer|\<WAN Name>>|status
  - **switch:** switch to load balancing mode or to one of the gateways defined in the configuration
  - **status:** display the current default gateway, not necessarily the one you have selected (if non-operational due to failover)
  - For example, if we assume the above configuration, possible commands would be:  
  $gateway switch Balancer, $gateway switch Vodafone, $gateway switch Verison, $gateway status
* $failover check|toggle|status
  - **check:** trigger a manual WAN availability check (useful for troubleshooting)
  - **toggle:** enable or disable the automatic WAN availability checks
  - **status:** display detailed information about the operational status for each gateway and their approximate up/down time
* $dyndns update|toggle
  - **update:** trigger a manual dynamic DNS service update (if WAN address has changed)
  - **toggle:** enable or disable the automatic dynamic DNS service updates
* $resolvefqdn \<FQDN> \<Address List>
  - **\<FQDN>:** the fully qualified domain name to resolve
  - **\<Address List>:** the address list name to put all resulting addresses under
* $livestream toggle|status
  - **toggle:** enable or disable the live streaming module
  - **status:** display whether the live streaming module is active or not

## XII. REPORTING BUGS/REQUESTING FEATURES

If you want to report a behavior that the scripts shouldn't exhibit, or simply request a new feature:  
Please use [this thread over on the MikroTik forums](https://forum.mikrotik.com/viewtopic.php?f=9&t=143511)