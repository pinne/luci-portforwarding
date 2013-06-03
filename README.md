Port forwarding presets and device identification
=================================================

## TODO ##
 * diplay available services
 * do not use for loops
 * use Object.keys(jsonobjekt) to iterate, returns an array with keys
 * use .forEach(function(value,counter) { ... }); on array objects
 * migrate to using LuCI templates

## Instructions ##
### New LuCI application ###
Make a new directory for the LuCI application, or copy the myapplication/ dir
and create or copy your files:

### Working directory ###
    ~/Documents/School/Exjobb/iop-backfire/build_dir/target-mips_uClibc-0.9.30.1/luci-inteno-1.0.9/applications/luci-portforwarding

### Dir structure ###
    $ tree .
    .
    |-- luasrc
    |   |-- controller
    |   |   `-- wizard
    |   |       `-- wizard.lua
    |   |-- model
    |   |   `-- cbi
    |   |       `-- wizard
    |   |           `-- mylib.lua
    |   `-- view
    |       `-- wizard
    |           `-- view_tab.htm
    |-- Makefile
    `-- root
        `-- etc
            `-- config
                `-- preset
    
    11 directories, 5 files

### Compile it ###
    make

### Upload it to the router ###
    scp -r dist/* root@login:/

## Testing scenario ##
Enter the router ip address in browser:
    http://login.lan/

Select 
