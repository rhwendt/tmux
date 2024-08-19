#!/usr/bin/env bash
# setting the locale, some users have issues with different locales, this forces the correct one
export LC_ALL=en_US.UTF-8

current_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source $current_dir/utils.sh

vpn_function() {
  case $(uname -s) in
  Linux)
    #Show IP of tun0 if connected
    vpn=$(ip -o -4 addr show dev tun0 | awk '{print $4}' | cut -d/ -f1)

    if [[ $vpn =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
      echo $vpn
    else
      echo "NO VPN"
    fi
  ;;

  Darwin)

    verbose=$(get_tmux_option "@dracula-network-vpn-verbose" false)

    vpn="$(scutil --nc list | sed "s/\*//g" | grep Connected)"

    is_not_tailscale=$(echo "$vpn" | grep -v Tailscale)

    which -s tailscale > /dev/null
    tailscale_installed=$?

    if [ -z "$vpn" ]; then
      echo ""

    elif [ $tailscale_installed ] && [ -z "$is_not_tailscale" ]; then
      # if tailscale is installed and no other vpn is connected. this is because tailscale will
      # always show as connected for some reason.
      #
      # https://www.reddit.com/r/Tailscale/comments/18dirro/is_there_a_way_i_can_tell_which_exit_node_i_am/
      node=$(tailscale status --peers --json | jq '.ExitNodeStatus')
      if [[ -z $node ]] || [[ "$node"  == 'null' ]]; then
        # no tailscale exit node, no output, since trafic isnt actually rerouted
        echo ""
      else
        exitnode=$(tailscale status | grep "; exit node" | cut -w -f 2)

        if $verbose; then
          echo "󰌘 $exitnode"
        else
          echo "Tailscale"
        fi
      fi

    else
      if $verbose; then
        vpn_name=$(echo $is_not_tailscale | sed "s/.*\"\(.*\)\".*/\1/g")
        echo "󰌘 $vpn_name"
      else
        echo "VPN"
      fi
    fi
    ;;

  CYGWIN* | MINGW32* | MSYS* | MINGW*)
    # TODO - windows compatability
    ;;
  esac
}

main() {

  echo $(vpn_function)
}

# run main driver
main
