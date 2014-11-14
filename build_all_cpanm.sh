#!/bin/sh

cpanm --prompt Module::Install
for module_name in Whatbot Whatbot-*/ ; do
    cd $module_name
    rm Makefile
    cpanm --prompt .
    cd ..
done
