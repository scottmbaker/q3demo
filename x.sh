#!/bin/bash
MPATH=demo-rest-2.0.0-4g
aether-post-internal connectivity-services $MPATH/0100-connectivity-service.json
aether-post-internal enterprises $MPATH/0200-enterprise.json
aether-post-internal enterprises $MPATH/0250-traffic-class.json
aether-post-internal enterprises $MPATH/0300-application.json
aether-post-internal enterprises $MPATH/0800-site.json
aether-post-internal enterprises $MPATH/0450-upf.json
aether-post-internal enterprises $MPATH/0550-ip-domain.json
aether-post-internal enterprises $MPATH/0700-simcard.json
aether-post-internal enterprises $MPATH/0750-device.json
aether-post-internal enterprises $MPATH/0850-device-group.json
aether-post-internal enterprises $MPATH/0900-template.json
aether-post-internal enterprises $MPATH/1000-slice.json

#aether-post-internal enterprises/aib4gent/traffic-class $MPATH/0250-traffic-class.json
#aether-post-internal application $MPATH/0300-application.json
#aether-post-internal site $MPATH/0800-site.json
#aether-post-internal upf $MPATH/0450-upf.json
#aether-post-internal ip-domain $MPATH/0550-ip-domain.json
#aether-post-internal device-group $MPATH/0850-device-group.json
#aether-post-internal template $MPATH/0900-template.json
#aether-post-internal vcs $MPATH/1000-vcs.json
