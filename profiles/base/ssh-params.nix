{
  Ciphers = [
    "chacha20-poly1305@openssh.com"
    "aes256-gcm@openssh.com"
    "aes128-gcm@openssh.com"
    "aes256-ctr"
    "aes192-ctr"
    "aes128-ctr"
  ];
  KexAlgorithms = [
    "curve25519-sha256"
    "curve25519-sha256@libssh.org"
    "diffie-hellman-group16-sha512"
    "diffie-hellman-group18-sha512"
    "diffie-hellman-group-exchange-sha256"
    "diffie-hellman-group14-sha256"
  ];
  Macs = [
    "hmac-sha2-256-etm@openssh.com"
    "hmac-sha2-512-etm@openssh.com"
    "umac-128-etm@openssh.com"
  ];
  HostKeyAlgorithms = [
    "ssh-ed25519"
    "ssh-ed25519-cert-v01@openssh.com"
    "sk-ssh-ed25519@openssh.com"
    "sk-ssh-ed25519-cert-v01@openssh.com"
    "rsa-sha2-256"
    "rsa-sha2-256-cert-v01@openssh.com"
    "rsa-sha2-512"
    "rsa-sha2-512-cert-v01@openssh.com"
  ];
}
