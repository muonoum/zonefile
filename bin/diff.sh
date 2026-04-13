#!/usr/bin/env bash
set -eu

zone=$1
dir=$2
file=$3
base=$(basename "$file")

mkdir -p .checkzone
gleam run -- "$dir/$file" >".checkzone/$base--parsed"
named-checkzone -w "$dir" -i none -D "$zone" "$file" >".checkzone/$base--checkzone"
named-checkzone -w "$dir" -i none -D "$zone" <(cat ".checkzone/$base--parsed") >".checkzone/$base--parsed--checkzone"
diff ".checkzone/$base--checkzone" ".checkzone/$base--parsed--checkzone"
rm -r .checkzone
