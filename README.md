Script for deploying minimal SSH jail system on Debian-like distributions, upon normal SSH installation without altering it.

Then easily add/remove SSH jail accounts, allowing users to Rsync/sFTP in their `$JAIL/home/dir` and execute minimal commands (GNU-like commands via Toybox).

 Commands:

- `jail-add.sh` (first deployment and add account)
- `jail-del.sh` (delete account)
- `jail-uninst.sh`
