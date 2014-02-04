#!/bin/sh

for module_name in whatbot \
                   whatbot-Command-Annoying \
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
                   whatbot-IO-AIM; do
    cd $module_name
    rm Makefile
    cpanm --prompt .
    cd ..
done
