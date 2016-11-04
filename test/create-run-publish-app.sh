#!/usr/bin/env bash
set -e  # Exit immediately upon failure

: ${1?"Need to pass sandbox directory as argument"}
: ${2?"Need to pass sdk image tag as argument"}

cd $1

echo "Testing framework-dependent deployment"
dotnet new

if [[ $2 == "1.1"* ]]; then
    replacement_arg="s/1.0.1/1.1.0/"

    if [[ $2 == *"projectjson"* ]]; then
        sed -i ${replacement_arg} ./project.json
    else
        sed -i ${replacement_arg} ./${PWD##*/}.csproj
    fi

    cp /test/NuGet.Config .    
fi

dotnet restore
dotnet run
dotnet publish -o publish/framework-dependent


echo "Testing self-contained deployment"
if [[ $2 == *"projectjson"* ]]; then
    runtimes_section="  },\n  \"runtimes\": {\n    \"debian.8-x64\": {}\n  }"
    sed -i '/"type": "platform"/d' ./project.json
    sed -i "s/^  }$/${runtimes_section}/" ./project.json

    dotnet restore
    dotnet run
    dotnet publish -o publish/self-contained
else
    sed -i '/<PropertyGroup>/a \    <RuntimeIdentifiers>debian.8-x64<\/RuntimeIdentifiers>' ./${PWD##*/}.csproj

    dotnet restore
    dotnet publish -r debian.8-x64 -o publish/self-contained
fi
