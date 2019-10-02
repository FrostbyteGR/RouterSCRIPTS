# RouterSCRIPTS Installer
# Version 1.0.1

#Error handling functions
local notify do={local msg "[RouterSCRIPTS][Info]: $1";put $msg;log info $msg}
local execStatus 0

#Install the scripts
/system script add dont-require-permissions=no name=mod-provision policy=read,write source="#Provision module script\r\
    \n#Script permissions: read, write\r\
    \n#Script dependencies: none\r\
    \n\r\
    \n#Declare scripts version\r\
    \nglobal scriptsVersion \"1.0.1\"\r\
    \n\r\
    \n#If the scheduler entry for the initialization of the provision module doesn't exist\r\
    \nif ([/system scheduler find name=init-provision]=\"\") do={\r\
    \n\t#Add it\r\
    \n\t/system scheduler add name=init-provision start-time=startup on-event={delay 10;/system script run mod-provision;global provision;\$provision auto}\r\
    \n}\r\
    \n\r\
    \n#Provision function\r\
    \nglobal provision do={\r\
    \n\t#Configuration parser subfunction\r\
    \n\t#Inputs: <Config attribute>\r\
    \n\t#Output: <Config value>\r\
    \n\tlocal parseConfig do={\r\
    \n\t\t#Pull the configuration file contents\r\
    \n\t\tlocal cfgFileContent [/file get value-name=contents [find name~([/system identity get value-name=name].\".cfg\")]]\r\
    \n\r\
    \n\t\t#Detect and adjust the configuration EOL sequence\r\
    \n\t\tlocal cfgEOLSequence \"\\n\"\r\
    \n\t\tif ([typeof [find \$cfgFileContent \"\\r\\n\" 0]]=\"num\") do={set cfgEOLSequence \"\\r\\n\"}\r\
    \n\r\
    \n\t\t#Declare helper pointers\r\
    \n\t\tlocal cfgLineStart 0\r\
    \n\t\tlocal cfgLineEnd 0\r\
    \n\r\
    \n\t\t#Iterate through the configuration file contents\r\
    \n\t\tdo {\r\
    \n\t\t\t#Find out where the line ends\r\
    \n\t\t\tset cfgLineEnd [find \$cfgFileContent \$cfgEOLSequence \$cfgLineStart]\r\
    \n\r\
    \n\t\t\t#If an EOL sequence cannot be found\r\
    \n\t\t\tif ([typeof \$cfgLineEnd]!=\"num\") do={\r\
    \n\t\t\t\t#Adjust the line end to the end of contents\r\
    \n\t\t\t\tset cfgLineEnd [len \$cfgFileContent]\r\
    \n\t\t\t}\r\
    \n\r\
    \n\t\t\t#Fetch the line\r\
    \n\t\t\tlocal cfgLine [pick \$cfgFileContent \$cfgLineStart \$cfgLineEnd]\r\
    \n\r\
    \n\t\t\t#Pull the configuration attribute of the line\r\
    \n\t\t\tlocal cfgAttribute [pick \$cfgLine 0 [find \$cfgLine \"=\" 0]]\r\
    \n\r\
    \n\t\t\t#If the attribute matches the request\r\
    \n\t\t\tif (\$cfgAttribute=\$1) do={\r\
    \n\t\t\t\t#Initialize the configuration value\r\
    \n\t\t\t\tlocal cfgValue \"\"\r\
    \n\r\
    \n\t\t\t\t#If the value is populated\r\
    \n\t\t\t\tif ([find \$cfgLine \"=\" 0]!=[len \$cfgLine]) do={\r\
    \n\t\t\t\t\t#Set the configuration value\r\
    \n\t\t\t\t\tset cfgValue [pick \$cfgLine ([find \$cfgLine \"=\" 0]+1) [len \$cfgLine]]\r\
    \n\r\
    \n\t\t\t\t\t#If the value is a boolean, properly convert it\r\
    \n\t\t\t\t\tif (\$cfgValue=\"true\") do={set cfgValue true}\r\
    \n\t\t\t\t\tif (\$cfgValue=\"false\") do={set cfgValue false}\r\
    \n\t\t\t\t}\r\
    \n\r\
    \n\t\t\t\t#Return the requested configuration value\r\
    \n\t\t\t\treturn \$cfgValue\r\
    \n\t\t\t}\r\
    \n\r\
    \n\t\t\t#Advance to the next line\r\
    \n\t\t\tset cfgLineStart (\$cfgLineEnd+[len \$cfgEOLSequence])\r\
    \n\t\t} while (\$cfgLineStart<[len \$cfgFileContent])\r\
    \n\r\
    \n\t\t#If this part has been reached, it means that the requested attribute was not found\r\
    \n\t\t#Exit\r\
    \n\t\treturn \"\"\r\
    \n\t}\r\
    \n\r\
    \n\t#Non-empty variable validator subfunction\r\
    \n\t#Inputs: <Array of variable names> <Array of variable values>\r\
    \n\t#Output: <Exit code>\r\
    \n\tlocal validateVars do={\r\
    \n\t\t#Error handling functions\r\
    \n\t\tlocal error do={local msg \"[Provision][Error]: \$1\";put \$msg;log error \$msg;return -1}\r\
    \n\t\tlocal execStatus 0\r\
    \n\r\
    \n\t\t#Iterate through the requested variables\r\
    \n\t\tforeach varIndex,cfgVar in=\$1 do={\r\
    \n\t\t\t#If any of them are not specified or invalid\r\
    \n\t\t\tif ((\$2->\$varIndex)=\"\") do={\r\
    \n\t\t\t\t#Throw error and adjust execution status\r\
    \n\t\t\t\tset execStatus [\$error (\"The configuration variable \$cfgVar cannot be left empty or contain an invalid value.\")]\r\
    \n\t\t\t}\r\
    \n\t\t}\r\
    \n\r\
    \n\t\t#Exit\r\
    \n\t\treturn \$execStatus\r\
    \n\t}\r\
    \n\r\
    \n\t#Error handling functions\r\
    \n\tlocal notify do={local msg \"[Provision][Info]: \$1\";put \$msg;log info \$msg}\r\
    \n\tlocal error do={local msg \"[Provision][Error]: \$1\";put \$msg;log error \$msg;return -1}\r\
    \n\tlocal execStatus 0\r\
    \n\r\
    \n\t#If the configuration file does not exist\r\
    \n\tif ([/file find name~([/system identity get value-name=name].\".cfg\")]=\"\") do={\r\
    \n\t\t#Throw error and exit\r\
    \n\t\tset execStatus [\$error (\"Unable to locate the config file, please upload it to the router and try again.\")]\r\
    \n\t\treturn \$execStatus\r\
    \n\t}\r\
    \n\r\
    \n\t#If function was called with argument \"auto\"\r\
    \n\tif (\$1=\"auto\" && [typeof \$2]=\"nothing\") do={\r\
    \n\t\t#Notify\r\
    \n\t\t\$notify (\"Provisioning all available modules.\")\r\
    \n\r\
    \n\t\t#Gain function access\r\
    \n\t\tglobal provision\r\
    \n\r\
    \n\t\t#Iterate through the module inventory\r\
    \n\t\tlocal availCommands \"\"\r\
    \n\t\tlocal systemScripts {\"mod-gateway\";\"mod-failover\";\"mod-dyndns\";\"mod-resolvefqdn\";\"mod-livestream\"}\r\
    \n\t\tforeach cmdIndex,moduleName in={\"gateways\";\"failover\";\"dyndns\";\"resolver\";\"livestream\"} do={\r\
    \n\t\t\t#If any of the corresponding scripts are installed\r\
    \n\t\t\tif ([/system script find name=(\$systemScripts->\$cmdIndex)]!=\"\") do={\r\
    \n\t\t\t\t#Append their corresponding command to the provision commands string\r\
    \n\t\t\t\tset availCommands \"\$availCommands,\$moduleName\"\r\
    \n\t\t\t}\r\
    \n\t\t}\r\
    \n\r\
    \n\t\t#Iterate through the available commands\r\
    \n\t\tforeach command in=[toarray \$availCommands] do={\r\
    \n\t\t\t#Execute each command and if any error was encountered\r\
    \n\t\t\tif ([\$provision \$command]<0) do={\r\
    \n\t\t\t\t#Adjust the execution status\r\
    \n\t\t\t\tset execStatus -1\r\
    \n\t\t\t}\r\
    \n\t\t}\r\
    \n\r\
    \n\t\t#If any errors occured\r\
    \n\t\tif (\$execStatus<0) do={\r\
    \n\t\t\t#Throw error\r\
    \n\t\t\t\$error (\"Completed with errors.\")\r\
    \n\t\t} else {\r\
    \n\t\t\t#Notify success\r\
    \n\t\t\t\$notify (\"Completed successfully.\")\r\
    \n\t\t}\r\
    \n\r\
    \n\t\t#Exit\r\
    \n\t\treturn \$execStatus\r\
    \n\t}\r\
    \n\r\
    \n\t#If function was called with argument \"purge\"\r\
    \n\tif (\$1=\"purge\" && [typeof \$2]=\"nothing\") do={\r\
    \n\t\t#Notify\r\
    \n\t\t\$notify (\"Automatically purging provisioned configuration.\")\r\
    \n\r\
    \n\t\t#Construct an inventory of variable names belonging to each module\r\
    \n\t\tlocal varsLiveStream {\"livestream\";\"LVStreamList\";\"LVStreamFQDN\";\"LVStreamRulePrefix\"}\r\
    \n\t\tlocal varsResolver {\"resolvefqdn\"}\r\
    \n\t\tlocal varsDynDNS {\"dyndns\";\"WANAddress\";\"DDNSService\";\"DDNSInterval\";\"DDNSUsername\";\"DDNSPassword\";\"DDNSHostname\"}\r\
    \n\t\tlocal varsFailover {\"failover\";\"FailoverCounters\";\"FailoverTarget\";\"FailoverThreshold\";\"FailoverInterval\"}\r\
    \n\t\tlocal varsGateway {\"gateway\";\"WANNames\";\"WANGateways\";\"WANGatewayPrefix\";\"BalancingRulePrefix\"}\r\
    \n\t\tlocal moduleVars {\$varsLiveStream;\$varsResolver;\$varsDynDNS;\$varsFailover;\$varsGateway}\r\
    \n\r\
    \n\t\t#Iterate through the system scripts\r\
    \n\t\tforeach modIndex,systemScript in={\"mod-livestream\";\"mod-resolvefqdn\";\"mod-dyndns\";\"mod-failover\";\"mod-gateway\"} do={\r\
    \n\t\t\t#If any of them is not installed\r\
    \n\t\t\tif ([/system script find name=\$systemScript]=\"\") do={\r\
    \n\t\t\t\t#Iterate through its corresponding variables\r\
    \n\t\t\t\tforeach modVar in=(\$moduleVars->\$modIndex) do={\r\
    \n\t\t\t\t\t#If it's a function variable that possesses a cron job\r\
    \n\t\t\t\t\tforeach varWithCron in={\"dyndns\";\"failover\"} do={\r\
    \n\t\t\t\t\t\tif (\$modVar=\$varWithCron) do={\r\
    \n\t\t\t\t\t\t\t#If it's currently active\r\
    \n\t\t\t\t\t\t\tif ([/system scheduler find disabled=no name=\"cron-\$modVar\"]!=\"\") do={\r\
    \n\t\t\t\t\t\t\t\t#Disable it\r\
    \n\t\t\t\t\t\t\t\texecute (\"global \$modVar;\\\$\$modVar toggle\")\r\
    \n\r\
    \n\t\t\t\t\t\t\t\t#Allow enough time for any additional actions to complete\r\
    \n\t\t\t\t\t\t\t\tdelay 1\r\
    \n\t\t\t\t\t\t\t}\r\
    \n\r\
    \n\t\t\t\t\t\t\t#Remove it\r\
    \n\t\t\t\t\t\t\t/system scheduler remove [find name=\"cron-\$modVar\"]\r\
    \n\t\t\t\t\t\t}\r\
    \n\t\t\t\t\t}\r\
    \n\t\t\t\t\t\r\
    \n\t\t\t\t\t#Clear their corresponding variables\r\
    \n\t\t\t\t\texecute (\"global \".\$modVar.\"; set \".\$modVar)\r\
    \n\t\t\t\t}\r\
    \n\t\t\t}\r\
    \n\t\t}\r\
    \n\r\
    \n\t\t#Exit\r\
    \n\t\treturn \$execStatus\r\
    \n\t}\r\
    \n\r\
    \n\t#If function was called with argument \"gateways\"\r\
    \n\tif (\$1=\"gateways\" && [typeof \$2]=\"nothing\") do={\r\
    \n\t\t#Array duplicate checker subfunction\r\
    \n\t\t#Inputs: <Array of arrays>\r\
    \n\t\t#Output: <Duplicates flag>\r\
    \n\t\tlocal containsDuplicates do={\r\
    \n\t\t\t#Iterate through the requested arrays\r\
    \n\t\t\tforeach array in=\$1 do={\r\
    \n\t\t\t\t#Iterate through each array element\r\
    \n\t\t\t\tforeach primaryElement in=\$array do={\r\
    \n\t\t\t\t\t#Declare helper counter\r\
    \n\t\t\t\t\tlocal elementOccurences 0\r\
    \n\r\
    \n\t\t\t\t\t#Iterate through each array element a second time\r\
    \n\t\t\t\t\tforeach secondaryElement in=\$array do={\r\
    \n\t\t\t\t\t\t#If the element is found\r\
    \n\t\t\t\t\t\tif (\$primaryElement=\$secondaryElement) do={\r\
    \n\t\t\t\t\t\t\t#Adjust the helper counter\r\
    \n\t\t\t\t\t\t\tset elementOccurences (\$elementOccurences+1)\r\
    \n\t\t\t\t\t\t}\r\
    \n\t\t\t\t\t}\r\
    \n\r\
    \n\t\t\t\t\t#If an element has been found more than once\r\
    \n\t\t\t\t\tif (\$elementOccurences>1) do={\r\
    \n\t\t\t\t\t\t#Exit\r\
    \n\t\t\t\t\t\treturn true\r\
    \n\t\t\t\t\t}\r\
    \n\t\t\t\t}\r\
    \n\t\t\t}\r\
    \n\r\
    \n\t\t\t#Exit\r\
    \n\t\t\treturn false\r\
    \n\t\t}\r\
    \n\r\
    \n\t\t#Notify\r\
    \n\t\t\$notify (\"Provisioning \$1.\")\r\
    \n\r\
    \n\t\t#Request variables from config\r\
    \n\t\tglobal WANNames [toarray [\$parseConfig \"WANNames\"]]\r\
    \n\t\tglobal WANGateways [toarray [\$parseConfig \"WANGateways\"]]\r\
    \n\t\tglobal WANGatewayPrefix [\$parseConfig \"WANGatewayPrefix\"]\r\
    \n\t\tglobal BalancingRulePrefix [\$parseConfig \"BalancingRulePrefix\"]\r\
    \n\r\
    \n\t\t#Validate that the mandatory variables are not empty\r\
    \n\t\tlocal cfgMandatoryVars {\"WANNames\";\"WANGateways\";\"WANGatewayPrefix\";\"BalancingRulePrefix\"}\r\
    \n\t\tlocal cfgMandatoryValues {\$WANNames;\$WANGateways;\$WANGatewayPrefix;\$BalancingRulePrefix}\r\
    \n\t\tset execStatus [\$validateVars \$cfgMandatoryVars \$cfgMandatoryValues]\r\
    \n\r\
    \n\t\t#If the WAN names or gateways contain duplicate values\r\
    \n\t\tlocal arrays {\$WANNames;\$WANGateways}\r\
    \n\t\tif ([\$containsDuplicates \$arrays]) do={\r\
    \n\t\t\t#Throw error and adjust execution status\r\
    \n\t\t\tset execStatus [\$error (\"Gateways configuration contains duplicate values.\")]\r\
    \n\t\t}\r\
    \n\r\
    \n\t\t#If the WAN name and gateway pairings are even\r\
    \n\t\tif ([len \$WANNames]=[len \$WANGateways]) do={\r\
    \n\t\t\t#Iterate through the gateways\r\
    \n\t\t\tforeach wanIndex,WANName in=\$WANNames do={\r\
    \n\t\t\t\t#If it's assigned with a proper IP\r\
    \n\t\t\t\tif ([typeof [toip (\$WANGateways->\$wanIndex)]]=\"ip\") do={\r\
    \n\t\t\t\t\t#If it does not have a corresponding default route\r\
    \n\t\t\t\t\tif ([/ip route find gateway=(\$WANGateways->\$wanIndex) dst-address=0.0.0.0/0 comment~\$WANGatewayPrefix]=\"\") do={\r\
    \n\t\t\t\t\t\t#Throw error and adjust execution status\r\
    \n\t\t\t\t\t\tset execStatus [\$error (\"Gateways configuration for \$WANName does not have a corresponding default route.\")]\r\
    \n\t\t\t\t\t}\r\
    \n\t\t\t\t} else {\r\
    \n\t\t\t\t\t#Throw error and adjust execution status\r\
    \n\t\t\t\t\tset execStatus [\$error (\"Gateways configuration for \$WANName contains an invalid IP address: \".(\$WANGateways->\$wanIndex).\".\")]\r\
    \n\t\t\t\t}\r\
    \n\t\t\t}\r\
    \n\t\t} else {\r\
    \n\t\t\t#Throw error and adjust execution status\r\
    \n\t\t\tset execStatus [\$error (\"Gateways configuration is incomplete. Declared items are not evenly populated or may be enclosed in quotes.\")]\r\
    \n\t\t}\r\
    \n\r\
    \n\t\t#If any errors occured\r\
    \n\t\tif (\$execStatus<0) do={\r\
    \n\t\t\t#Gain variable access\r\
    \n\t\t\tglobal gateway\r\
    \n\r\
    \n\t\t\t#Clear all corresponding variables\r\
    \n\t\t\tset gateway\r\
    \n\t\t\tset WANNames\r\
    \n\t\t\tset WANGateways\r\
    \n\t\t\tset WANGatewayPrefix\r\
    \n\t\t\tset BalancingRulePrefix\r\
    \n\r\
    \n\t\t\t#Throw error and adjust execution status\r\
    \n\t\t\tset execStatus [\$error (\"The \$1 configuration is invalid, please check the config file and try again.\")]\r\
    \n\t\t} else {\r\
    \n\t\t\t#If the function script is not installed\r\
    \n\t\t\tif ([/system script find name=mod-gateway]=\"\") do={\r\
    \n\t\t\t\t#Throw error and adjust execution status\r\
    \n\t\t\t\tset execStatus [\$error (\"The gateway selector module script is missing, please install it and try again.\")]\r\
    \n\t\t\t} else {\r\
    \n\t\t\t\t#Initialize function\r\
    \n\t\t\t\t/system script run mod-gateway\r\
    \n\t\t\t}\r\
    \n\t\t}\r\
    \n\r\
    \n\t\t#Exit\r\
    \n\t\treturn \$execStatus\r\
    \n\t}\r\
    \n\r\
    \n\t#If function was called with argument \"failover\"\r\
    \n\tif (\$1=\"failover\" && [typeof \$2]=\"nothing\") do={\r\
    \n\t\t#Notify\r\
    \n\t\t\$notify (\"Provisioning \$1.\")\r\
    \n\r\
    \n\t\t#Request variables from config\r\
    \n\t\tglobal FailoverTarget [toip [\$parseConfig \"FailoverTarget\"]]\r\
    \n\t\tglobal FailoverThreshold [tonum [\$parseConfig \"FailoverThreshold\"]]\r\
    \n\t\tglobal FailoverInterval [tonum [\$parseConfig \"FailoverInterval\"]]\r\
    \n\r\
    \n\t\t#Validate that the mandatory variables are not empty\r\
    \n\t\tlocal cfgMandatoryVars {\"FailoverTarget\";\"FailoverThreshold\";\"FailoverInterval\"}\r\
    \n\t\tlocal cfgMandatoryValues {\$FailoverTarget;\$FailoverThreshold;\$FailoverInterval}\r\
    \n\t\tset execStatus [\$validateVars \$cfgMandatoryVars \$cfgMandatoryValues]\r\
    \n\r\
    \n\t\t#If any errors occured\r\
    \n\t\tif (\$execStatus<0) do={\r\
    \n\t\t\t#Gain variable access\r\
    \n\t\t\tglobal failover\r\
    \n\r\
    \n\t\t\t#Clear all corresponding variables\r\
    \n\t\t\tset failover\r\
    \n\t\t\tset FailoverTarget\r\
    \n\t\t\tset FailoverThreshold\r\
    \n\t\t\tset FailoverInterval\r\
    \n\r\
    \n\t\t\t#Throw error and adjust execution status\r\
    \n\t\t\tset execStatus [\$error (\"The \$1 configuration is invalid, please check the config file and try again.\")]\r\
    \n\t\t} else {\r\
    \n\t\t\t#If the function script is not installed\r\
    \n\t\t\tif ([/system script find name=mod-failover]=\"\") do={\r\
    \n\t\t\t\t#Throw error and adjust execution status\r\
    \n\t\t\t\tset execStatus [\$error (\"The failover module script is missing, please install it and try again.\")]\r\
    \n\t\t\t} else {\r\
    \n\t\t\t\t#Gain variable access\r\
    \n\t\t\t\tglobal gateway\r\
    \n\r\
    \n\t\t\t\t#If the gateway function is not present\r\
    \n\t\t\t\tif ([typeof \$gateway]=\"nothing\") do={\r\
    \n\t\t\t\t\t#Throw error and adjust execution status\r\
    \n\t\t\t\t\tset execStatus [\$error (\"The failover module depends on the gateway selector module, please provision it and try again.\")]\r\
    \n\t\t\t\t} else {\r\
    \n\t\t\t\t\t#Gain variable access\r\
    \n\t\t\t\t\tglobal WANNames\r\
    \n\r\
    \n\t\t\t\t\t#Initialize the failover counters string\r\
    \n\t\t\t\t\tglobal FailoverCounters \"\"\r\
    \n\r\
    \n\t\t\t\t\t#For every gateway\r\
    \n\t\t\t\t\tforeach WANName in=\$WANNames do={\r\
    \n\t\t\t\t\t\t#Append an initialization value to it\r\
    \n\t\t\t\t\t\tset FailoverCounters \"\$FailoverCounters,0\"\r\
    \n\t\t\t\t\t}\r\
    \n\r\
    \n\t\t\t\t\t#Convert the failover counters string to an array\r\
    \n\t\t\t\t\tset FailoverCounters [toarray \$FailoverCounters]\r\
    \n\r\
    \n\t\t\t\t\t#Declare helper flag\r\
    \n\t\t\t\t\tlocal cronStatus true\r\
    \n\r\
    \n\t\t\t\t\t#If the scheduler entry for the periodic failover checks exists\r\
    \n\t\t\t\t\tif ([/system scheduler find name=cron-failover]!=\"\") do={\r\
    \n\t\t\t\t\t\t#Fetch its status\r\
    \n\t\t\t\t\t\tset cronStatus [/system scheduler get value-name=disabled [find name=cron-failover]]\r\
    \n\r\
    \n\t\t\t\t\t\t#Remove it\r\
    \n\t\t\t\t\t\t/system scheduler remove [find name=\"cron-failover\"]\r\
    \n\t\t\t\t\t}\r\
    \n\r\
    \n\t\t\t\t\t#Re-add the scheduler entry\r\
    \n\t\t\t\t\t/system scheduler add name=\"cron-failover\" interval=\$FailoverInterval policy=read,write,policy,test disabled=\$cronStatus on-event={global failover;\$failover check}\r\
    \n\r\
    \n\t\t\t\t\t#Initialize function\r\
    \n\t\t\t\t\t/system script run mod-failover\r\
    \n\t\t\t\t}\r\
    \n\t\t\t}\r\
    \n\t\t}\r\
    \n\r\
    \n\t\t#Exit\r\
    \n\t\treturn \$execStatus\r\
    \n\t}\r\
    \n\r\
    \n\t#If function was called with argument \"dyndns\"\r\
    \n\tif (\$1=\"dyndns\" && [typeof \$2]=\"nothing\") do={\r\
    \n\t\t#Notify\r\
    \n\t\t\$notify (\"Provisioning \$1.\")\r\
    \n\r\
    \n\t\t#Request variables from config\r\
    \n\t\tglobal DDNSService [\$parseConfig \"DDNSService\"]\r\
    \n\t\tglobal DDNSInterval [tonum [\$parseConfig \"DDNSInterval\"]]\r\
    \n\t\tglobal DDNSUsername [\$parseConfig \"DDNSUsername\"]\r\
    \n\t\tglobal DDNSPassword [\$parseConfig \"DDNSPassword\"]\r\
    \n\t\tglobal DDNSHostname [\$parseConfig \"DDNSHostname\"]\r\
    \n\r\
    \n\t\t#Validate that the mandatory variables are not empty\r\
    \n\t\tlocal cfgMandatoryVars {\"DDNSService\";\"DDNSInterval\";\"DDNSUsername\";\"DDNSPassword\";\"DDNSHostname\"}\r\
    \n\t\tlocal cfgMandatoryValues {\$DDNSService;\$DDNSInterval;\$DDNSUsername;\$DDNSPassword;\$DDNSHostname}\r\
    \n\t\tset execStatus [\$validateVars \$cfgMandatoryVars \$cfgMandatoryValues]\r\
    \n\r\
    \n\t\t#If any errors occured\r\
    \n\t\tif (\$execStatus<0) do={\r\
    \n\t\t\t#Gain variable access\r\
    \n\t\t\tglobal dyndns\r\
    \n\r\
    \n\t\t\t#Clear all corresponding variables\r\
    \n\t\t\tset dyndns\r\
    \n\t\t\tset DDNSService\r\
    \n\t\t\tset DDNSInterval\r\
    \n\t\t\tset DDNSUsername\r\
    \n\t\t\tset DDNSPassword\r\
    \n\t\t\tset DDNSHostname\r\
    \n\r\
    \n\t\t\t#Throw error and adjust execution status\r\
    \n\t\t\tset execStatus [\$error (\"The \$1 configuration is invalid, please check the config file and try again.\")]\r\
    \n\t\t} else {\r\
    \n\t\t\t#If the function script is not installed\r\
    \n\t\t\tif ([/system script find name=mod-dyndns]=\"\") do={\r\
    \n\t\t\t\t#Throw error and adjust execution status\r\
    \n\t\t\t\tset execStatus [\$error (\"The DynDNS updater module script is missing, please install it and try again.\")]\r\
    \n\t\t\t} else {\r\
    \n\t\t\t\t#Declare helper flag\r\
    \n\t\t\t\tlocal cronStatus true\r\
    \n\r\
    \n\t\t\t\t#If the scheduler entry for the periodic DynDNS updates exists\r\
    \n\t\t\t\tif ([/system scheduler find name=cron-dyndns]!=\"\") do={\r\
    \n\t\t\t\t\t#Fetch its status\r\
    \n\t\t\t\t\tset cronStatus [/system scheduler get value-name=disabled [find name=cron-dyndns]]\r\
    \n\r\
    \n\t\t\t\t\t#Remove it\r\
    \n\t\t\t\t\t/system scheduler remove [find name=\"cron-dyndns\"]\r\
    \n\t\t\t\t}\r\
    \n\r\
    \n\t\t\t\t#Re-add the scheduler entry\r\
    \n\t\t\t\t/system scheduler add name=\"cron-dyndns\" interval=\$DDNSInterval disabled=\$cronStatus on-event={global dyndns;\$dyndns update}\r\
    \n\r\
    \n\t\t\t\t#Initialize function\r\
    \n\t\t\t\t/system script run mod-dyndns\r\
    \n\t\t\t}\r\
    \n\t\t}\r\
    \n\r\
    \n\t\t#Exit\r\
    \n\t\treturn \$execStatus\r\
    \n\t}\r\
    \n\r\
    \n\t#If function was called with argument \"resolver\"\r\
    \n\tif (\$1=\"resolver\" && [typeof \$2]=\"nothing\") do={\r\
    \n\t\t#Notify\r\
    \n\t\t\$notify (\"Provisioning \$1.\")\r\
    \n\r\
    \n\t\t#If the function script is not installed\r\
    \n\t\tif ([/system script find name=mod-resolvefqdn]=\"\") do={\r\
    \n\t\t\t#Throw error and adjust execution status\r\
    \n\t\t\tset execStatus [\$error (\"The FQDN resolver module script is missing, please install it and try again.\")]\r\
    \n\t\t} else {\r\
    \n\t\t\t#Initialize function\r\
    \n\t\t\t/system script run mod-resolvefqdn\r\
    \n\t\t}\r\
    \n\r\
    \n\t\t#Exit\r\
    \n\t\treturn \$execStatus\r\
    \n\t}\r\
    \n\r\
    \n\t#If function was called with argument \"livestream\"\r\
    \n\tif (\$1=\"livestream\" && [typeof \$2]=\"nothing\") do={\r\
    \n\t\t#Notify\r\
    \n\t\t\$notify (\"Provisioning \$1.\")\r\
    \n\r\
    \n\t\t#Request variables from config\r\
    \n\t\tglobal LVStreamList [\$parseConfig \"LVStreamList\"]\r\
    \n\t\tglobal LVStreamFQDN [\$parseConfig \"LVStreamFQDN\"]\r\
    \n\t\tglobal LVStreamRulePrefix [\$parseConfig \"LVStreamRulePrefix\"]\r\
    \n\r\
    \n\t\t#Validate that the mandatory variables are not empty\r\
    \n\t\tlocal cfgMandatoryVars {\"LVStreamList\";\"LVStreamFQDN\";\"LVStreamRulePrefix\"}\r\
    \n\t\tlocal cfgMandatoryValues {\$LVStreamList;\$LVStreamFQDN;\$LVStreamRulePrefix}\r\
    \n\t\tset execStatus [\$validateVars \$cfgMandatoryVars \$cfgMandatoryValues]\r\
    \n\r\
    \n\t\t#If any errors occured\r\
    \n\t\tif (\$execStatus<0) do={\r\
    \n\t\t\t#Gain variable access\r\
    \n\t\t\tglobal livestream\r\
    \n\r\
    \n\t\t\t#Clear all corresponding variables\r\
    \n\t\t\tset livestream\r\
    \n\t\t\tset LVStreamList\r\
    \n\t\t\tset LVStreamFQDN\r\
    \n\t\t\tset LVStreamRulePrefix\r\
    \n\r\
    \n\t\t\t#Throw error and adjust execution status\r\
    \n\t\t\tset execStatus [\$error (\"The \$1 configuration is invalid, please check the config file and try again.\")]\r\
    \n\t\t} else {\r\
    \n\t\t\t#If the function script is not installed\r\
    \n\t\t\tif ([/system script find name=mod-livestream]=\"\") do={\r\
    \n\t\t\t\t#Throw error and adjust execution status\r\
    \n\t\t\t\tset execStatus [\$error (\"The live streaming module script is missing, please install it and try again.\")]\r\
    \n\t\t\t} else {\r\
    \n\t\t\t\t#Gain variable access\r\
    \n\t\t\t\tglobal resolvefqdn\r\
    \n\r\
    \n\t\t\t\t#If the resolvefqdn function is not present\r\
    \n\t\t\t\tif ([typeof \$resolvefqdn]=\"nothing\") do={\r\
    \n\t\t\t\t\t#Throw error and adjust execution status\r\
    \n\t\t\t\t\tset execStatus [\$error (\"The live streaming module depends on the FQDN resolver module, please provision it and try again.\")]\r\
    \n\t\t\t\t} else {\r\
    \n\t\t\t\t\t#Initialize function\r\
    \n\t\t\t\t\t/system script run mod-livestream\r\
    \n\t\t\t\t}\r\
    \n\t\t\t}\r\
    \n\t\t}\r\
    \n\r\
    \n\t\t#Exit\r\
    \n\t\treturn \$execStatus\r\
    \n\t}\r\
    \n\r\
    \n\t#If this part has been reached, it means that no valid arguments were caught\r\
    \n\t#Respond on console with help message\r\
    \n\tput (\"[Provision][Info]: incorrect arguments, try:\")\r\
    \n\tput (\"\\\$provision auto|purge|failover|gateways|dyndns|resolver|livestream\")\r\
    \n\r\
    \n\t#Exit with error\r\
    \n\tset execStatus -1\r\
    \n\treturn \$execStatus\r\
    \n}"
/system script add dont-require-permissions=no name=mod-gateway policy=read,write source="#Gateway selector module script\r\
    \n#Script permissions: read, write\r\
    \n#Script dependencies: mod-provision\r\
    \n\r\
    \n#Function declaration\r\
    \nglobal gateway do={\r\
    \n\t#Error handling functions\r\
    \n\tlocal notify do={local msg \"[Gateway Selector][Info]: \$1\";put \$msg}\r\
    \n\tlocal warn do={local msg \"[Gateway Selector][Warn]: \$1\";put \$msg;log warn \$msg}\r\
    \n\tlocal error do={local msg \"[Gateway Selector][Error]: \$1\";put \$msg;return -1}\r\
    \n\tlocal execStatus 0\r\
    \n\t\r\
    \n\t#Gain variable access\r\
    \n\tglobal WANNames\r\
    \n\tglobal WANGateways\r\
    \n\tglobal WANGatewayPrefix\r\
    \n\tglobal BalancingRulePrefix\r\
    \n\r\
    \n\t#If function was called with argument \"switch\"\r\
    \n\tif (\$1=\"switch\" && [typeof \$2]!=\"nothing\" && [typeof \$3]=\"nothing\") do={\r\
    \n\t\tif (\$2=\"Balancer\") do={\r\
    \n\t\t\t#If there are no load balancing rules present\r\
    \n\t\t\tif ([/ip firewall mangle find comment~\$BalancingRulePrefix]=\"\") do={\r\
    \n\t\t\t\t#Throw error and exit\r\
    \n\t\t\t\tset execStatus [\$error (\"Cannot activate load balancing because there are no corresponding rules present.\")]\r\
    \n\t\t\t\treturn \$execStatus\r\
    \n\t\t\t}\r\
    \n\r\
    \n\t\t\t#Declare helper flag\r\
    \n\t\t\tlocal WANOutage false\r\
    \n\r\
    \n\t\t\t#Iterate through the gateways\r\
    \n\t\t\tforeach WANGateway in=\$WANGateways do={\r\
    \n\t\t\t\t#If there's at least one non-operational gateway\r\
    \n\t\t\t\tif ([/ip route get value-name=distance [find gateway=\$WANGateway comment~\$WANGatewayPrefix]]>[len \$WANGateways]) do={\r\
    \n\t\t\t\t\t#Adjust the helper flag\r\
    \n\t\t\t\t\tset WANOutage true\r\
    \n\t\t\t\t}\r\
    \n\t\t\t}\r\
    \n\r\
    \n\t\t\t#If there's a WAN outage\r\
    \n\t\t\tif (\$WANOutage) do={\r\
    \n\t\t\t\t#If load balancing was not active prior the outage\r\
    \n\t\t\t\tif ([/ip firewall mangle find action=passthrough content=\"Failover\" comment~\$BalancingRulePrefix]=\"\") do={\r\
    \n\t\t\t\t\t#Create semaphore rule\r\
    \n\t\t\t\t\t/ip firewall mangle add chain=input action=passthrough disabled=yes content=\"Failover\" comment=\"\$BalancingRulePrefix\"\r\
    \n\r\
    \n\t\t\t\t\t#Throw warning\r\
    \n\t\t\t\t\t\$warn (\"Load balancing has been selected and will be activated once WAN outage has been resolved.\")\r\
    \n\t\t\t\t} else {\r\
    \n\t\t\t\t\t#Throw warning\r\
    \n\t\t\t\t\t\$warn (\"Load balancing is already selected, but will be activated once the WAN outage has been resolved.\")\r\
    \n\t\t\t\t}\r\
    \n\t\t\t} else {\r\
    \n\t\t\t\t#If load balancing is currently active\r\
    \n\t\t\t\tif ([len [/ip firewall mangle find disabled=no comment~\$BalancingRulePrefix]]>0) do={\r\
    \n\t\t\t\t\t#Notify\r\
    \n\t\t\t\t\t\$notify (\"Load balancing is already active.\")\r\
    \n\t\t\t\t} else {\r\
    \n\t\t\t\t\t#Activate the load balancing rules\r\
    \n\t\t\t\t\t/ip firewall mangle set disabled=no [find comment~\$BalancingRulePrefix]\r\
    \n\r\
    \n\t\t\t\t\t#Notify\r\
    \n\t\t\t\t\t\$notify (\"Switched to: Load balancing\")\r\
    \n\t\t\t\t}\r\
    \n\t\t\t}\r\
    \n\r\
    \n\t\t\t#Exit\r\
    \n\t\t\treturn \$execStatus\r\
    \n\t\t}\r\
    \n\r\
    \n\t\t#Iterate through the gateways\r\
    \n\t\tforeach wanIndex,WANName in=\$WANNames do={\r\
    \n\t\t\t#If the requested gateway exists\r\
    \n\t\t\tif (\$2=\$WANName) do={\r\
    \n\t\t\t\t#Declare helper flags\r\
    \n\t\t\t\tlocal gatewayOperational true\r\
    \n\t\t\t\tlocal disabledBalancer false\r\
    \n\r\
    \n\t\t\t\t#Fetch its distance\r\
    \n\t\t\t\tlocal requestedGatewayDistance [/ip route get value-name=distance [find gateway=(\$WANGateways->\$wanIndex) comment~\$WANGatewayPrefix]]\r\
    \n\r\
    \n\t\t\t\t#If it's non-operational\r\
    \n\t\t\t\tif (\$requestedGatewayDistance>[len \$WANGateways]) do={\r\
    \n\t\t\t\t\t#Adjust for real distance\r\
    \n\t\t\t\t\tset requestedGatewayDistance (\$requestedGatewayDistance-[len \$WANGateways])\r\
    \n\r\
    \n\t\t\t\t\t#Adjust helper flag\r\
    \n\t\t\t\t\tset gatewayOperational false\r\
    \n\t\t\t\t}\r\
    \n\r\
    \n\t\t\t\t#If load balancing is currently active\r\
    \n\t\t\t\tif ([len [/ip firewall mangle find disabled=no comment~\$BalancingRulePrefix]]>0) do={\r\
    \n\t\t\t\t\t#Deactivate the load balancing rules\r\
    \n\t\t\t\t\t/ip firewall mangle set disabled=yes [find comment~\$BalancingRulePrefix]\r\
    \n\r\
    \n\t\t\t\t\t#Adjust helper flag\r\
    \n\t\t\t\t\tset disabledBalancer true\r\
    \n\t\t\t\t}\r\
    \n\r\
    \n\t\t\t\t#If load balancing was active prior a WAN outage\r\
    \n\t\t\t\tif ([/ip firewall mangle find action=passthrough content=\"Failover\" comment~\$BalancingRulePrefix]!=\"\") do={\r\
    \n\t\t\t\t\t#Clean up semaphore rule\r\
    \n\t\t\t\t\t/ip firewall mangle remove [find action=passthrough content=\"Failover\" comment~\$BalancingRulePrefix]\r\
    \n\r\
    \n\t\t\t\t\t#Adjust helper flag\r\
    \n\t\t\t\t\tset disabledBalancer true\r\
    \n\t\t\t\t}\r\
    \n\r\
    \n\t\t\t\t#If it's already the default gateway\r\
    \n\t\t\t\tif (\$requestedGatewayDistance=1) do={\r\
    \n\t\t\t\t\t#If load balancing was just disabled\r\
    \n\t\t\t\t\tif (\$disabledBalancer) do={\r\
    \n\t\t\t\t\t\t#If it's operational\r\
    \n\t\t\t\t\t\tif (\$gatewayOperational) do={\r\
    \n\t\t\t\t\t\t\t#Notify\r\
    \n\t\t\t\t\t\t\t\$notify (\"Switched to: \$WANName\")\r\
    \n\t\t\t\t\t\t} else {\r\
    \n\t\t\t\t\t\t\t#Throw warning\r\
    \n\t\t\t\t\t\t\t\$warn (\"\$WANName has been selected and will be available once it regains WAN access.\")\r\
    \n\t\t\t\t\t\t}\r\
    \n\t\t\t\t\t} else {\r\
    \n\t\t\t\t\t\t#If it's operational\r\
    \n\t\t\t\t\t\tif (\$gatewayOperational) do={\r\
    \n\t\t\t\t\t\t\t#Notify\r\
    \n\t\t\t\t\t\t\t\$notify (\"\$WANName is already the default gateway.\")\r\
    \n\t\t\t\t\t\t} else {\r\
    \n\t\t\t\t\t\t\t#Throw warning\r\
    \n\t\t\t\t\t\t\t\$warn (\"\$WANName is already selected, but will be available once it regains WAN access.\")\r\
    \n\t\t\t\t\t\t}\r\
    \n\t\t\t\t\t}\r\
    \n\r\
    \n\t\t\t\t\t#Exit\r\
    \n\t\t\t\t\treturn \$execStatus\r\
    \n\t\t\t\t}\r\
    \n\r\
    \n\t\t\t\t#Iterate through the gateways\r\
    \n\t\t\t\tforeach WANGateway in=\$WANGateways do={\r\
    \n\t\t\t\t\t#Fetch their distance information\r\
    \n\t\t\t\t\tlocal gatewayDistance [/ip route get value-name=distance [find gateway=\$WANGateway comment~\$WANGatewayPrefix]]\r\
    \n\r\
    \n\t\t\t\t\t#If there are any non-operational ones\r\
    \n\t\t\t\t\tif (\$gatewayDistance>[len \$WANGateways]) do={\r\
    \n\t\t\t\t\t\t#Adjust for real distance\r\
    \n\t\t\t\t\t\tset gatewayDistance (\$gatewayDistance-[len \$WANGateways])\r\
    \n\t\t\t\t\t}\r\
    \n\r\
    \n\t\t\t\t\t#For every gateway's default route that has a distance less than requested one\r\
    \n\t\t\t\t\tif (\$gatewayDistance<\$requestedGatewayDistance) do={\r\
    \n\t\t\t\t\t\t#Increase their distance by one\r\
    \n\t\t\t\t\t\t/ip route set distance=([/ip route get value-name=distance [find gateway=\$WANGateway comment~\$WANGatewayPrefix]]+1) [find gateway=\$WANGateway comment~\$WANGatewayPrefix]\r\
    \n\t\t\t\t\t}\r\
    \n\t\t\t\t}\r\
    \n\r\
    \n\t\t\t\t#Set the minimum distance to one\r\
    \n\t\t\t\tlocal minDistance 1\r\
    \n\r\
    \n\t\t\t\t#If it's non-operational\r\
    \n\t\t\t\tif (!\$gatewayOperational) do={\r\
    \n\t\t\t\t\t#Set the minimum distance to the total number of gateways plus one\r\
    \n\t\t\t\t\tset minDistance ([len \$WANGateways]+1)\r\
    \n\t\t\t\t}\r\
    \n\r\
    \n\t\t\t\t#Set it as the default gateway\r\
    \n\t\t\t\t/ip route set distance=\$minDistance [find gateway=(\$WANGateways->\$wanIndex) comment~\$WANGatewayPrefix]\r\
    \n\r\
    \n\t\t\t\t#If it's operational\r\
    \n\t\t\t\tif (\$gatewayOperational) do={\r\
    \n\t\t\t\t\t#Notify\r\
    \n\t\t\t\t\t\$notify (\"Switched to: \$WANName\")\r\
    \n\t\t\t\t} else {\r\
    \n\t\t\t\t\t#Throw warning\r\
    \n\t\t\t\t\t\$warn (\"\$WANName has been selected and will be available once it regains WAN access.\")\r\
    \n\t\t\t\t}\r\
    \n\r\
    \n\t\t\t\t#Exit\r\
    \n\t\t\t\treturn \$execStatus\r\
    \n\t\t\t}\r\
    \n\t\t}\r\
    \n\r\
    \n\t\t#If this part has been reached, it means that no valid gateway was caught\r\
    \n\t\t#Throw error and exit\r\
    \n\t\tset execStatus [\$error (\"Cannot switch to \$2 because there's no such gateway declared in the config file.\")]\r\
    \n\t\treturn \$execStatus\r\
    \n\t}\r\
    \n\r\
    \n\t#If function was called with argument \"status\"\r\
    \n\tif (\$1=\"status\" && [typeof \$2]=\"nothing\") do={\r\
    \n\t\t#Find the gateway of least distance\r\
    \n\t\tlocal currGateway \"\"\r\
    \n\t\tlocal currMinDistance ([len \$WANGateways]+1)\r\
    \n\t\tforeach wanIndex,WANName in=\$WANNames do={\r\
    \n\t\t\tif ([/ip route get value-name=distance [find gateway=(\$WANGateways->\$wanIndex) comment~\$WANGatewayPrefix]]<\$currMinDistance) do={\r\
    \n\t\t\t\tset currGateway \$WANName\r\
    \n\t\t\t\tset currMinDistance [/ip route get value-name=distance [find gateway=(\$WANGateways->\$wanIndex) comment~\$WANGatewayPrefix]]\r\
    \n\t\t\t}\r\
    \n\t\t}\r\
    \n\r\
    \n\t\t#If the gateway of least distance is non-operational\r\
    \n\t\tif (\$currMinDistance>[len \$WANGateways]) do={\r\
    \n\t\t\t#Throw warning\r\
    \n\t\t\t\$warn (\"All gateways are non-operational.\")\r\
    \n\t\t} else {\r\
    \n\t\t\t#If load balancing is currently active\r\
    \n\t\t\tif ([len [/ip firewall mangle find disabled=no comment~\$BalancingRulePrefix]]>0) do={\r\
    \n\t\t\t\t#Notify\r\
    \n\t\t\t\t\$notify (\"Currently via: Load balancing\")\r\
    \n\t\t\t} else {\r\
    \n\t\t\t\t#Notify\r\
    \n\t\t\t\t\$notify (\"Currently via: \$currGateway\")\r\
    \n\t\t\t}\r\
    \n\t\t}\r\
    \n\r\
    \n\t\t#Exit\r\
    \n\t\treturn \$execStatus\r\
    \n\t}\r\
    \n\r\
    \n\t#If this part has been reached, it means that no valid arguments were caught\r\
    \n\t#Respond on console with help message\r\
    \n\tput (\"[Gateway Selector][Info]: incorrect arguments, try:\")\r\
    \n\tput (\"\\\$gateway <switch Balancer|<WAN Name>>|status\")\r\
    \n\r\
    \n\t#Exit with error\r\
    \n\tset execStatus -1\r\
    \n\treturn \$execStatus\r\
    \n}"
/system script add dont-require-permissions=no name=mod-failover policy=read,write source="#Failover module script\r\
    \n#Script permissions: read, write\r\
    \n#Script dependencies: mod-provision, mod-gateway\r\
    \n\r\
    \n#Function declaration\r\
    \nglobal failover do={\r\
    \n\t#Error handling functions\r\
    \n\tlocal notify do={local msg \"[Failover][Info]: \$1\";put \$msg;log info \$msg}\r\
    \n\tlocal warn do={local msg \"[Failover][Warn]: \$1\";put \$msg;log warn \$msg}\r\
    \n\tlocal error do={local msg \"[Failover][Error]: \$1\";put \$msg;log error \$msg;return -1}\r\
    \n\tlocal execStatus 0\r\
    \n\r\
    \n\t#Gain variable access\r\
    \n\tglobal gateway\r\
    \n\tglobal WANNames\r\
    \n\tglobal WANGateways\r\
    \n\tglobal WANGatewayPrefix\r\
    \n\tglobal BalancingRulePrefix\r\
    \n\tglobal FailoverCounters\r\
    \n\tglobal FailoverTarget\r\
    \n\tglobal FailoverThreshold\r\
    \n\r\
    \n\t#If the gateway selector function is not present\r\
    \n\tif ([typeof \$gateway]=\"nothing\") do={\r\
    \n\t\t#Throw error and exit\r\
    \n\t\tset execStatus [\$error (\"The gateway selector function is missing. Please ensure that the module is installed and properly provisioned.\")]\r\
    \n\t\treturn \$execStatus\r\
    \n\t}\r\
    \n\r\
    \n\t#If function was called with argument \"check\"\r\
    \n\tif (\$1=\"check\" && [typeof \$2]=\"nothing\") do={\r\
    \n\t\t#WAN availability evaluator subfunction\r\
    \n\t\t#Inputs: <WAN index>\r\
    \n\t\tlocal evaluateAvailability do={\r\
    \n\t\t\t#WAN interface locator subfunction\r\
    \n\t\t\t#Inputs: <Gateway address>\r\
    \n\t\t\tlocal locateWANInterface do={\r\
    \n\t\t\t\t#Iterate through the ip address entries\r\
    \n\t\t\t\tforeach entry in=[/ip address find] do={\r\
    \n\t\t\t\t\t#Fetch the address information\r\
    \n\t\t\t\t\tlocal entryAddress [/ip address get value-name=address \$entry]\r\
    \n\r\
    \n\t\t\t\t\t#If it contains a subnet mask\r\
    \n\t\t\t\t\tif ([typeof [find \$entryAddress \"/\"]]=\"num\") do={\r\
    \n\t\t\t\t\t\t#Convert the mask to octet format\r\
    \n\t\t\t\t\t\tlocal entryMask [toip (255.255.255.255<<(32-[pick \$entryAddress ([find \$entryAddress \"/\"]+1) [len \$entryAddress]]))]\r\
    \n\r\
    \n\t\t\t\t\t\t#Calculate the host range\r\
    \n\t\t\t\t\t\tlocal firstHost ([toip ([pick \$entryAddress 0 ([find \$entryAddress \"/\"])]&(\$entryMask))]+1)\r\
    \n\t\t\t\t\t\tlocal lastHost ([toip ([pick \$entryAddress 0 ([find \$entryAddress \"/\"])]|(~\$entryMask))]-1)\r\
    \n\r\
    \n\t\t\t\t\t\t#If the requested address exists within the host range\r\
    \n\t\t\t\t\t\tif (\$1>=\$firstHost && \$1<=\$lastHost) do={\r\
    \n\t\t\t\t\t\t\t#Return the name of the corresponding interface\r\
    \n\t\t\t\t\t\t\treturn [/ip address get value-name=interface \$entry]\r\
    \n\t\t\t\t\t\t}\r\
    \n\t\t\t\t\t}\r\
    \n\t\t\t\t}\r\
    \n\r\
    \n\t\t\t\t#If this part has been reached, it means that no valid interface was caught\r\
    \n\t\t\t\t#Exit\r\
    \n\t\t\t\treturn \"\"\r\
    \n\t\t\t}\r\
    \n\r\
    \n\t\t\t#Error handling functions\r\
    \n\t\t\tlocal notify do={local msg \"[Failover][Info]: \$1\";put \$msg;log info \$msg}\r\
    \n\t\t\tlocal warn do={local msg \"[Failover][Warn]: \$1\";put \$msg;log warn \$msg}\r\
    \n\r\
    \n\t\t\t#Gain variable access\r\
    \n\t\t\tglobal WANNames\r\
    \n\t\t\tglobal WANGateways\r\
    \n\t\t\tglobal WANGatewayPrefix\r\
    \n\t\t\tglobal BalancingRulePrefix\r\
    \n\t\t\tglobal FailoverCounters\r\
    \n\t\t\tglobal FailoverTarget\r\
    \n\t\t\tglobal FailoverThreshold\r\
    \n\r\
    \n\t\t\t#Declare helper flag\r\
    \n\t\t\tlocal pingSuccessful false\r\
    \n\r\
    \n\t\t\t#If the gateway points to a valid interface\r\
    \n\t\t\tlocal WANInterface [\$locateWANInterface (\$WANGateways->\$1)]\r\
    \n\t\t\tif (\$WANInterface!=\"\") do={\r\
    \n\t\t\t\t#Ping the target through that interface and if it succeeds\r\
    \n\t\t\t\tif ([ping \$FailoverTarget count=1 interface=\$WANInterface]>0) do={\r\
    \n\t\t\t\t\t#Adjust helper flag\r\
    \n\t\t\t\t\tset pingSuccessful true\r\
    \n\t\t\t\t}\r\
    \n\t\t\t}\r\
    \n\r\
    \n\t\t\t#If the gateway is operational\r\
    \n\t\t\tif ([/ip route get value-name=distance [find gateway=(\$WANGateways->\$1) comment~\$WANGatewayPrefix]]<=[len \$WANGateways]) do={\r\
    \n\t\t\t\t#If the ping was successful\r\
    \n\t\t\t\tif (\$pingSuccessful) do={\r\
    \n\t\t\t\t\t#If its counter had picked up any failures prior\r\
    \n\t\t\t\t\tif ((\$FailoverCounters->\$1)>0) do={\r\
    \n\t\t\t\t\t\t#Set it to minus one\r\
    \n\t\t\t\t\t\tset (\$FailoverCounters->\$1) -1\r\
    \n\t\t\t\t\t} else {\r\
    \n\t\t\t\t\t\t#Reduce it by one\r\
    \n\t\t\t\t\t\tset (\$FailoverCounters->\$1) ((\$FailoverCounters->\$1)-1)\r\
    \n\t\t\t\t\t}\r\
    \n\t\t\t\t} else {\r\
    \n\t\t\t\t\t#If its counter had not picked up any failures prior\r\
    \n\t\t\t\t\tif ((\$FailoverCounters->\$1)<=0) do={\r\
    \n\t\t\t\t\t\t#Set it to one\r\
    \n\t\t\t\t\t\tset (\$FailoverCounters->\$1) 1\r\
    \n\t\t\t\t\t} else {\r\
    \n\t\t\t\t\t\t#Increase it by one\r\
    \n\t\t\t\t\t\tset (\$FailoverCounters->\$1) ((\$FailoverCounters->\$1)+1)\r\
    \n\t\t\t\t\t}\r\
    \n\r\
    \n\t\t\t\t\t#If its counter met the threshold\r\
    \n\t\t\t\t\tif ((\$FailoverCounters->\$1)=\$FailoverThreshold) do={\r\
    \n\t\t\t\t\t\t#Throw a warning\r\
    \n\t\t\t\t\t\t\$warn (\"WAN outage detected on \".(\$WANNames->\$1).\".\")\r\
    \n\r\
    \n\t\t\t\t\t\t#Increase its default route distance\r\
    \n\t\t\t\t\t\t/ip route set distance=([/ip route get value-name=distance [find gateway=(\$WANGateways->\$1) comment~\$WANGatewayPrefix]]+[/len \$WANGateways]) [find gateway=(\$WANGateways->\$1) comment~\$WANGatewayPrefix]\r\
    \n\r\
    \n\t\t\t\t\t\t#If load balancing is currently active\r\
    \n\t\t\t\t\t\tif ([len [/ip firewall mangle find disabled=no comment~\$BalancingRulePrefix]]>0) do={\r\
    \n\t\t\t\t\t\t\t#Deactivate its rules\r\
    \n\t\t\t\t\t\t\t/ip firewall mangle set disabled=yes [find comment~\$BalancingRulePrefix]\r\
    \n\r\
    \n\t\t\t\t\t\t\t#Create semaphore rule\r\
    \n\t\t\t\t\t\t\t/ip firewall mangle add chain=input action=passthrough disabled=yes content=\"Failover\" comment=\"\$BalancingRulePrefix\"\r\
    \n\r\
    \n\t\t\t\t\t\t\t#Throw a warning\r\
    \n\t\t\t\t\t\t\t\$warn (\"Load balancing has been temporarily disabled until all gateways regain WAN access.\")\r\
    \n\t\t\t\t\t\t}\r\
    \n\r\
    \n\t\t\t\t\t\t#Declare helper flag\r\
    \n\t\t\t\t\t\tlocal WANOutage true\r\
    \n\r\
    \n\t\t\t\t\t\t#Iterate through the gateways\r\
    \n\t\t\t\t\t\tforeach WANGateway in=\$WANGateways do={\r\
    \n\t\t\t\t\t\t\t#If there's at least one that's operational\r\
    \n\t\t\t\t\t\t\tif ([/ip route get value-name=distance [find gateway=\$WANGateway comment~\$WANGatewayPrefix]]<=[len \$WANGateways]) do={\r\
    \n\t\t\t\t\t\t\t\t#Adjust the helper flag\r\
    \n\t\t\t\t\t\t\t\tset WANOutage false\r\
    \n\t\t\t\t\t\t\t}\r\
    \n\t\t\t\t\t\t}\r\
    \n\r\
    \n\t\t\t\t\t\t#If all gateways are non-operational\r\
    \n\t\t\t\t\t\tif (\$WANOutage) do={\r\
    \n\t\t\t\t\t\t\t#Throw a warning\r\
    \n\t\t\t\t\t\t\t\$warn (\"WAN outage detected on all gateways.\")\r\
    \n\t\t\t\t\t\t}\r\
    \n\t\t\t\t\t}\r\
    \n\t\t\t\t\t\r\
    \n\t\t\t\t}\r\
    \n\t\t\t} else {\r\
    \n\t\t\t\t#If the ping was successful\r\
    \n\t\t\t\tif (\$pingSuccessful) do={\r\
    \n\t\t\t\t\t#Reset its counter to zero\r\
    \n\t\t\t\t\tset (\$FailoverCounters->\$1) 0\r\
    \n\r\
    \n\t\t\t\t\t#Decrease its default route distance\r\
    \n\t\t\t\t\t/ip route set distance=([/ip route get value-name=distance [find gateway=(\$WANGateways->\$1) comment~\$WANGatewayPrefix]]-[/len \$WANGateways]) [find gateway=(\$WANGateways->\$1) comment~\$WANGatewayPrefix]\r\
    \n\r\
    \n\t\t\t\t\t#Notify\r\
    \n\t\t\t\t\t\$notify (\"Gateway \".(\$WANNames->\$1).\" regained WAN access.\")\r\
    \n\r\
    \n\t\t\t\t\t#Declare helper flag\r\
    \n\t\t\t\t\tlocal WANOutage false\r\
    \n\r\
    \n\t\t\t\t\t#Iterate through the gateways\r\
    \n\t\t\t\t\tforeach WANGateway in=\$WANGateways do={\r\
    \n\t\t\t\t\t\t#If there's at least one that's non-operational\r\
    \n\t\t\t\t\t\tif ([/ip route get value-name=distance [find gateway=\$WANGateway comment~\$WANGatewayPrefix]]>[len \$WANGateways]) do={\r\
    \n\t\t\t\t\t\t\t#Adjust the helper flag\r\
    \n\t\t\t\t\t\t\tset WANOutage true\r\
    \n\t\t\t\t\t\t}\r\
    \n\t\t\t\t\t}\r\
    \n\r\
    \n\t\t\t\t\t#If all gateways are operational\r\
    \n\t\t\t\t\tif (!\$WANOutage) do={\r\
    \n\t\t\t\t\t\t#Notify\r\
    \n\t\t\t\t\t\t\$notify (\"All gateways have regained WAN access.\")\r\
    \n\r\
    \n\t\t\t\t\t\t#If load balancing was enabled prior the outage\r\
    \n\t\t\t\t\t\tif ([/ip firewall mangle find action=passthrough content=\"Failover\" comment~\$BalancingRulePrefix]!=\"\") do={\r\
    \n\t\t\t\t\t\t\t#Clean up semaphore rule\r\
    \n\t\t\t\t\t\t\t/ip firewall mangle remove [find action=passthrough content=\"Failover\" comment~\$BalancingRulePrefix]\r\
    \n\r\
    \n\t\t\t\t\t\t\t#Activate its rules\r\
    \n\t\t\t\t\t\t\t/ip firewall mangle set disabled=no [find comment~\$BalancingRulePrefix]\r\
    \n\r\
    \n\t\t\t\t\t\t\t#Notify\r\
    \n\t\t\t\t\t\t\t\$notify (\"Load balancing has been reactivated because it was previously enabled.\")\r\
    \n\t\t\t\t\t\t}\r\
    \n\t\t\t\t\t}\r\
    \n\t\t\t\t} else {\r\
    \n\t\t\t\t\t#In case the device is coming off of a reboot and the failed gateway's counter has not yet met or surpassed the threshold\r\
    \n\t\t\t\t\tif ((\$FailoverCounters->\$1)<\$FailoverThreshold) do={\r\
    \n\t\t\t\t\t\t#Set it to the threshold\r\
    \n\t\t\t\t\t\tset (\$FailoverCounters->\$1) \$FailoverThreshold\r\
    \n\t\t\t\t\t} else {\r\
    \n\t\t\t\t\t\t#Increase it by one\r\
    \n\t\t\t\t\t\tset (\$FailoverCounters->\$1) ((\$FailoverCounters->\$1)+1)\r\
    \n\t\t\t\t\t}\r\
    \n\t\t\t\t}\r\
    \n\t\t\t}\r\
    \n\t\t}\r\
    \n\r\
    \n\t\t#For every gateway\r\
    \n\t\tforeach wanIndex,WANName in=\$WANNames do={\r\
    \n\t\t\t#Evaluate its availability\r\
    \n\t\t\t\$evaluateAvailability \$wanIndex\r\
    \n\t\t}\r\
    \n\r\
    \n\t\t#Exit\r\
    \n\t\treturn \$execStatus\r\
    \n\t}\r\
    \n\r\
    \n\t#If function was called with argument \"toggle\"\r\
    \n\tif (\$1=\"toggle\" && [typeof \$2]=\"nothing\") do={\r\
    \n\t\t#If the scheduler entry for the periodic failover checks is not enabled\r\
    \n\t\tif ([/system scheduler get value-name=disabled [find name=cron-failover]]) do={\r\
    \n\t\t\t#Enable it\r\
    \n\t\t\t/system scheduler set disabled=no [find name=cron-failover]\r\
    \n\r\
    \n\t\t\t#Notify\r\
    \n\t\t\t\$notify (\"Enabled.\")\r\
    \n\t\t} else {\r\
    \n\t\t\t#For every gateway\r\
    \n\t\t\tforeach WANGateway in=\$WANGateways do={\r\
    \n\t\t\t\t#Which is non-operational\r\
    \n\t\t\t\tif ([/ip route get value-name=distance [find gateway=\$WANGateway comment~\$WANGatewayPrefix]]>[len \$WANGateways]) do={\r\
    \n\t\t\t\t\t#Restore its distance\r\
    \n\t\t\t\t\t/ip route set distance=([/ip route get value-name=distance [find gateway=\$WANGateway comment~\$WANGatewayPrefix]]-[/len \$WANGateways]) [find gateway=\$WANGateway comment~\$WANGatewayPrefix]\r\
    \n\t\t\t\t}\r\
    \n\t\t\t}\r\
    \n\r\
    \n\t\t\t#If load balancing was enabled prior the outage\r\
    \n\t\t\tif ([/ip firewall mangle find content=\"Failover\" comment~\$BalancingRulePrefix]!=\"\") do={\r\
    \n\t\t\t\t#Clean up semaphore rule\r\
    \n\t\t\t\t/ip firewall mangle remove [find action=passthrough content=\"Failover\" comment~\$BalancingRulePrefix]\r\
    \n\r\
    \n\t\t\t\t#Activate its rules\r\
    \n\t\t\t\t/ip firewall mangle set disabled=no [find comment~\$BalancingRulePrefix]\t\t\t\t\r\
    \n\t\t\t}\r\
    \n\r\
    \n\t\t\t#Disable it\r\
    \n\t\t\t/system scheduler set disabled=yes [find name=cron-failover]\r\
    \n\r\
    \n\t\t\t#Notify\r\
    \n\t\t\t\$notify (\"Disabled.\")\r\
    \n\t\t}\r\
    \n\r\
    \n\t\t#Exit\r\
    \n\t\treturn \$execStatus\r\
    \n\t}\r\
    \n\r\
    \n\t#If function was called with argument \"status\"\r\
    \n\tif (\$1=\"status\" && [typeof \$2]=\"nothing\") do={\r\
    \n\t\t#Error handling functions\r\
    \n\t\tlocal notifyCon do={local msg \"[Failover][Info]: \$1\";put \$msg}\r\
    \n\r\
    \n\t\t#If the scheduler entry for the periodic failover checks is not enabled\r\
    \n\t\tif ([/system scheduler get value-name=disabled [find name=cron-failover]]) do={\r\
    \n\t\t\t#Notify\r\
    \n\t\t\t\$notifyCon (\"Failover status: Inactive.\")\r\
    \n\t\t} else {\r\
    \n\t\t\t#Notify\r\
    \n\t\t\t\$notifyCon (\"Failover status: Active.\")\r\
    \n\t\t}\r\
    \n\r\
    \n\t\t#Declare helper string\r\
    \n\t\tlocal WANStatus\r\
    \n\r\
    \n\t\t#Iterate through the failover counters\r\
    \n\t\tforeach wanIndex,WANName in=\$WANNames do={\r\
    \n\t\t\t#If the counter value greater than zero\r\
    \n\t\t\tif ((\$FailoverCounters->\$wanIndex)>0) do={\r\
    \n\t\t\t\t#Append the downtime estimation to the message\r\
    \n\t\t\t\tset WANStatus (\"\$WANName: Offline\\t(down for at least \".((\$FailoverCounters->\$wanIndex)*[/system scheduler get value-name=interval [find name=cron-failover]]).\")\")\r\
    \n\t\t\t} else {\r\
    \n\t\t\t\tset WANStatus (\"\$WANName: Online\\t(up for at least \".((\$FailoverCounters->\$wanIndex)*(-1)*[/system scheduler get value-name=interval [find name=cron-failover]]).\")\")\r\
    \n\t\t\t}\r\
    \n\r\
    \n\t\t\t#Notify\r\
    \n\t\t\t\$notifyCon \$WANStatus\r\
    \n\t\t}\r\
    \n\r\
    \n\t\t#Exit\r\
    \n\t\treturn \$execStatus\r\
    \n\t}\r\
    \n\r\
    \n\t#If this part has been reached, it means that no valid arguments were caught\r\
    \n\t#Respond on console with help message\r\
    \n\tput (\"[Failover][Info]: incorrect arguments, try:\")\r\
    \n\tput (\"\\\$failover check|toggle|status\")\r\
    \n\r\
    \n\t#Exit with error\r\
    \n\tset execStatus -1\r\
    \n\treturn \$execStatus\r\
    \n}"
/system script add dont-require-permissions=no name=mod-dyndns policy=read,write source="#DynDNS updater module script\r\
    \n#Script permissions: read, write\r\
    \n#Script dependencies: mod-provision\r\
    \n#Extra requirements: at least one DNS server must be configured\r\
    \n\r\
    \n#Function declaration\r\
    \nglobal dyndns do={\r\
    \n\t#Error handling functions\r\
    \n\tlocal notify do={local msg \"[DynDNS Updater][Info]: \$1\";put \$msg;log info \$msg}\r\
    \n\tlocal error do={local msg \"[DynDNS Updater][Error]: \$1\";put \$msg;log error \$msg;return -1}\r\
    \n\tlocal execStatus 0\r\
    \n\r\
    \n\t#If function was called with argument \"update\"\r\
    \n\tif (\$1=\"update\" && [typeof \$2]=\"nothing\") do={\r\
    \n\t\t#If there are no DNS servers configured\r\
    \n\t\tif ([/ip dns get value-name=servers]=\"\") do={\r\
    \n\t\t\t#Throw error and exit\r\
    \n\t\t\tset execStatus [\$error (\"At least one DNS server must be configured.\")]\r\
    \n\t\t\treturn \$execStatus\r\
    \n\t\t}\r\
    \n\r\
    \n\t\t#Gain variable access\r\
    \n\t\tglobal DDNSService\r\
    \n\t\tglobal DDNSUsername\r\
    \n\t\tglobal DDNSPassword\r\
    \n\t\tglobal DDNSHostname\r\
    \n\t\tglobal WANAddress\r\
    \n\r\
    \n\t\t#Declare helper string\r\
    \n\t\tlocal updateURL\r\
    \n\r\
    \n\t\t#If the service is DynDNS\r\
    \n\t\tif (\$DDNSService=\"DynDNS\") do={\r\
    \n\t\t\t#Adjust the helper string\r\
    \n\t\t\tset updateURL \"https://members.dyndns.org/v3/update\"\t\t\t\r\
    \n\t\t}\r\
    \n\r\
    \n\t\t#If the service is NoIP\r\
    \n\t\tif (\$DDNSService=\"NoIP\") do={\r\
    \n\t\t\t#Adjust the helper string\r\
    \n\t\t\tset updateURL \"https://dynupdate.no-ip.com/nic/update\"\r\
    \n\t\t}\r\
    \n\r\
    \n\t\t#If no valid service was specified\r\
    \n\t\tif ([typeof \$updateURL]=\"nothing\") do={\r\
    \n\t\t\t#Throw error and exit\r\
    \n\t\t\tset execStatus [\$error (\"Invalid service configured. Please use either DynDNS or NoIP in the config and try again.\")]\r\
    \n\t\t\treturn \$execStatus\r\
    \n\t\t}\r\
    \n\r\
    \n\t\t#Poll opendns.com to discover the current WAN address\r\
    \n\t\tlocal currWANAddress [toip [resolve myip.opendns.com server=resolver1.opendns.com]]\r\
    \n\r\
    \n\t\t#If the stored WAN address is different from the one that was just fetched\r\
    \n\t\tif (\$WANAddress!=\$currWANAddress) do={\r\
    \n\t\t\t#Update the stored WAN address\r\
    \n\t\t\tset WANAddress \$currWANAddress\r\
    \n\r\
    \n\t\t\t#Notify\r\
    \n\t\t\t\$notify (\"New WAN Address detected: \$WANAddress - Updating \$DDNSService.\")\r\
    \n\r\
    \n\t\t\t#Update over HTTP\r\
    \n\t\t\t/tool fetch url=(\"\$updateURL\?hostname=\$DDNSHostname&myip=\$WANAddress\") user=\$DDNSUsername password=\$DDNSPassword mode=https keep-result=no\r\
    \n\t\t}\r\
    \n\r\
    \n\t\t#Exit\r\
    \n\t\treturn \$execStatus\r\
    \n\t}\r\
    \n\r\
    \n\t#If function was called with argument \"toggle\"\r\
    \n\tif (\$1=\"toggle\" && [typeof \$2]=\"nothing\") do={\r\
    \n\t\t#If the scheduler entry for the periodic DynDNS updates is not enabled\r\
    \n\t\tif ([/system scheduler get value-name=disabled [find name=cron-dyndns]]) do={\r\
    \n\t\t\t#Enable it\r\
    \n\t\t\t/system scheduler set disabled=no [find name=cron-dyndns]\r\
    \n\r\
    \n\t\t\t#Notify\r\
    \n\t\t\t\$notify (\"Enabled.\")\r\
    \n\t\t} else {\r\
    \n\t\t\t#Disable it\r\
    \n\t\t\t/system scheduler set disabled=yes [find name=cron-dyndns]\r\
    \n\r\
    \n\t\t\t#Notify\r\
    \n\t\t\t\$notify (\"Disabled.\")\r\
    \n\t\t}\r\
    \n\r\
    \n\t\t#Exit\r\
    \n\t\treturn \$execStatus\r\
    \n\t}\r\
    \n\r\
    \n\t#If this part has been reached, it means that no valid arguments were caught\r\
    \n\t#Respond on console with help message\r\
    \n\tput (\"[DynDNS][Info]: incorrect arguments, try:\")\r\
    \n\tput (\"\\\$dyndns update|toggle\")\r\
    \n\r\
    \n\t#Exit with error\r\
    \n\tset execStatus -1\r\
    \n\treturn \$execStatus\r\
    \n}"
/system script add dont-require-permissions=no name=mod-resolvefqdn policy=read,write source="#FQDN resolver module script\r\
    \n#Script permissions: read, write\r\
    \n#Script dependencies: none\r\
    \n#Extra requirements: at least one DNS server must be configured\r\
    \n\r\
    \n#Function declaration\r\
    \n#Inputs: <FQDN> <Address List>\r\
    \nglobal resolvefqdn do={\r\
    \n\t#Error handling functions\r\
    \n\tlocal error do={local msg \"[FQDN Resolver][Error]: \$1\";put \$msg;log error \$msg;return -1}\r\
    \n\tlocal execStatus 0\r\
    \n\r\
    \n\t#If there are no DNS servers configured\r\
    \n\tif ([/ip dns get value-name=servers]=\"\") do={\r\
    \n\t\t#Throw error and exit\r\
    \n\t\tset execStatus [\$error (\"At least one DNS server must be configured.\")]\r\
    \n\t\treturn \$execStatus\r\
    \n\t}\r\
    \n\r\
    \n\t#If there are any existing address list entries\r\
    \n\tif ([len [/ip firewall address-list find list=\$2]]>0) do={\r\
    \n\t\t#Remove them\r\
    \n\t\t/ip firewall address-list remove [find list=\$2]\r\
    \n\t}\r\
    \n\r\
    \n\t#Resolve the requested FQDN\r\
    \n\tresolve \$1\r\
    \n\r\
    \n\t#For every produced DNS record that was cached\r\
    \n\tforeach cachedRecord in=[/ip dns cache all find name=\$1] do={\r\
    \n\t\t#If its an A record\r\
    \n\t\tif ([/ip dns cache all get value-name=type \$cachedRecord]=\"A\") do={\r\
    \n\t\t\t#Add it to the requested address list\r\
    \n\t\t\t/ip firewall address-list add list=\$2 address=[/ip dns cache all get value-name=data \$cachedRecord] comment=\$1\r\
    \n\t\t}\r\
    \n\r\
    \n\t\t#If its a CNAME record\r\
    \n\t\tif ([/ip dns cache all get value-name=type \$cachedRecord]=\"CNAME\") do={\r\
    \n\t\t\t#Declare helper pointers\r\
    \n\t\t\tlocal currCNAME [/ip dns cache all find name=\$1 type=\"CNAME\"]\r\
    \n\t\t\tlocal nextCNAME [/ip dns cache all find name=[/ip dns cache all get value-name=data \$currCNAME] type=\"CNAME\"]\r\
    \n\r\
    \n\t\t\t#Keep navigating to the next node, until there are no more CNAME records\r\
    \n\t\t\twhile (\$nextCNAME!=\"\") do={\r\
    \n\t\t\t\tset currCNAME \$nextCNAME\r\
    \n\t\t\t\tset nextCNAME [/ip dns cache all find name=[/ip dns cache all get value-name=data \$currCNAME] type=\"CNAME\"]\r\
    \n\t\t\t}\r\
    \n\r\
    \n\t\t\t#For every underlying A record\r\
    \n\t\t\tforeach ARecord in=[/ip dns cache all find name=[/ip dns cache all get value-name=data \$currCNAME] type=\"A\"] do={\r\
    \n\t\t\t\t#Add it to the requested address list\r\
    \n\t\t\t\t/ip firewall address-list add list=\$2 address=[/ip dns cache all get value-name=data \$ARecord] comment=\$1\r\
    \n\t\t\t}\r\
    \n\t\t}\r\
    \n\t}\r\
    \n\r\
    \n\t#Exit\r\
    \n\treturn \$execStatus\r\
    \n}"
/system script add dont-require-permissions=no name=mod-livestream policy=read,write source="#Live streaming module script\r\
    \n#Script permissions: read, write\r\
    \n#Script dependencies: mod-provision, mod-resolvefqdn\r\
    \n\r\
    \n#Function declaration\r\
    \nglobal livestream do={\r\
    \n\t#Error handling functions\r\
    \n\tlocal notify do={local msg \"[Live Streaming][Info]: \$1\";put \$msg}\r\
    \n\tlocal error do={local msg \"[Live Streaming][Error]: \$1\";put \$msg;return -1}\r\
    \n\tlocal execStatus 0\r\
    \n\r\
    \n\t#Gain variable access\r\
    \n\tglobal LVStreamList\r\
    \n\tglobal LVStreamFQDN\r\
    \n\tglobal LVStreamRulePrefix\r\
    \n\tglobal resolvefqdn\r\
    \n\r\
    \n\t#If the FQDN resolver function is not present\r\
    \n\tif ([typeof \$resolvefqdn]=\"nothing\") do={\r\
    \n\t\t#Throw error and exit\r\
    \n\t\tset execStatus [\$error (\"The FQDN resolver function is missing. Please ensure that the module is installed and properly provisioned.\")]\r\
    \n\t\treturn \$execStatus\r\
    \n\t}\r\
    \n\r\
    \n\t#If there are no livestreaming rules present\r\
    \n\tif ([/ip firewall mangle find comment~\$LVStreamRulePrefix]=\"\") do={\r\
    \n\t\t#Throw error and exit\r\
    \n\t\tset execStatus [\$error (\"There are no corresponding rules present.\")]\r\
    \n\t\treturn \$execStatus\r\
    \n\t}\r\
    \n\r\
    \n\t#If function was called with \"toggle\" argument\r\
    \n\tif (\$1=\"toggle\" && [typeof \$2]=\"nothing\") do={\r\
    \n\t\t#If livestreaming mode is currently active\r\
    \n\t\tif ([len [/ip firewall mangle find disabled=no comment~\$LVStreamRulePrefix]]>0) do={\r\
    \n\t\t\t#Deactivate its rules\r\
    \n\t\t\t/ip firewall mangle set disabled=yes [find comment~\$LVStreamRulePrefix]\r\
    \n\r\
    \n\t\t\t#Clear the streaming service address list entries\r\
    \n\t\t\t/ip firewall address-list remove [find list=\$LVStreamList]\r\
    \n\r\
    \n\t\t\t#Notify\r\
    \n\t\t\t\$notify (\"Disabled.\")\r\
    \n\t\t} else {\r\
    \n\t\t\t#Resolve the streaming service FQDN into the corresponding address list\r\
    \n\t\t\t\$resolvefqdn \$LVStreamFQDN \$LVStreamList\r\
    \n\r\
    \n\t\t\t#Activate its rules\r\
    \n\t\t\t/ip firewall mangle set disabled=no [find comment~\$LVStreamRulePrefix]\r\
    \n\r\
    \n\t\t\t#Notify\r\
    \n\t\t\t\$notify (\"Enabled.\")\r\
    \n\t\t}\r\
    \n\r\
    \n\t\t#Exit\r\
    \n\t\treturn \$execStatus\r\
    \n\t}\r\
    \n\r\
    \n\t#If function was called with argument \"status\"\r\
    \n\tif (\$1=\"status\" && [typeof \$2]=\"nothing\") do={\r\
    \n\t\t#If livestreaming mode is currently active\r\
    \n\t\tif ([len [/ip firewall mangle find disabled=no comment~\$LVStreamRulePrefix]]>0) do={\r\
    \n\t\t\t#Notify\r\
    \n\t\t\t\$notify (\"Active.\")\r\
    \n\t\t} else {\r\
    \n\t\t\t#Notify\r\
    \n\t\t\t\$notify (\"Inactive.\")\r\
    \n\t\t}\r\
    \n\r\
    \n\t\t#Exit\r\
    \n\t\treturn \$execStatus\r\
    \n\t}\r\
    \n\r\
    \n\t#If this part has been reached, it means that no valid arguments were caught\r\
    \n\t#Respond on console with help message\r\
    \n\tput (\"[Live Streaming][Info]: incorrect arguments, try:\")\r\
    \n\tput (\"\\\$livestream toggle|status\")\r\
    \n\r\
    \n\t#Exit with error\r\
    \n\tset execStatus -1\r\
    \n\treturn \$execStatus\r\
    \n}"

#Provision the router
/system script run mod-provision

#Cleanup
/file remove [find name="RouterSCRIPTS_Installer.rsc"]

#Notify
$notify ("Install finished. Assuming you have read through the supplied readme file, you may now remove any modules that you have no use for, then run: \$provision auto")