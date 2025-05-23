{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:

buildGoModule rec {
  pname = "frei";
  version = "0.4.0";

  src = fetchFromGitHub {
    owner = "alexcoder04";
    repo = "frei";
    rev = "v${version}";
    sha256 = "sha256-QVoRiqQt4DJK07YcCPplxigpgIqjDeQVYyDK/KQ7gbo=";
  };

  vendorHash = null;

  meta = with lib; {
    description = "Modern replacement for free";
    homepage = "https://github.com/alexcoder04/frei";
    license = licenses.gpl3Only;
    maintainers = with maintainers; [ infinidoge ];
    mainProgram = "frei";
  };
}
