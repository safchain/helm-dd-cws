#!/bin/bash

help()
{
   echo "Datadog Cloud Workload Security plugin"
   echo
   echo "Syntax: dd-cws [update-policy]"
   echo
   echo "options:"
   echo "update-policy     Download and update the policy."
   echo
}

case "$1" in
	update-policy)
		$HELM_PLUGIN_DIR/update.sh ${@:2}
		;;
	*)
		help
		;;
esac
