#!/bin/sh
rm -rf gen
bundle exec ruby generate.rb $*
