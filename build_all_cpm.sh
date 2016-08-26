#!/bin/sh

echo 'This will also install the Whatbot modules as well as dependencies, globally.'
cpm install -g Module::Install
for module_name in Whatbot Whatbot-*/ Whatbot-IO-HipChat ; do
	echo $module_name
    cd $module_name
    if [ -e Makefile ]; then
    	rm Makefile
    fi
    perl Makefile.PL
    cpm install -g .
    cd ..
done
