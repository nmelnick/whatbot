#!/bin/sh

cpanm --prompt Module::Install
for module_name in Whatbot Whatbot-*/ ; do
    cd $module_name
    if [ -e Makefile ]; then
    	rm Makefile
    fi
    cpanm -n --installdeps .
    cd ..
done
