{
  description = "dev shells";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = {self, nixpkgs}:
  let
    pkgs = import nixpkgs { system = "x86_64-linux"; config.allowUnfree = true; };
  in
  {
    devShells."x86_64-linux".php = pkgs.mkShell {
      packages = [
        pkgs.php
        pkgs.php.packages.composer
        pkgs.mysql
        pkgs.mysql-client
        pkgs.phpExtensions.pdo_mysql
        pkgs.phpExtensions.mbstring
        pkgs.nodejs
        pkgs.yarn
      ];

      shellHook = ''
        MYSQL_BASEDIR=${pkgs.mariadb}
        MYSQL_HOME="/home/terminator/mysql"
        MYSQL_DATADIR="$MYSQL_HOME/data"
        export MYSQL_UNIX_PORT="$MYSQL_HOME/mysql.sock"
        MYSQL_PID_FILE="$MYSQL_HOME/mysql.pid"
        alias mysql='mysql -u root'

        # TODO: check if mysql server already runnin'

        if [ ! -d "$MYSQL_HOME" ]; then
          mysql_install_db --no-defaults --auth-root-authentication-method=normal \
            --datadir="$MYSQL_DATADIR" --basedir="$MYSQL_BASEDIR" \
            --pid-file="$MYSQL_PID_FILE"
        fi

        mysqld --no-defaults --skip-networking --datadir="$MYSQL_DATADIR" --pid-file="$MYSQL_PID_FILE" \
          --socket="$MYSQL_UNIX_PORT" 2> "$MYSQL_HOME/mysql.log" &
        MYSQL_PID=$!

        finish()
        {
          mysqladmin -u root --socket="$MYSQL_UNIX_PORT" shutdown
          kill $MYSQL_PID
          wait $MYSQL_PID
        }
        
        trap finish EXIT
      '';
    };

    devShells."x86_64-linux".csharp = pkgs.mkShell {
      packages = [
        pkgs.dotnetCorePackages.sdk_8_0_2xx
      ];
    };

    devShells."x86_64-linux".java = pkgs.mkShell {
      packages = [
        pkgs.jdk
      ];
    };
  };
}