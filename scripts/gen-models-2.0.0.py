#!/usr/bin/env python3

# read-spgw-configs.py - read in live SPGW configuration and convert to ROC models

import json
import uuid
import sys

def gen_flat_models(config_dict, section, target, prefix = ""):
	profiles = []
	for id in config_dict[section]:
		profile = { "id": id, "description": "", "display-name": "" }
		for k, v in config_dict[section][id].items():
			profile[k] = v
		profiles.append(profile)

	models = {
		target: profiles
	}

	models_json = json.dumps(models)
	f = open(prefix + section.rstrip("s") + ".json", "w")
	f.write(models_json)
	f.close()

def gen_subscriber_models(config_dict, prefix = ""):
	subscriber_rules = []
	for r in config_dict["subscriber-selection-rules"]:
		rule = {
			"display-name": "",
			"enabled": True,
			"enterprise": "",
			"id": str(uuid.uuid4()),
			"priority": r["priority"],
			"Profiles": {
				"apn-profile": r["selected-apn-profile"],
				"qos-profile": r["selected-qos-profile"],
				"security-profile": "",
				"up-profile": r["selected-user-plane-profile"]
			}
		}

		if "imsi-range" in r["keys"]:
			rule["imsi-range-from"] = r["keys"]["imsi-range"]["from"]
			rule["imsi-range-to"] = r["keys"]["imsi-range"]["to"]
		elif "match-all" in r["keys"]:
			rule["imsi-wildcard"] = "*"

		if "serving-plmn" in r["keys"]:
			rule["Serving-plmn"] = r["keys"]["serving-plmn"]

		access_profiles = []
		for ap in r["selected-access-profile"]:
			access_profiles.append({
				"access-profile": ap,
				"allowed": True
				})
		rule["Profiles"]["Access-profile"] = access_profiles
		subscriber_rules.append(rule)

	models = {
		"Ue": subscriber_rules
	}

	section = "subscribers"
	models_json = json.dumps(models)
	f = open(prefix + section.rstrip("s") + ".json", "w")
	f.write(models_json)
	f.close()

# Read subscriber_mapping.json from stdin
config = sys.stdin.read()
config_dict = json.loads(config)

# Pre-processing for APN profiles
apn_profiles = {}
for k, v in config_dict["apn-profiles"].items():
	apn_profiles[k] = v.copy()
	for k2, v2 in v.items():
		if "_" in k2:
			newkey = k2.replace("_", "-")
			apn_profiles[k][newkey] = v[k2]
			del apn_profiles[k][k2]
config_dict["apn-profiles"] = apn_profiles

# Pre-processing for QOS profiles
for k, v in config_dict["qos-profiles"].items():
	config_dict["qos-profiles"][k]["Apn-ambr"] = {
		"uplink": v["apn-ambr"][0], 
		"downlink": v["apn-ambr"][1]
	}
	del config_dict["qos-profiles"][k]["apn-ambr"]

gen_flat_models(config_dict, "access-profiles", "Access-profile", "1-")
gen_flat_models(config_dict, "apn-profiles", "Apn-profile", "2-")
gen_flat_models(config_dict, "qos-profiles", "Qos-profile", "3-")
gen_flat_models(config_dict, "user-plane-profiles", "Up-profile", "5-")
gen_subscriber_models(config_dict, "8-")
