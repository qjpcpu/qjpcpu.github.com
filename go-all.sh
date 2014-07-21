#!/bin/bash
set -eu
bundle exec rake generate
bundle exec rake deploy
git add .
git commit -m "Auto commit.`date '+%Y/%m/%d %H:%M:%S'`"
git push -u origin source
