#!/bin/sh

for module_name in whatbot \
                   whatbot-Command-Annoying \
                   whatbot-Command-Bitcoin \
                   whatbot-Command-Blackjack \
                   whatbot-Command-Excuse \
                   whatbot-Command-Market \
                   whatbot-Command-Nickometer \
                   whatbot-Command-PageRank \
                   whatbot-Command-Paste \
                   whatbot-Command-Quote \
                   whatbot-Command-RSS \
                   whatbot-Command-Trade \
                   whatbot-Command-Translate \
                   whatbot-Command-Weather \
                   whatbot-IO-AIM \
                   whatbot-IO-Jabber; do
    cd $module_name
    make clean
    perl Makefile.PL
    make
    make test
    make install
    cd ..
done