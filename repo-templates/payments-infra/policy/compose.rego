# Repo policies for docker compose files, checked by conftest.
#   conftest test --policy policy/ docker-compose.yml
# deny = blocks the commit, warn = printed but passes.
package main

import rego.v1

# Publishing a port without a host IP binds 0.0.0.0. Docker writes its own
# iptables rules, which bypass UFW, so the port is public even if UFW blocks it.
deny contains msg if {
	some name, svc in input.services
	some port in svc.ports
	is_string(port)
	not startswith(port, "127.0.0.1:")
	msg := sprintf("%s: port \"%s\" is published on all interfaces; use \"127.0.0.1:%s\" or an internal network", [name, port, port])
}

deny contains msg if {
	some name, svc in input.services
	some port in svc.ports
	is_number(port)
	msg := sprintf("%s: port %v is published on all interfaces; use \"127.0.0.1:%v:%v\" or an internal network", [name, port, port, port])
}

# Long syntax: ports: [{target: 5432, published: 5432, host_ip: 127.0.0.1}]
deny contains msg if {
	some name, svc in input.services
	some port in svc.ports
	is_object(port)
	object.get(port, "host_ip", "") != "127.0.0.1"
	msg := sprintf("%s: port %v is published without host_ip: 127.0.0.1", [name, object.get(port, "target", "?")])
}

deny contains msg if {
	some name, svc in input.services
	svc.privileged == true
	msg := sprintf("%s: privileged containers can take over the host", [name])
}

# Literal secret values in compose end up in git history. Map-form environment only.
deny contains msg if {
	some name, svc in input.services
	some key, value in svc.environment
	is_string(key)
	is_string(value)
	regex.match(`(SECRET|PASSWORD|PASSWD|TOKEN|API_?KEY|PRIVATE_?KEY|MNEMONIC|SEED)`, upper(key))
	value != ""
	not startswith(value, "${")
	msg := sprintf("%s: %s has a literal value; load it from an env file or a secret", [name, key])
}

warn contains msg if {
	some name, svc in input.services
	tag_part := last_segment(svc.image)
	not contains(tag_part, ":")
	not contains(tag_part, "@")
	msg := sprintf("%s: image \"%s\" has no tag, so it means :latest; pin a version or digest", [name, svc.image])
}

warn contains msg if {
	some name, svc in input.services
	endswith(svc.image, ":latest")
	msg := sprintf("%s: image \"%s\" uses :latest; pin a version or digest", [name, svc.image])
}

last_segment(img) := seg if {
	parts := split(img, "/")
	seg := parts[count(parts) - 1]
}
