#!/bin/bash

selfdir=$(dirname $0)
s=$1
o=$2

if [ $# -lt 2 ]
then
  shift $#
else
  shift 2
fi

if [ $o ]
then
  java -jar "${selfdir}/saxonHE9-6-0-1j/saxon9he.jar" -xsl:"${selfdir}/101_nafneghornlogeq_normalizer.xslt" -s:"$s" -o:"$o" "$@"
else
  java -jar "${selfdir}/saxonHE9-6-0-1j/saxon9he.jar" -xsl:"${selfdir}/101_nafneghornlogeq_normalizer.xslt" -s:"$s" "$@"
fi
