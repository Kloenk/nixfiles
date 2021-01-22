#!/usr/bin/env bash
set -euo pipefail

cd $(dirname $0)/..


for i in $(cat ./lib/hosts)
do
    hostname=$(ssh $i "hostname")
    echo $hostname
    ssh $i "sudo sh -c 'rm -rf /root/.gnupg/*'"
    cat lib/keygen | sed "s/NAME/${hostname}/" | ssh -o RequestTTY=yes $i "sudo gpg --generate-key --pinentry-mode loopback --batch /dev/stdin"
    cp ./secrets/.gpg-id ./secrets/$hostname/.gpg-id
    ssh $i "sudo -u root gpg --fingerprint --with-colons | grep '^fpr' | head -n1 | cut -d: -f10" >> ./secrets/$hostname/.gpg-id
    ssh $i "sudo -u root gpg --export --armor" > ./secrets/.public-keys/$hostname
    lib/pass.sh init -p $hostname $(cat ./secrets/$hostname/.gpg-id);
done