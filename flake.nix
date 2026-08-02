{
  description = "UnoCSS Language Server";

  nixConfig = {
    extra-substituters = [
      "https://unocss-language-server-nix.cachix.org"
    ];
    extra-trusted-public-keys = [
      "unocss-language-server-nix.cachix.org-1:FHwwYQY2s9CgEHRqCgv2MiT0XAySjpyZLJTHg5hHFP0="
    ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        packages.default = pkgs.stdenv.mkDerivation (finalAttrs: {
          pname = "unocss-language-server";
          version = "66.7.5";

          src = pkgs.fetchFromGitHub {
            owner = "unocss";
            repo = "unocss";
            rev = "v${finalAttrs.version}";
            hash = "sha256-sm1Grc8qcQ0tDeAHV92l5WiIaHjAHfzTUSKLp1zvJAs=";
          };

          env.CI = "true";

          pnpmDeps = pkgs.fetchPnpmDeps {
            inherit (finalAttrs) pname version src;
            hash = "sha256-kj9eioTstD+ahDjgup1RrGUxgqjTpcii3smj8eOxox8=";
            fetcherVersion = 4;
          };

          nativeBuildInputs = with pkgs; [
            nodejs
            pnpm
            pnpmConfigHook
            makeBinaryWrapper
            typescript
          ];

          pnpmInstallFlags = ["--ignore-scripts"];

          buildPhase = ''
            runHook preBuild
            pnpm --filter "@unocss/language-server..." --filter "./packages-presets/*" run build
            runHook postBuild
          '';

          installPhase = ''
            runHook preInstall

            mkdir -p $out/lib/unocss-language-server

            cp -r packages-integrations/language-server/dist $out/lib/unocss-language-server/
            cp -r packages-integrations/language-server/bin  $out/lib/unocss-language-server/
            cp packages-integrations/language-server/package.json $out/lib/unocss-language-server/

            makeWrapper ${pkgs.lib.getExe pkgs.nodejs} \
              $out/bin/unocss-language-server \
              --inherit-argv0 \
              --add-flags $out/lib/unocss-language-server/bin/unocss-language-server.js

            runHook postInstall
          '';
        });
      }
    );
}
