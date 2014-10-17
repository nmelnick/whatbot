#!/bin/sh

for module_name in whatbot whatbot*/ ; do
    cd $module_name
    make clean
    perl Makefile.PL
    make
    make test
    make install
    cd ..
done
