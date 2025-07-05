# flake.nix

{
  description = "Meu toolkit pessoal com ambientes de desenvolvimento para Node, Go e Python";

  # Entradas: as dependências do nosso flake.
  # A principal é o nixpkgs, que contém todos os pacotes.
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  # Saídas: o que nosso flake oferece para o mundo.
  # Pode ser pacotes, ambientes de desenvolvimento (shells), etc.
  outputs = { self, nixpkgs }:
    let
      # Define o sistema para o qual estamos construindo.
      # Isso torna o flake compatível com outros sistemas no futuro.
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];

      # Função para gerar as saídas para cada sistema.
      # Isso evita repetir a mesma lógica para cada sistema.
      forEachSystem = function: nixpkgs.lib.genAttrs systems (system: function system);

    in
    {
      # 'packages' é uma saída padrão para expor pacotes.
      # Aqui vamos expor nosso conjunto de ferramentas base.
      packages = forEachSystem (system:
        let pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          # Nosso conjunto de ferramentas base
          base-tools = pkgs.buildEnv {
            name = "base-tools";
            paths = [
              # --- SUAS FERRAMENTAS BASE AQUI ---
              # pkgs.gemini-cli # Exemplo: Descomente se encontrar um pacote para ele
              pkgs.git
              pkgs.yazi
              pkgs.lazygit
              pkgs.micro
            ];
          };
        });

      # 'devShells' é a saída padrão para ambientes de desenvolvimento.
      devShells = forEachSystem (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          # Importa nosso conjunto de ferramentas base para não repetir
          baseTools = self.packages.${system}.base-tools;
        in
        {
          # 1. Um shell apenas com as ferramentas base
          base = pkgs.mkShell {
            name = "base-shell";
            packages = [ baseTools ];
          };

          # 2. Um shell para desenvolvimento Node.js
          node = pkgs.mkShell {
            name = "node-dev-shell";
            packages = [
              baseTools      # Inclui todas as ferramentas base
              pkgs.nodejs_24 # O usuário pediu v24, mas v22 é a mais recente estável em nixpkgs.
                             # Podemos usar v24 se estiver disponível ou usar outra fonte.
                             # Por agora, vamos usar a versão LTS mais recente.
            ];
          };

          # 3. Um shell para desenvolvimento Go
          go = pkgs.mkShell {
            name = "go-dev-shell";
            packages = [
              baseTools   # Inclui todas as ferramentas base
              pkgs.go
              pkgs.gopls  # O language server para Go, muito útil
            ];
          };

          # 4. Um shell para desenvolvimento Python
          python = pkgs.mkShell {
            name = "python-dev-shell";
            packages = [
              baseTools                # Inclui todas as ferramentas base
              pkgs.python3
              pkgs.python3Packages.pip # Inclui o pip
            ];
          };

        });
    };
}
