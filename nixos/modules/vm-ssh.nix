{ pkgs, ... }: {
  services.openssh = {
    enable = true;
    settings = { PermitRootLogin = "yes"; PasswordAuthentication = true; };
  };
  users.users.root.hashedPassword = "$6$8fxlnRQm4BudcWzf$1/yDod3iR7GplqPNqltJkLZpktHiQRMV4fcbQjIuOnFef4FzBrMuVfUqVTiO6nPoDJ0Cx2rkUM7Rzm5bXyaQT1";
  networking.interfaces.eth0.ipv4.addresses = [{ address = "192.168.100.2"; prefixLength = 24; }];
}
