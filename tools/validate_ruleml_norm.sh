#!/bin/bash

SCRIPTDIR=$(dirname $0)
java -jar "${SCRIPTDIR}/jing/jing.jar" -c "${SCRIPTDIR}/datalogplus_min_normal.rnc" "$@"
