#!/bin/bash

cd dart/uber_challenge
pub install
cd ../../
find dart/ -type f -name 'main*.dart' -exec dart2js {} --enable-experimental-mirrors -o {}.js \;