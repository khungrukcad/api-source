#!/bin/sh
API="gen"
rm -rf $API
git clone --depth 1 https://github.com/passepartoutvpn/api $API
bundle exec ruby generate.rb $*
