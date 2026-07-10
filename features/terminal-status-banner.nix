{ config, pkgs, lib, ... }:

{
  # Terminal status banner - shows service health on new terminal

  environment.systemPackages = [
    (pkgs.writeShellScriptBin "nixos-health" ''
      # Colors
      RED='\033[0;31m'
      GREEN='\033[0;32m'
      YELLOW='\033[1;33m'
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

      now=$(date +%s)

      # Last completed run of a service, falling back to its timer's last
      # trigger. Prints a unix epoch, or 0 if it has not run since boot.
      last_run_epoch() {
        local _ts _prop
        for _prop in InactiveEnterTimestamp ActiveEnterTimestamp; do
          _ts=$(systemctl show "$1" -p "$_prop" --value 2>/dev/null)
          if [ -n "$_ts" ] && [ "$_ts" != "n/a" ]; then
            if date -d "$_ts" +%s 2>/dev/null; then return; fi
          fi
        done
        _ts=$(systemctl show "$2" -p LastTriggerUSec --value 2>/dev/null)
        if [ -n "$_ts" ] && [ "$_ts" != "n/a" ]; then
          if date -d "$_ts" +%s 2>/dev/null; then return; fi
        fi
        echo 0
      }

      fmt_ago() {
        if [ "$1" -le 0 ]; then echo "never (since boot)"; return; fi
        local h=$(( (now - $1) / 3600 ))
        if [ "$h" -lt 1 ]; then
          echo "<1h ago"
        elif [ "$h" -lt 24 ]; then
          echo "''${h}h ago"
        else
          echo "$(( h / 24 ))d ago"
        fi
      }

      # Failed services - system and user
      mapfile -t failed_system < <(systemctl list-units --state=failed --plain --no-legend --no-pager 2>/dev/null | awk '{print $1}')
      mapfile -t failed_user < <(systemctl --user list-units --state=failed --plain --no-legend --no-pager 2>/dev/null | awk '{print $1}')
      failed_total=$(( ''${#failed_system[@]} + ''${#failed_user[@]} ))

      # Check for pending reboot: kernel of the current system generation
      # differs from the one we booted (uname -r always reports the booted
      # kernel, so compare the generation symlinks instead)
      reboot_needed=false
      current_kernel=$(readlink -f /run/current-system/kernel 2>/dev/null)
      booted_kernel=$(readlink -f /run/booted-system/kernel 2>/dev/null)
      if [ -n "$current_kernel" ] && [ "$current_kernel" != "$booted_kernel" ]; then
        reboot_needed=true
      fi

      # Backup / snapshot / auto-upgrade recency
      backup_epoch=$(last_run_epoch restic-backups-fullMachine.service restic-backups-fullMachine.timer)
      backup_status=$(fmt_ago "$backup_epoch")

      snap_epoch=$(last_run_epoch snapper-timeline.service snapper-timeline.timer)
      # Fallback: parse snapper list (user has access via ALLOW_USERS config)
      if [ "$snap_epoch" -eq 0 ]; then
        _snap_date=$(snapper -c home list 2>/dev/null | tail -1 | awk -F'│' '{gsub(/^[[:space:]]+|[[:space:]]+$/, "", $4); print $4}')
        if [ -n "$_snap_date" ]; then
          snap_epoch=$(date -d "$_snap_date" +%s 2>/dev/null || echo 0)
        fi
      fi
      snapshot_status=$(fmt_ago "$snap_epoch")

      upgrade_epoch=$(last_run_epoch nixos-upgrade.service nixos-upgrade.timer)
      upgrade_status=$(fmt_ago "$upgrade_epoch")
      upgrade_result=$(systemctl show nixos-upgrade.service -p Result --value 2>/dev/null)

      # Check for available flake updates (lock file older than 7 days)
      updates_available="unknown"
      _lock="$HOME/nix-config/flake.lock"
      if [ -f "$_lock" ]; then
        lock_days=$(( (now - $(stat -c %Y "$_lock" 2>/dev/null || echo "$now")) / 86400 ))
        if [ "$lock_days" -gt 7 ]; then
          updates_available="$lock_days days since last update"
        fi
      fi

      # --- Build the attention block ---
      alert_lines=()
      hint_lines=()

      for u in "''${failed_system[@]}"; do
        alert_lines+=("''${RED}✗ $u — failed''${NC}")
      done
      for u in "''${failed_user[@]}"; do
        alert_lines+=("''${RED}✗ $u — failed (user)''${NC}")
      done
      if [ "$failed_total" -eq 1 ]; then
        # Single failure: print copy-pasteable commands
        if [ "''${#failed_user[@]}" -eq 1 ]; then
          hint_lines+=("logs:   journalctl --user -eu ''${failed_user[0]}")
          hint_lines+=("status: systemctl --user status ''${failed_user[0]}")
        else
          hint_lines+=("logs:   journalctl -eu ''${failed_system[0]}")
          hint_lines+=("status: systemctl status ''${failed_system[0]}")
        fi
      elif [ "$failed_total" -gt 1 ]; then
        hint_lines+=("logs:   journalctl -eu <unit>   (add --user for user units)")
        hint_lines+=("status: systemctl status <unit>")
      fi

      # Daily backup >36h old (only when we have a timestamp - after a fresh
      # boot the timer hasn't fired yet and "never" would be a false alarm)
      if [ "$backup_epoch" -gt 0 ] && [ $(( (now - backup_epoch) / 3600 )) -gt 36 ]; then
        alert_lines+=("''${YELLOW}! backup overdue — last run $backup_status''${NC}")
        hint_lines+=("check:  journalctl -eu restic-backups-fullMachine.service")
      fi

      # Timeline snapshots >26h old
      if [ "$snap_epoch" -gt 0 ] && [ $(( (now - snap_epoch) / 3600 )) -gt 26 ]; then
        alert_lines+=("''${YELLOW}! snapshots overdue — last run $snapshot_status''${NC}")
        hint_lines+=("check:  journalctl -eu snapper-timeline.service")
      fi

      # Last auto-upgrade failed (skip if already listed as a failed unit)
      if [ "$upgrade_epoch" -gt 0 ] && [ -n "$upgrade_result" ] && [ "$upgrade_result" != "success" ]; then
        case " ''${failed_system[*]} " in
          *" nixos-upgrade.service "*) : ;;
          *)
            alert_lines+=("''${RED}! last auto-upgrade failed ($upgrade_result) — ran $upgrade_status''${NC}")
            hint_lines+=("logs:   journalctl -eu nixos-upgrade.service")
            ;;
        esac
      fi

      if [ "$reboot_needed" = true ]; then
        alert_lines+=("''${YELLOW}! reboot required — kernel updated since boot''${NC}")
        hint_lines+=("fix:    sudo reboot")
      fi

      if [ "$updates_available" != "unknown" ]; then
        alert_lines+=("''${YELLOW}! flake inputs stale — $updates_available''${NC}")
        hint_lines+=("fix:    cd ~/nix-config && nix flake update")
      fi

      # Filesystems at >=90% capacity (deduped by device: /, /home and
      # /backup are subvolumes of the same btrfs disk). Skips unmounted /
      # automount targets so we don't trigger a mount just to check.
      declare -A _seen_dev
      for mnt in / /home /backup /games /mnt/data; do
        fstype=$(findmnt -rn -o FSTYPE "$mnt" 2>/dev/null | tail -n1)
        if [ -z "$fstype" ] || [ "$fstype" = "autofs" ]; then continue; fi
        read -r dev pcent < <(df --output=source,pcent "$mnt" 2>/dev/null | tail -n1)
        if [ -z "$dev" ] || [ -n "''${_seen_dev[$dev]}" ]; then continue; fi
        _seen_dev[$dev]=1
        pct=''${pcent%\%}
        if [ "$pct" -ge 90 ] 2>/dev/null; then
          alert_lines+=("''${YELLOW}! $mnt at ''${pct}% capacity''${NC}")
        fi
      done

      print_alert_block() {
        local n=''${#alert_lines[@]} line
        [ "$n" -eq 0 ] && return
        echo ""
        if [ "$n" -eq 1 ]; then
          echo -e "  ''${BOLD}''${RED}⚠ 1 issue needs attention''${NC}"
        else
          echo -e "  ''${BOLD}''${RED}⚠ $n issues need attention''${NC}"
        fi
        for line in "''${alert_lines[@]}"; do
          echo -e "    $line"
        done
        for line in "''${hint_lines[@]}"; do
          echo -e "    ''${YELLOW}→ $line''${NC}"
        done
        echo ""
      }

      if [ "$SHOW_DETAILED" = true ]; then
        # DETAILED VIEW (first of day or --force)
        nixos_version=$(nixos-version | cut -d' ' -f1)
        generation=$(readlink /nix/var/nix/profiles/system | grep -oP 'system-\K[0-9]+' || echo "?")
        kernel=$(uname -r)

        uptime_seconds=$(cut -d' ' -f1 /proc/uptime | cut -d'.' -f1)
        uptime_days=$((uptime_seconds / 86400))
        uptime_hours=$(( (uptime_seconds % 86400) / 3600 ))
        if [ "$uptime_days" -gt 0 ]; then
          uptime_info="''${uptime_days}d ''${uptime_hours}h"
        else
          uptime_info="''${uptime_hours}h"
        fi

        load_avg=$(awk '{print $1}' /proc/loadavg)
        mem_total=$(free -h | awk '/^Mem:/ {print $2}')
        mem_used=$(free -h | awk '/^Mem:/ {print $3}')
        mem_percent=$(free | awk '/^Mem:/ {printf "%.0f", $3/$2 * 100}')
        disk_info=$(df -h / | awk 'NR==2 {print $3"/"$2" ("$5")"}')

        echo ""
        echo "Welcome to NixOS $nixos_version ($(uname -m))"

        if [ "''${#alert_lines[@]}" -gt 0 ]; then
          print_alert_block
        else
          echo ""
          echo -e "  ''${GREEN}✓ all services running''${NC}"
          echo ""
        fi

        echo "  System information as of $(date '+%a %b %d %H:%M:%S %Y')"
        echo ""
        echo "  System load:    $load_avg"
        echo "  Usage of /:     $disk_info"
        echo "  Memory usage:   $mem_used/$mem_total ($mem_percent%)"
        echo "  Processes:      $(ps -e --no-headers | wc -l)"
        echo "  Uptime:         $uptime_info"
        echo "  Kernel:         $kernel"
        echo "  NixOS version:  $nixos_version"
        echo "  Generation:     $generation"
        echo ""
        echo "  Last backup:    $backup_status"
        echo "  Last snapshot:  $snapshot_status"
        echo "  Last upgrade:   $upgrade_status"
        echo ""
      else
        # MINIMAL VIEW (rest of day) - full alert block, silent when healthy
        print_alert_block
      fi
    '')
  ];
}
