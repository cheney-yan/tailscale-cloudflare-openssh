## GitHub Actions Setup

### Tailscale Cleanup Action

The repository includes a GitHub Action that runs daily to:
- Remove Tailscale devices that have been offline for more than 7 days
- Extend key expirations for devices expiring in the next 30 days

#### Required Secrets

Add these secrets to your GitHub repository (Settings > Secrets and variables > Actions):

1. `TAILSCALE_API_KEY`: Your Tailscale API key with device management permissions
   - Generate at: https://login.tailscale.com/admin/settings/keys
   - Required permissions: Devices (Read, Write, Delete)

2. `TAILNET`: Your Tailscale tailnet name (e.g., `example.com` or `tail12345.ts.net`)

#### Manual Trigger

You can manually trigger the cleanup action from the GitHub Actions tab in your repository.