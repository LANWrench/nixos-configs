{ config, pkgs, lib, ... }:

{
  # Terminal status banner - shows service health on new terminal

  environment.systemPackages = [
    (pkgs.writeShellScriptBin "nixos-health" ''
      #!/usr/bin/env bash

      # Colors
      RED='\033[0;31m'
      GREEN='\033[0;32m'
      YELLOW='\033[1;33m'
      BLUE='\033[0;34m'
      NC='\033[0m'
      BOLD='\033[1m'

      # Track daily display
      TRACK_FILE="/tmp/nixos-health-$(whoami)-$(date +%Y%m%d)"
      SHOW_DETAILED=false

      # Check if this is first run today
      if [ ! -f "$TRACK_FILE" ]; then
        SHOW_DETAILED=true
        touch "$TRACK_FILE"
        # Clean up old tracking files
        find /tmp -name "nixos-health-$(whoami)-*" -type f -mtime +1 -delete 2>/dev/null || true
      fi

      # Force detailed view if requested
      if [ "$1" = "--force" ] || [ "$1" = "-f" ]; then
        SHOW_DETAILED=true
      fi

      # Gather system info
      failed_count=$(systemctl list-units --state=failed --no-legend --no-pager | wc -l)
      nixos_version=$(nixos-version | cut -d' ' -f1)
      generation=$(readlink /nix/var/nix/profiles/system | grep -oP 'system-\K[0-9]+' || echo "?")
      kernel=$(uname -r)

      # Get uptime (compatible method)
      uptime_seconds=$(cat /proc/uptime | cut -d' ' -f1 | cut -d'.' -f1)
      uptime_days=$((uptime_seconds / 86400))
      uptime_hours=$(( (uptime_seconds % 86400) / 3600 ))
      if [ "$uptime_days" -gt 0 ]; then
        uptime_info="''${uptime_days}d ''${uptime_hours}h"
      else
        uptime_info="''${uptime_hours}h"
      fi

      load_avg=$(uptime | grep -oP 'load average: \K[0-9.]+')

      # Memory info
      mem_total=$(free -h | awk '/^Mem:/ {print $2}')
      mem_used=$(free -h | awk '/^Mem:/ {print $3}')
      mem_percent=$(free | awk '/^Mem:/ {printf "%.0f", $3/$2 * 100}')

      # Disk info
      disk_info=$(df -h / | awk 'NR==2 {print $3"/"$2" ("$5")"}')

      # Check for pending reboot (kernel updated)
      current_kernel=$(uname -r)
      booted_kernel=$(readlink /run/booted-system/kernel | grep -oP 'linux-\K[^/]+' || echo "$current_kernel")
      reboot_needed=false
      if [ "$current_kernel" != "$booted_kernel" ]; then
        reboot_needed=true
      fi

      # Backup status - when did it last run?
      backup_status="never run"
      backup_age=0
      # Try service timestamps (populated while service is running or shortly after)
      for _prop in InactiveEnterTimestamp ActiveEnterTimestamp; do
        _ts=$(systemctl show restic-backups-fullMachine.service -p "$_prop" --value 2>/dev/null)
        if [ -n "$_ts" ] && [ "$_ts" != "n/a" ]; then
          backup_age=$(date -d "$_ts" +%s 2>/dev/null || echo "0")
          break
        fi
      done
      # Fallback: timer LastTriggerUSec (human-readable timestamp, persists across reboots)
      if [ "$backup_age" -eq 0 ]; then
        _ts=$(systemctl show restic-backups-fullMachine.timer -p LastTriggerUSec --value 2>/dev/null)
        if [ -n "$_ts" ] && [ "$_ts" != "n/a" ]; then
          backup_age=$(date -d "$_ts" +%s 2>/dev/null || echo "0")
        fi
      fi
      now=$(date +%s)
      if [ "$backup_age" -gt 0 ]; then
        hours_ago=$(( (now - backup_age) / 3600 ))
        if [ "$hours_ago" -lt 24 ]; then
          backup_status="''${hours_ago}h ago"
        else
          days_ago=$(( hours_ago / 24 ))
          backup_status="''${days_ago}d ago"
        fi
      fi

      # Snapshot status - when did it last run?
      snapshot_status="never run"
      snap_age=0
      # Try service timestamps
      for _prop in InactiveEnterTimestamp ActiveEnterTimestamp; do
        _ts=$(systemctl show snapper-timeline.service -p "$_prop" --value 2>/dev/null)
        if [ -n "$_ts" ] && [ "$_ts" != "n/a" ]; then
          snap_age=$(date -d "$_ts" +%s 2>/dev/null || echo "0")
          break
        fi
      done
      # Fallback: parse snapper list (user has access via ALLOW_USERS config)
      if [ "$snap_age" -eq 0 ]; then
        _snap_date=$(snapper -c home list 2>/dev/null | tail -1 | awk -F'│' '{gsub(/^[[:space:]]+|[[:space:]]+$/, "", $4); print $4}')
        if [ -n "$_snap_date" ]; then
          snap_age=$(date -d "$_snap_date" +%s 2>/dev/null || echo "0")
        fi
      fi
      now=$(date +%s)
      if [ "$snap_age" -gt 0 ]; then
        hours_ago=$(( (now - snap_age) / 3600 ))
        if [ "$hours_ago" -lt 24 ]; then
          snapshot_status="''${hours_ago}h ago"
        else
          days_ago=$(( hours_ago / 24 ));
          snapshot_status="''${days_ago}d ago"
        fi
      fi

      # Check for available flake updates
      updates_available="unknown"
      if [ -f "$HOME/nix-config/flake.lock" ]; then
        # Check if flake.lock is older than 7 days
        lock_age_days=$(find "$HOME/nix-config/flake.lock" -mtime +7 2>/dev/null | wc -l)
        if [ "$lock_age_days" -gt 0 ]; then
          lock_days=$(( ($(date +%s) - $(stat -c %Y "$HOME/nix-config/flake.lock" 2>/dev/null || echo 0)) / 86400 ))
          updates_available="$lock_days days since last update"
        fi
      fi

      # DETAILED VIEW (first of day or --force)
      if [ "$SHOW_DETAILED" = true ]; then
        echo ""
        echo "Welcome to NixOS $nixos_version ($(uname -m))"
        echo ""
        echo "  System information as of $(date '+%a %b %d %H:%M:%S %Y')"
        echo ""

        # System information
        echo "  System load:    $load_avg"
        echo "  Usage of /:     $disk_info"
        echo "  Memory usage:   $mem_used/$mem_total ($mem_percent%)"
        echo "  Processes:      $(ps aux | wc -l)"
        echo "  Uptime:         $uptime_info"
        echo "  Kernel:         $kernel"
        echo "  NixOS version:  $nixos_version"
        echo "  Generation:     $generation"
        echo ""

        # Backup and snapshot status
        echo "  Last backup:    $backup_status"
        echo "  Last snapshot:  $snapshot_status"

        # Update status
        if [ "$updates_available" != "unknown" ]; then
          echo -e "  ''${YELLOW}Updates:        $updates_available''${NC}"
        fi
        echo ""

        # Failed services
        if [ "$failed_count" -gt 0 ]; then
          echo -e "  ''${RED}$failed_count failed service(s)''${NC}"
          systemctl list-units --state=failed --no-legend --no-pager | head -5 | while read line; do
            service=$(echo "$line" | awk '{print $1}')
            echo "   * $service"
          done
          if [ "$failed_count" -gt 5 ]; then
            echo "   ... and $((failed_count - 5)) more"
          fi
          echo ""
        fi

        # Warnings/actions needed
        warnings=false

        if [ "$reboot_needed" = true ]; then
          echo -e "  ''${YELLOW}*** System restart required ***''${NC}"
          warnings=true
        fi

        if [ "$updates_available" != "unknown" ]; then
          echo -e "  ''${YELLOW}*** Run 'nix flake update' to update system inputs ***''${NC}"
          warnings=true
        fi

        if [ "$warnings" = true ]; then
          echo ""
        fi
      else
        # MINIMAL VIEW (rest of day) - only show if there are issues
        issues_list=()

        if [ "$failed_count" -gt 0 ]; then
          issues_list+=("''${RED}$failed_count failed services''${NC}")
        fi

        if [ "$reboot_needed" = true ]; then
          issues_list+=("''${YELLOW}reboot required''${NC}")
        fi

        if [ "$updates_available" != "unknown" ]; then
          issues_list+=("''${YELLOW}updates available''${NC}")
        fi

        # Only show if there are issues
        if [ ''${#issues_list[@]} -gt 0 ]; then
          echo ""
          echo -e "  System alerts: ''${issues_list[*]}"
          echo "  Run 'nixos-health --force' for details"
          echo ""
        fi
      fi
    '')
  ];
}
