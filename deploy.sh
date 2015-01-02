#!/bin/bash
set -eu
(cd _deploy && git pull -u origin master)
bundle exec rake generate
bundle exec rake deploy
git pull -u origin source
git add -A
git commit -m "Auto commit.`date '+%Y/%m/%d %H:%M:%S'`"
git push -u origin source
