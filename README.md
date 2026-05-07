# kube2iam-binaries

This repository publishes binaries from the upstream `kube2iam` release tags on
[`jtblin/kube2iam`](https://github.com/jtblin/kube2iam).

The upstream GitHub releases do not publish standalone binary assets. This
repository builds those binaries from the upstream source tag and republishes
small tarballs so [`podplane/vmconfig`](https://github.com/podplane/vmconfig)
can consume them through its normal dependency manifest flow.

## Published assets

Each release tag matches the upstream kube2iam release/image tag, for example
`0.15.0`.

Release assets:

```text
kube2iam_<VERSION>_linux_amd64.tar.gz
kube2iam_<VERSION>_linux_arm64.tar.gz
kube2iam_<VERSION>_checksums.txt
kube2iam_<VERSION>_checksums.txt.bundle
kube2iam_<VERSION>_source.json
kube2iam_<VERSION>_<OS>_<ARCH>.tar.gz.spdx.json
```

Each architecture tarball contains the executable and the upstream license:

```text
kube2iam
LICENSE
```

The checksum file is `sha512sum` compatible:

```text
<sha512>  kube2iam_<VERSION>_linux_amd64.tar.gz
<sha512>  kube2iam_<VERSION>_linux_arm64.tar.gz
```

## Building locally

Required tools:

- `git`
- `go`
- `goreleaser`
- `jq`
- `syft`

Build assets for a tag:

```sh
make build TAG=0.15.0
```

Assets are written to `dist/`.

## Release automation

The GitHub Actions workflow runs daily and can also be triggered manually. It:

1. Resolves the latest upstream GitHub release tag from `jtblin/kube2iam` unless
   a tag is provided manually.
2. Skips if this repository already has a release with the same tag.
3. Resolves the tag to the exact upstream commit SHA and checks out that commit.
4. Runs GoReleaser against the checked-out upstream source to build
   `linux/amd64` and `linux/arm64` with `CGO_ENABLED=0`, `-trimpath`, readonly
   modules, and fixed ldflags.
5. Packages the binaries and upstream `LICENSE` as tarballs, writes a SHA-512
   checksum file, and generates SPDX SBOMs.
6. Signs the checksum file with Cosign keyless signing in GitHub Actions,
   producing a Sigstore bundle.
7. Publishes everything via GoReleaser. Release notes link to the official
   upstream kube2iam release notes.

## Verification model

The release script records the upstream repository, tag, commit SHA, and build
settings in `kube2iam_<VERSION>_source.json`.

GitHub Actions signs the checksum file with Cosign keyless signing. Verify the
checksum file with:

```sh
cosign verify-blob \
  --bundle kube2iam_0.15.0_checksums.txt.bundle \
  --certificate-identity-regexp 'https://github.com/podplane/kube2iam-binaries/.github/workflows/release.yml@refs/.*' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  kube2iam_0.15.0_checksums.txt
```

Then verify downloaded assets against `kube2iam_<VERSION>_checksums.txt`.

As of `0.15.0`, upstream tags are lightweight Git tags that point directly at a
commit, not signed annotated tags. Building from source still avoids trusting an
opaque OCI image layer, and Go module checksums are verified through `go.sum` and
the Go checksum database, but this is not a cryptographic upstream release
signature. If upstream starts signing tags, this workflow should be tightened to
verify those signatures before building.

## License

This repository's scripts and documentation are licensed under BSD-3-Clause to
match upstream kube2iam.

The mirrored `kube2iam` binary is built from upstream source and remains subject
to the upstream kube2iam license and notices.
