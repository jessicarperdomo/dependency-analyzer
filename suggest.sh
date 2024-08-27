#!/bin/bash
set +x

# Setting some required variables
BITO_CMD=`which bito`
BITO_CMD_VEP=""
BITO_VERSION=`$BITO_CMD -v | awk '{print $NF}'`

# Compare BITO_VERSION to check if its greater than 3.7
if awk "BEGIN {exit !($BITO_VERSION > 3.7)}"; then
	BITO_CMD_VEP="--agent create_code_doc"
fi

# Check if folder name is provided as command line argument
if [ $# -eq 0 ]; then
    echo "Please provide folder name as command line argument"
    exit 1
fi

# Get folder name from command line argument
folder=$1

# Check if folder exists
if [ ! -d "$folder" ]; then
    echo "Folder $folder does not exist"
    exit 1
fi

# Check if package.json exists in the folder
if [ ! -f "$folder/package.json" ]; then
    echo "package.json does not exist in the folder $folder"
    exit 1
fi

# Change to the specified folder
cd $folder

# Run npm-check-updates to check for outdated dependencies
echo "Checking for outdated dependencies in $folder"
ncu > ncu_output.txt

# Use Bito to explain what was done
explanation_file="dependency_update_explanation.md"
echo "Generating explanation using Bito in $explanation_file"
# Change to out folder
cd ..
cat "$folder/ncu_output.txt" | bito -p ./promps/explain_ncu_output.txt $BITO_CMD_VEP > $explanation_file

echo "Outdated dependencies checked. Explanation saved in $explanation_file"