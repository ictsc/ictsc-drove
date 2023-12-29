#!/bin/sh

git clone https://github.com/kubernetes/autoscaler.git --depth 1
./autoscaler/vertical-pod-autoscaler/hack/vpa-up.sh
rm -rf autoscaler
