#!/bin/sh

cron_usage()
{
    cat << EOF
Usage:
  manrsctl cron COMMAND

Available Commands:
    update		only updates the filters, including as path lists, ipv6 prefix lists, route-maps.
    bogon       only updates the bogon filters, including as path lists, ipv6 prefix lists.
    edrop       only updates the edrop as path lists.

Use "manrsctl -v|--version" for version information.
EOF
    exit 1
}

cron_bogon()
{
    bogon_asp_list
    bogon_pfl_list
}

cron_edrop() {
    edrop_asp_get
}

cron_update()
{
    # Should be first due to value validation
    myself_out_pfl_get
    echo !

    cron_bogon

    cron_edrop

    dynamic_ass_pfl_get

    dynamic_ass_asp_get
}
