MYSQL_DATABASE="misp"
MYSQL_USER="misp"

MISP_ADMIN_EMAIL="admin@admin.test"
MISP_ADMIN_PASSPHRASE="ChangeMe"

POSTFIX_RELAY_HOST="relay.fqdn"
TIMEZONE="Europe/Brussels"

DATA_DIR="./data"

# DNS zone to deploy MISP and MISP-DASHBOARD
route53_zone="yourzone.example.com"

# List of CIDR used to whitelist IP for access
authorized_ips = ["0.0.0.0/0"]

aws_region = "YOURREGION"

# Size of the DB used by MISP
size_db = 20
