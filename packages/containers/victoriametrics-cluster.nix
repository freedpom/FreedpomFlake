{
  lib,
  buildGoModule,
  fetchFromGitHub,
  version ? "1.136.0",
}:

buildGoModule rec {
  pname = "victoriametrics-cluster";
  inherit version;

  src = fetchFromGitHub {
    owner = "VictoriaMetrics";
    repo = "VictoriaMetrics";
    tag = "v${version}-cluster";
    hash = lib.fakeSha256; # Will be updated after first build attempt
  };

  vendorHash = null;

  subPackages = [
    "app/vmstorage"
    "app/vminsert"
    "app/vmselect"
  ];

  ldflags = [
    "-s"
    "-w"
    "-X github.com/VictoriaMetrics/VictoriaMetrics/lib/buildinfo.Version=${version}"
  ];

  postInstall = ''
    mv $out/bin/vmstorage $out/bin/vmstorage-cluster
    mv $out/bin/vminsert $out/bin/vminsert-cluster
    mv $out/bin/vmselect $out/bin/vmselect-cluster
  '';

  meta = with lib; {
    description = "VictoriaMetrics cluster version - high-performance, cost-effective and scalable time series database";
    homepage = "https://victoriametrics.com/";
    license = licenses.asl20;
    maintainers = [ ];
    platforms = platforms.linux;
  };
}
