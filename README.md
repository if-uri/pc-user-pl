# pc-user-pl — Jan Kowalski's personal computer

The **computer of an average citizen** in the isolated digital twin: a virtual
desktop (Xvfb + openbox + Chromium + noVNC) running a real `urirun` node with
the KVM connector, joined to the virtual internet and trusting its local CA — so
Chromium sees valid HTTPS on `mbank.pl` / `phone.jan.pl` just like the real web.
Everything Jan does is driven through the urirun mesh (`kvm://`, `app://`).

Trio: [net-user-pl](https://github.com/if-uri/net-user-pl) (network) · **pc-user-pl** (computer) · [mobile-user-pl](https://github.com/if-uri/mobile-user-pl) (phone). Orchestrated by `pc1`.

## Build

The desktop extends the `pc1-desktop:local` base image (built by the `pc1`
project). Because it derives from a local-only tag, use the legacy builder:

```bash
DOCKER_BUILDKIT=0 docker build -t pc-user-pl-desktop:local desktop
```

## Run

Needs net-user-pl up (creates `netpl` and the CA under `../net-user-pl/ca/out`):

```bash
docker network create netpl                      # idempotent
docker compose -f compose.pc.yml up -d
# watch Jan work live:
xdg-open http://127.0.0.1:26080/vnc.html
```

The node is reachable at `http://127.0.0.1:28765` for `urirun host add-node`.

## What it adds over the base desktop

- installs the net-user-pl root CA into the system store **and** Chromium's NSS
  db (so HTTPS validates with no warning) — see `desktop/setup-ca.sh`;
- joins the `netpl` network so `mbank.pl`, `phone.jan.pl` resolve;
- identifies the session as **Jan Kowalski** (`TWIN_USER`).

Trust is contained to this image only — the CA is never installed on the host.
