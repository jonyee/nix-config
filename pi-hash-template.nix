version:
with import <nixpkgs> {};
stdenv.mkDerivation {
  name = "pi-coding-agent-npm-${version}";
  outputHashAlgo = "sha256";
  outputHashMode = "recursive";
  outputHash = lib.fakeHash;
  nativeBuildInputs = [ nodejs_22 cacert ];
  buildCommand = ''
    export HOME="$TMPDIR"
    export npm_config_cache="$TMPDIR/.npm"
    export SSL_CERT_FILE="${cacert}/etc/ssl/certs/ca-bundle.crt"
    npm install -g --prefix="$out" @mariozechner/pi-coding-agent@${version}
    rm -rf "$out/bin"
  '';
}