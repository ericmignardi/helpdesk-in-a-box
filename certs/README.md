# certs/

Put the lab's root CA certificate here as **`bayview-root-ca.crt`** (RUNBOOK Phase 6.2).

- It must be **Base64/PEM** text that starts with `-----BEGIN CERTIFICATE-----`. `certutil -encode` produces this.
- It's the *public* certificate only, not a private key. It's still ignored by Git to keep the repo free of lab-specific files.

When the container starts, it adds this certificate to its trusted list. That's what lets osTicket's TLS connection to `dc01.bayview.internal` pass the certificate check.
