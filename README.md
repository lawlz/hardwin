# hardwin
This repository is the place where I store and share my windows hardening woes, I mean funs, I mean yeah, for a presentation I give on this.  A lot of this code is not my own and I hope that all of it is properly attributed, because I pull from various other repos to conduct my windows hardening routines.


## Overview

This is used for documenting how I apply hardening settings on a Windows 10 system, when you don't have a domain to use to enforce secure baseline settings.

## The Journey...  Never Ends

Group policy for Windows is a mess, at least to me.  I have tried and tried to understand how to easily and intuitively apply hardened settings to Windows for an off network Windows client for some time.  

Group policy cmdlets may only work on a domain joined machine...
https://docs.microsoft.com/en-us/previous-versions/windows/it-pro/windows-server-2008-R2-and-2008/ee461027(v=technet.10)  

## Hardening Paths for Windows

### MS Documentation

MS has a security config framework, but really good guidance is all it is:
https://www.microsoft.com/security/blog/2019/04/11/introducing-the-security-configuration-framework-a-prioritized-guide-to-hardening-windows-10/

### Current Hardening Tools Available

#### DSC

Desired state configuration (DSC) is a new-ish toolset to apply configurations and baslines withuot the need to be a part of a domain.  It gets close to combining all the hardening into one interface, but has gotchas...  [About](https://docs.microsoft.com/en-us/powershell/scripting/dsc/overview/overview?view=powershell-6)  

Here are some links that I found helpful when attempting to use DSC for this.

* Since MS Baselines made a GPO format, this may help transforming [GPO to DSC template](https://www.powershellgallery.com/packages/GpoToDsc/1.1.24)
  * [Git](https://github.com/dsccommunity) DSC community repo.  
* This may be our best bet, but it has DSC configuration deps above, but can convert from policyrules to DSCs - maybe.. and yet to be found how...  
  * [Baseline Management](https://www.powershellgallery.com/packages/BaselineManagement/2.9.0)
* However, even DSC seems so disjoined and [compartmentalized](https://github.com/dsccommunity?page=2), not really combining efforts in a single direction...

How many different ways to set a setting a windows machine?!  Is DSC really making administration more easy?
  
However, I feel this may be the way to apply all types of security settings through one mechanism...  If MS would actually maintain it...

#### Current Script Work Found

RootSecDev has a great resource out there for what they called the [MIcrosoft-Blue-Forest](https://github.com/rootsecdev/Microsoft-Blue-Forest)

Here is one using [Ansible!](https://github.com/juju4/ansible-harden-windows)

Here is one using [Chef!](https://github.com/CHEF-KOCH/Windows-10-hardening)

These look very promising:  

* Holy crap, someone did a hardening win10 with Go! and seems to be currently [supported](https://github.com/securitywithoutborders/hardentools).
* Nice powershell one but only does an audit it looks like. [current](https://github.com/0x6d69636b/windows_hardening).
    - no it sets it too!
* Really nice powershell one that is using the net forms GUI thing and just what we are looking for maybe...  [PS_W_GUI](https://github.com/ssh3ll/Windows-10-Hardening)


Could be neat and references empire for some reason, but for ICS envs its looks like was the inital purpose.
https://github.com/cutaway-security/chaps


This guy did an amazing job documenting a best practice and how to maintain and support - [however it is archived...](https://github.com/Disassembler0/Win10-Initial-Setup-Script)  

Other interesting ones:
https://github.com/SwiftOnSecurity/OrgKit

Already packaged:
https://github.com/AndyFul/Hard_Configurator

Neat privacy related repo:
https://github.com/adolfintel/Windows10-Privacy


## Way Forward

* THis is also a good potential, last update late 2018, but this is NSA created and approved hardening standards for [high secure environments](https://github.com/nsacyber/Windows-Secure-Host-Baseline).  Handle with care, since I have bricked a machine applying everything NSA/DISA suggested in the past....
  * Regardless, this has a great little 'validation' or checker script that could come in handy...
  * **Issue** the offline script uses the admx files for where it pulls the configs from, verbatim, would need to modify or export new GPO admx files somehow.  It is XML and is not easily modded or updated as a baseline config source...

Guttin the above repo of its scripts.  It has a couple of functions that will take the secure baseline in excel format and conver to csv and vice versa.  
   https://github.com/nsacyber/Windows-Secure-Host-Baseline/tree/master/Scripts  


ADMX to DSC -   
https://github.com/gpoguy/ADMXToDSC  

But I found that 'F' DSC, is the best way to go...  I am sorry it took this long...


### Helpful Tools

Sysmon!
https://github.com/SwiftOnSecurity/sysmon-config


[Hardening Kitty!](https://github.com/0x6d69636b/windows_hardening)  Main template used ultimately or tried to use  





### References




[GPO management tools](https://www.google.com/search?q=GPO+Policy+Reporting+Pak&oq=GPO+Policy+Reporting+Pak)


#### Raw Reference notes


Hardening Baselines:

This one is the github by IAD from the gov'ment:
This is great and based on securing win10 and server 2016
https://github.com/iadgov/Secure-Host-Baseline


Some good info on how to use the built-in Win10 threat mitigations:
https://docs.microsoft.com/en-us/windows/threat-protection/overview-of-threat-mitigations-in-windows-10#data-execution-prevention
Do some configurations to do so:
https://support.microsoft.com/en-us/help/3000483/ms15-011-vulnerability-in-group-policy-could-allow-remote-code-executi


Great open source toolset!!  -- well maybe, some of the commands had some fishy things in it...
https://github.com/pshdo/Carbon


Pass the Hash Protections:
https://download.microsoft.com/download/7/7/A/77ABC5BD-8320-41AF-863C-6ECFB10CB4B9/Mitigating-Pass-the-Hash-Attacks-and-Other-Credential-Theft-Version-2.pdf


Another Quick View of STIGs by rule version
http://www.goldskysecurity.com/kb/controls/

A great STIG/RMF even resource:
https://demo.xylok.io/


Awesome group policy site!!!!
https://getadmx.com/
You can download templates through here, but even better it gives a great no-nonesense explanation of GP settings!


Helps understand C types to .Net types.
This can help with understanding the filetype to pass to the .net method.
http://www.pinvoke.net
Great Write-up
https://blogs.technet.microsoft.com/heyscriptingguy/2013/06/25/use-powershell-to-interact-with-the-windows-api-part-1/


Security Descriptor info/ACL stuffs
https://blogs.technet.microsoft.com/askds/2008/04/18/the-security-descriptor-definition-language-of-love-part-1/


Ways to apply hardening settings:
Desired State Configuration (DSC)
https://docs.microsoft.com/en-us/powershell/dsc/decisionmaker
Supposedly even works for Lunix boxes added to AD...  Maybe look into this.


Get your test infrastructure here!
https://developer.microsoft.com/en-us/microsoft-edge/tools/vms/
https://www.microsoft.com/en-us/evalcenter/evaluate-windows-server-2016




