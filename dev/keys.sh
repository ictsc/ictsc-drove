#!/bin/bash

curl -sS https://raw.githubusercontent.com/ictsc/ictsc-github-member/production/terraform.tfstate |
  jq -r '.resources[] | select( .type == "github_team_members").instances[] | select( .index_key | contains ("ictsc2024") ).attributes.members[] | .username' |
  while read -r line; do curl -q "https://github.com/${line}.keys" | grep -e "ssh-" -e "ecdsa-" || true; done >./keys
