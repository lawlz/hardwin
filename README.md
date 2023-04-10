# hardwin
This repository is the place where I store and share my windows hardening woes, I mean funs, I mean yeah, for a presentation I give on this.  A lot of this code is not my own and I hope that all of it is properly attributed, because I pull from various other repos to conduct my windows hardening routines.


## Overview

This is used for documenting how I apply hardening settings on a Windows 10 system, when you don't have a domain to use to enforce secure baseline settings.

## The Journey...  Never Ends

This is an ongoing journey, with each update a new service or feature to determine the worth of in our Windows life.  This code tries to be robust in what it can disable while also running in a home environment.  

## How to run 

It was tested mostly using Windows 10 21H2.  The script is meant to be easy to run and easily reconfigure as you see fit.  Since not everyone wants the things I turn off, you may have different choices in what services you will want to use even from MicroSoft.  Either way, here is how to use:


### Files in the Repo

- get-hardened.ps1
    - This is the main script to run.  You can call it directly and has a help file.
- hardeningUtils.psm1
    - This is the main module that is importanted and ran against using whatever preset file is passed
    - Can import directly using this command:
        - ```import-module hardeningUtils.psm1```
- Default.preset
    - This preset should work for most people.  You still want to look through to see if there is anything you don't want to disable.


###  How to Run

```
    -------------------------- EXAMPLE 1 --------------------------

    PS > get-hardened.ps1 -preset default.preset

    This command will not run the backup process.




    -------------------------- EXAMPLE 2 --------------------------

    PS > get-hardened.ps1 -preset default.preset -Backup

    This command will run the hardening with the default preset and do a backup.

```