{
  bash,
  jq,
  writeScriptBin,
  ...
}:

#
# the input format is specified in /specifications/translator-call-example.json

writeScriptBin "translate" ''
  #!${bash}/bin/bash

  set -Eeuo pipefail

  # accroding to the spec, the translator reads the input from a json file
  jsonInput=$1

  # extract the 'inputFiles' field from the json
  inputFiles=$(${jq}/bin/jq '.inputFiles | .[]' -c -r $jsonInput)
  outputFile=$(${jq}/bin/jq '.outputFile' -c -r $jsonInput)

  # prepare temporary directory
  tmp=translateTmp
  rm -rf $tmp
  mkdir $tmp

  # download files according to requirements
  $ TODO:

  # generate the generic lock from the downloaded list of files
  # check ./specifications/generic-lock-example.json
  # TODO: generate lock json into $outputFile

  rm -rf $tmp
''
