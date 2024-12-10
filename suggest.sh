#!/bin/bash
set -e  # Exit immediately if a command exits with a non-zero status

# Function to compare versions
version_gt() {
    # Compare versions in X.Y format
    printf '%s\n%s' "$1" "$2" | sort -V | head -n1 | grep -qx "$2"
}

# Check if `bito` and `ncu` are installed
if ! command -v bito &> /dev/null; then
    echo "Error: bito is not installed."
    exit 1
fi

if ! command -v ncu &> /dev/null; then
    echo "Error: ncu is not installed."
    exit 1
fi

# Get the version of bito
BITO_CMD=$(which bito)
BITO_VERSION=$($BITO_CMD -v | awk '{print $NF}')

# Compare BITO version
if version_gt "$BITO_VERSION" "3.7"; then
    BITO_CMD_VEP="--agent create_code_doc"
else
    BITO_CMD_VEP=""
fi

# Check if a folder name is provided
if [ $# -eq 0 ]; then
    echo "Error: You must provide the folder name as an argument."
    exit 1
fi

# Get the folder name from the argument
folder="$1"

# Check if the folder exists
if [ ! -d "$folder" ]; then
    echo "Error: The folder $folder does not exist."
    exit 1
fi

# Check if package.json exists in the folder
if [ ! -f "$folder/package.json" ]; then
    echo "Error: package.json does not exist in the folder $folder."
    exit 1
fi

# Change to the specified folder
cd "$folder"

# Run `npm-check-updates` to check for outdated dependencies
echo "Checking outdated dependencies in $folder..."
ncu > ncu_output.txt

# Run `npm audit` and redirect output
echo "Checking for vulnerabilities in $folder..."
npm audit --json > npm_audit_output.json || true 

# Check if the prompt file exists
if [ ! -f "../promps/explain_ncu_output.txt" ]; then
    echo "Error: The input file for Bito does not exist in ../promps/explain_ncu_output.txt."
    exit 1
fi

# Check if bito is installed
if ! command -v bito &> /dev/null; then
    echo "Error: bito is not installed."
    exit 1
fi
# Generate explanation using Bito
explanation_file="../dependency_update_explanation.md"
echo "Generating explanation using Bito in $explanation_file..."
if [ ! -f "../promps/explain_ncu_output.txt" ]; then
    echo "Error: The input file for Bito does not exist in ../promps/explain_ncu_output.txt."
    exit 1
fi

# Concatenate outputs and pipe to Bito
cat ncu_output.txt  | bito -p ../promps/explain_ncu_output.txt $BITO_CMD_VEP > "$explanation_file"

echo "Outdated dependencies checked. Explanation saved in $explanation_file."

#dfsdfd

# Generate a summary of vulnerabilities
vulnerabilities_summary="../vulnerabilities_summary.md"
if [ ! -f "../promps/explain_audit_output.txt" ]; then
    echo "Error: The input file for Bito does not exist in ../promps/explain_audit_output.txt."
    exit 1
fi

if [ -s npm_audit_output.json ]; then
    # Concatenate outputs and pipe to Bito
    cat npm_audit_output.json  | bito -p ../promps/explain_audit_output.txt $BITO_CMD_VEP > "$vulnerabilities_summary"

    echo "Outdated dependencies checked. Explanation saved in $vulnerabilities_summary."
else
    echo "No vulnerabilities found."
fi