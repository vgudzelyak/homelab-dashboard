#!/bin/bash

echo "Content-type: text/plain"
echo ""

CMD=$(echo "$QUERY_STRING" | sed -n 's/^.*cmd=\([^&]*\).*$/\1/p')

case "$CMD" in
  "mikrotik-set-isp1")
    ssh admin@router.lan "/system script run ISP1-distance-1"
    echo "Done"
    ;;
  "mikrotik-set-isp2")
    ssh admin@router.lan "/system script run ISP1-distance-3"
    echo "Done"
    ;;
  *)
    echo "Unknown command"
    ;;
esac