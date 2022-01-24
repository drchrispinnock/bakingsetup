
Networks != {monday,daily}net are not reset automatically by the
scripts in this directory. Sometimes a reset is needed and has to
be done by hand (e.g. 24/25th Jan 2022 Ithacanet reset).

1. Make sure you are on the latest bakingsetup
2. Make sure your public and secret keys are in wallet-`hostname -s`
e.g.
ls -l wallet-ithacanet-stockholm/
total 12
-rw-rw-r-- 1 ubuntu ubuntu  73 Jan 24 12:00 public_key_hashs
-rw-rw-r-- 1 ubuntu ubuntu 211 Jan 24 12:00 public_keys
-rw-rw-r-- 1 ubuntu ubuntu 113 Jan 24 12:00 secret_keys

3. touch ~/.cleanup ~/.resetnode ~/.resetwallet

4. Run /bin/bash bakingsetup/mondaynet/mondaynet-setup.sh by hand.

