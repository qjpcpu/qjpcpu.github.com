#!/bin/bash
set -eu
rake generate
rake deploy
git add .
git commit -m "Auto commit.`date '+%Y/%m/%d %H:%M:%S'`"
git push -u origin source
