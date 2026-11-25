# plugins/

Put **`auth-ldap.phar`** here (RUNBOOK Phase 6.4).

1. Go to the osTicket download page (osticket.com → Download) and choose the plugins.
2. Select the **LDAP / Active Directory authentication** plugin for osTicket **1.18** and download it.
3. Save it in this folder as `auth-ldap.phar`.
4. Run `docker compose restart osticket`. The logs show `entrypoint: plugins copied`.

The container copies every `.phar` in this folder into osTicket's plugin directory each time it starts. `.phar` files are ignored by Git (they're downloaded, not authored).
