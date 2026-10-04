# Lab 2: Linux Administration and Deploying a Web App to EC2

### Deployment Steps
The `deploy-web.sh` script performs the following steps in order:
1. Installs the `python3` package using `dnf`.
2. Creates a restricted system user named `acs730web` (with no home directory and a nologin shell).
3. Creates the application directory at `/opt/acs730-web`, writes the `index.html` file into it, and assigns ownership to the `acs730web` user.
4. Copies the `acs730-web.service` unit file to `/etc/systemd/system/` and reloads the systemd daemon.
5. Enables and restarts the `acs730-web` service so it is actively running and configured to start on boot.

### systemctl start vs. systemctl enable
`systemctl start` turns the service on immediately for the current session, whereas `systemctl enable` configures the service to start automatically whenever the system boots up.

### Security Group Rules
SSH (port 22) is restricted to a `/32` IP address to ensure only our specific administrator workstation can securely log into the server, while HTTP (port 80) is open to `0.0.0.0/0` because the web application is intended to be publicly accessible to anyone on the internet.

### Service User
The application runs as the `acs730web` user. It is not run as root to follow the principle of least privilege; if a vulnerability in the web application is exploited, the attacker is confined to a restricted account and does not gain administrative control over the entire server.

## Experiments

### Experiment 4: Run it as root
* **Prediction:** If I change the service to run as root, the application will still start, but the `ps` command will show `root` as the owner of the web server process instead of the restricted service user.
* **Observation:** Running the app as `acs730web` confines an attacker to a low-privileged account if they find a bug in the web server, limiting their blast radius. Running it as `root` means an attacker who compromises the web server instantly gains full administrative control over the entire system, allowing them to steal secrets, install malware, or lock us out.

### Experiment 5: Break the idempotency
* **Prediction:** If I remove the `if` guard, the script will crash on the second run because the `useradd` command will fail when it tries to create a user that already exists.
* **Observation:** The script crashed exactly at the `useradd` line with an "already exists" error. Because the script includes `set -e` (fail fast), this single error caused the execution to instantly abort. Deploy scripts must be idempotent (safe to run twice) so they can be safely re-run to apply updates or resume a failed deployment without breaking the system.
