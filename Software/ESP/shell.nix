{ pkgs ? import <nixpkgs> {} }:
let
  # TODO: from <stockholm>
  nodemcu-uploader-next = pkgs.python2Packages.buildPythonPackage rec {
      name = "nodemcu-uploader-${version}";
      version = "0.4.1";
      propagatedBuildInputs = with pkgs;[
        python2Packages.pyserial
      ];
      src = pkgs.fetchFromGitHub {
        owner = "kmpm";
        repo = "nodemcu-uploader";
        rev = "v${version}";
        sha256 = "055pvlg544vb97kaqnnq51fs9f9g75vwgbazc293f3g1sk263gmn";
      };
      doCheck = false;
  };

  pyaes = pkgs.python2Packages.buildPythonPackage rec {
      name = "pyaes-${version}";
      version = "1.6.0";
      src = pkgs.fetchFromGitHub {
        owner = "ricmoo";
        repo = "pyaes";
        rev = "v${version}";
        sha256 = "04934a9zgwc8g3qhfrkcfv0bs557paigllnkrnfhp9m1azr3bfqb";
      };
      propagatedBuildInputs = with pkgs.python2Packages;[
      ];
      doCheck = false;
  };

  esptool = pkgs.python2Packages.buildPythonPackage rec {
      name = "esptool-${version}";
      version = "1.3";
      propagatedBuildInputs = with pkgs.python2Packages;[
        pyserial
        flake8
        ecdsa
        pyaes
      ];
      src = pkgs.fetchFromGitHub {
        owner = "espressif";
        repo = "esptool";
        rev = "v${version}";
        sha256 = "0112fybkz4259gyvhcs18wa6938jp6w7clk66kpd0d1dg70lz1h6";
      };
      doCheck = false;
  };

in pkgs.stdenv.mkDerivation rec {
  name = "minikrebs-env";
  version = "1.1";
  buildInputs = with pkgs; [
    wget
    git
    gawk
    bash
    platformio
    nodemcu-uploader-next
    esptool
    mosquitto # mosquitto_pub
    # esplorer
    jdk
  ];
    shellHook =''
      HISTFILE="$PWD/.histfile"
      upload(){
        nodemcu-uploader upload --compile *.lua
        nodemcu-uploader upload *.html *.js init.lua
        nodemcu-uploader node restart
        nodemcu-uploader terminal
      }
      alias term='nodemcu-uploader terminal'
      alias ulc='nodemcu-uploader upload --compile'
      alias ul='nodemcu-uploader upload'
    '' ;
}
