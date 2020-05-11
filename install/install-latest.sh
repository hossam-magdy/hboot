#!/bin/bash

# curl -sSL https://raw.github.com/hossam-magdy/hboot/master/install/install-latest.sh | sh

asset_path=$(curl -sL https://github.com/hossam-magdy/hboot/releases/latest | grep -o "/hossam-magdy/hboot/archive/.*\.tar.gz" | head -n 1)
# download_uri="https://github.com${asset_path}"
download_uri="https://github.com/hossam-magdy/hboot/archive/master.tar.gz"

release_file=$(basename $download_uri)
# release_version=$( echo ${release_file} | cut -d. -f1 )
release_version=${release_file%???????}
# echo $release_version

hboot_home=$HOME/.hboot
mkdir -p $hboot_home
cd "$hboot_home"
hboot_dir=$hboot_home/hboot-$release_version
hboot_installer=$hboot_dir/install/install.sh
hboot_gz=$hboot_dir.gz

echo "Downloading… $download_uri"
[ ! -f "$hboot_gz" ] && \
curl --fail --location --progress-bar --output "$hboot_gz" "$download_uri" || echo Already downloaded!
# rm "$exe.zip"

# unzip -o "$hboot_gz"
echo "Extracting to… $hboot_dir"
[ -d "$hboot_dir" ] && rm -rf $hboot_dir
mkdir -p $hboot_dir && tar --extract --file="$hboot_gz" --strip-components=1 --directory="$hboot_dir"

echo "Running installer …"
chmod +x $hboot_installer
$hboot_installer
