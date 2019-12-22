# New provider request

Replace dummy API/UI names with your proposed provider names.

## Name in API

`dummy_vpn`

## Name in UI

`DummyVPN`

## Insight

Technically describe how this PR generates the infrastructure of the VPN provider.

## Checklist

- [ ] The VPN provider is aware of this integration
- [ ] I added a new map to `providers/index.json` with the following fields:
	- `name`: alphanumeric or underscore, lowercase, without spaces, e.g. `dummy_vpn`
	- `description`: as seen in the apps, e.g. `DummyVPN`
- [ ] I cloned my provider implementation in `api-source-<name>` from `api-source-sample`, where `name` is 100% equal to the provider `name` field in `index.json`
- [ ] I added a submodule in `providers/<name>` pulling from my `api-source-<name>` repository
- [ ] My `net.sh` script in `api-source-<name>` generates a proper JSON according to the [syntax described here][1]

[1]: https://github.com/passepartoutvpn/api-source-sample/blob/master/scripts/README
