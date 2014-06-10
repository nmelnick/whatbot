#!/bin/sh

cpanm --prompt Module::Install
for module_name in whatbot \
                   whatbot-Helper-Bootstrap \
                   whatbot-Command-Annoying \
                   whatbot-Command-Bitcoin \
                   whatbot-Command-Blackjack \
                   whatbot-Command-Dogecoin \
                   whatbot-Command-Excuse \
                   whatbot-Command-Market \
                   whatbot-Command-Nickometer \
                   whatbot-Command-PageRank \
                   whatbot-Command-Paste \
                   whatbot-Command-Quote \
                   whatbot-Command-RSS \
                   whatbot-Command-Translate \
                   whatbot-Command-Weather \
                   whatbot-IO-AIM \
                   whatbot-IO-Jabber; do
    cd $module_name
    rm Makefile
    cpanm --prompt .
    cd ..
done
