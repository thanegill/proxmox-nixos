{

  name = "proxmox-ve";

  nodes.mypve = {
    services.proxmox-ve.enable = true;
  };

  testScript = ''
    machine.start()
    machine.wait_for_unit("pveproxy.service")
    assert "running" in machine.succeed("pveproxy status")
    assert "Proxmox" in machine.succeed("curl -k https://localhost:8006")
    machine.succeed("pvecm create mycluster")
    machine.wait_for_unit("corosync.service")
  '';
}
