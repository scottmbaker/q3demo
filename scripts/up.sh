#!/bin/bash
HOST=node.smbaker-box.xos-pg0.utah.cloudlab.us

rsync -avz --exclude "__history" --exclude "*~" --exclude ".git" --exclude "sdran-helm-charts" --exclude "sdcore-adapter" -e ssh . smbaker@$HOST:/users/smbaker/q3demo
rsync -avz --exclude "__history" --exclude "*~" --exclude ".git" -e ssh ../sdran-helm-charts smbaker@$HOST:/users/smbaker/q3demo/
