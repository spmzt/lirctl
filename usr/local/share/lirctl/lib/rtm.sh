#!/bin/sh

# Drop invalid
# Note: This route-map must be called by other route-maps
invalid_rtm_get() {
  echo "route-map RTM_INVALID_DENY deny 1
 description Drop Invalid RPKI
 match rpki invalid
exit
!
route-map RTM_INVALID_DENY deny 2
 description Drop IPv6 Bogon Prefixlist
 match ipv6 address prefix-list PFL_BOGON
exit
!
route-map RTM_INVALID_DENY deny 3
 description Drop IPv4 Bogon Prefixlist
 match ip address prefix-list PFL_V4_BOGON
exit
!
route-map RTM_INVALID_DENY deny 4
 description Drop Bogon AS Path
 match as-path BOGON_REV_ASN
exit
!
route-map RTM_INVALID_DENY permit 99
 description call by other route-maps, permit anything
exit"
}

# Generate import route-map from $1 based on being our upstream or not $2
in_rtm_get() {
  if [ "$2" = "True" ]; then
    UPSTREAM_ASN_LINE="ASP_ANY"
    UPSTREAM_IPV6_LINE="PFL_ANY"
  elif [ "$2" = "False" ]; then
    UPSTREAM_ASN_LINE="IMPORT_ASN_FROM_$1"
    UPSTREAM_IPV6_LINE="IMPORT_IPV6_FROM_$1"
  else
    echo "lirctl -> Error: Upstream values in peer $1 should be yes or no"
    exit 1
  fi
  
  invalid_rtm_get
  echo

  echo "route-map IMPORT_RTMV6_FROM_$1 permit 1
 call RTM_INVALID_DENY
 description Drop Invalid Prefixes
 on-match next
exit
!
route-map IMPORT_RTMV6_FROM_$1 permit 10
 description Import any valid RPKI from $1
 match rpki valid
 match ipv6 address prefix-list $UPSTREAM_IPV6_LINE
 match as-path $UPSTREAM_ASN_LINE
 match as-path BOGON_ASN
 set local-preference 30
exit
!
route-map IMPORT_RTMV6_FROM_$1 permit 20
 description Import any prefix that not found in RPKI db from $1 with lower pref
 match rpki notfound
 match ipv6 address prefix-list $UPSTREAM_IPV6_LINE
 match as-path $UPSTREAM_ASN_LINE
 match as-path BOGON_ASN
 set local-preference 20
exit
!
route-map IMPORT_RTMV6_FROM_$1 deny 99
 description Reject any prefix from $1
 match ipv6 address prefix-list PFL_ANY
exit"
}

# Generate export route-map to $1
out_rtm_get() {
  echo "route-map EXPORT_RTMV6_TO_$1 permit 1
 call RTM_INVALID_DENY
 description Drop Invalid Prefixes
 on-match next
exit
!
route-map EXPORT_RTMV6_TO_$1 deny 2
 description Drop Bogon Prefixlist
 match ipv6 address prefix-list BOGON_v6
exit
!
route-map EXPORT_RTMV6_TO_$1 deny 3
 description Drop Bogon AS Path
 match as-path BOGON_REV_ASN
exit
!
route-map EXPORT_RTMV6_TO_$1 permit 10
 description Export netwroks with valid RPKI
 match ipv6 address prefix-list EXPORT_IPV6_FROM_AS$MY_ASN
 match ipv6 address prefix-list EXPORT_IPV6_NETWORK
 match rpki valid
exit
!
route-map EXPORT_RTMV6_TO_$1 deny 99
 description Export netwroks with specific BGP attributes
 match ipv6 address prefix-list PFL_ANY
exit"
}

