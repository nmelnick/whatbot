#!/bin/sh

echo 'This will also install the Whatbot modules as well as dependencies, globally. Press enter to continue.'
read -p "" F
cpm install -g Module::Install
for module_name in Whatbot Whatbot-*/ ; do
	echo $module_name
    cd $module_name
    if [ -e Makefile ]; then
    	rm Makefile
    fi
    cpm install -g .
    cd ..
done
