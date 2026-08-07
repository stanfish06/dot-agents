#!/usr/bin/env sh 

# add kitesurf broser to claude
claude mcp add --transport stdio kitesurf \
  -- npx -y chrome-devtools-mcp@latest \
  --wsEndpoint='wss://api.cloudflare.com/client/v4/accounts/b4450c514309783b556bced87a544d36/browser-run/devtools/browser?browser=kitesurf' \
  --wsHeaders="{\"Authorization\":\"Bearer $CF_API_TOKEN\"}"
