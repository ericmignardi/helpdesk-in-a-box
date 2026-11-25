# RUNBOOK: Help Desk-in-a-Box

Step-by-step build plan. **You do every step yourself.** Each step has a check that it worked (✔) and a screenshot checkpoint (📸). Save screenshots as `screenshots/pN-NN-short-name.png`, e.g. `p2-03-ou-structure.png`.

**Pace:** about 9–10 days at 3–4 hours a day.
**Deadline:** the Windows 11 evaluation lasts 90 days from install, so finish this project, Idea 3 and Idea 4 well inside that window.

---

## Rules for the whole project

1. **End every session with a `git push`.** Notes, screenshots and config go to GitHub even if a VM breaks.
2. **Disk floor: 40 GB free.** Check free space at the start of each session (File Explorer → This PC). If it's under 40 GB, stop and clean up before carrying on.
3. **At most 2 snapshots per VM.** Delete old ones with VMware's **Snapshot Manager** (VM → Snapshot → Snapshot Manager → select → Delete). Deleting a snapshot merges it into the VM; it does **not** delete the VM.
4. **Never delete files inside a VM's folder by hand.** Use VMware's menus only. Deleting `.vmdk` files by hand is what broke the last lab.
5. **No real passwords in the repo.** Keep lab passwords in a password manager or a private note. `.env` is in `.gitignore`.
6. **Stuck for more than 30 minutes?** Write down what you tried, then ask Claude with the exact error message and a screenshot.

### Lab network values (VMnet8 = 10.10.10.0/24)

| Item                            | Your value                             |
| ------------------------------- | -------------------------------------- |
| VMnet8 subnet                   | `10.10.10.0` (mask `255.255.255.0`)    |
| Host VMnet8 adapter IP          | `10.10.10.1` (confirm with `ipconfig`) |
| VMware NAT gateway / DNS proxy  | `10.10.10.2` (confirm in NAT Settings) |
| DC01 static IP                  | `10.10.10.10`                          |
| DHCP range                      | `10.10.10.100` to `.199`               |
| Simulated copier IP (no device) | `10.10.10.50`                          |
| Domain / NetBIOS name           | `bayview.internal` / `BAYVIEW`         |

This runbook already uses these values. If you ever rebuild on a different subnet, change them here and everywhere else they appear.

### Disk budget (thin disks, so actual use grows over time)

| Item                 | Expected                                  |
| -------------------- | ----------------------------------------- |
| DC01 + updates       | 25–35 GB                                  |
| CLIENT01 + updates   | 25–35 GB                                  |
| Snapshots (2 per VM) | 5–15 GB                                   |
| Docker images + data | 2–3 GB                                    |
| **Total**            | **about 60–85 GB** (you have 189 GB free) |

### RAM budget (16 GB)

DC01 4 GB + CLIENT01 4 GB + Docker Desktop about 2–3 GB, which leaves about 5 GB for Windows. Close Chrome tabs and other heavy apps while both VMs are running.

---

## Phase 0: Prep and repo · ~0.5 day

- [*] Write down your free disk space: `188 GB`
- [*] Create a **public** GitHub repo called `helpdesk-in-a-box`. Clone it into this folder, or `git init` here and add the remote.
- [*] Copy the starter files from this folder into the repo (README, RUNBOOK, TICKETS, Docker files, `.gitignore`, `.gitattributes`) and make the first commit: `Initial plan and osTicket stack`
- [*] Open VMware Workstation → **Edit → Virtual Network Editor → Change Settings** (needs admin)
  - [*] Select **VMnet8 (NAT)**. Write its **Subnet IP** in the table above.
  - [*] **Untick "Use local DHCP service to distribute IP address to VMs".** DC01 will be the DHCP server, and two DHCP servers on one network cause random IP problems.
  - [*] Click **NAT Settings** and confirm the Gateway IP ends in **.2**
  - [*] Apply / OK
- [*] On the host, run `ipconfig` in PowerShell and find **"Ethernet adapter VMware Network Adapter VMnet8"**. Write its IP (usually `.1`) in the table above.
- ✔ The table at the top is filled in
- 📸 `p0-01-vmnet8-settings.png` (Virtual Network Editor with DHCP unticked)
- [*] `git push`

---

## Phase 1: Build DC01 · ~1 day

### 1.1 Create the VM

- [ ] VMware: **File → New Virtual Machine → Typical**
- [ ] **"I will install the operating system later"**
- [ ] Guest OS: **Microsoft Windows → Windows Server 2025** (if it isn't listed, pick Windows Server 2022)
- [ ] Name: `DC01`. Location: your VMs folder (keep it out of OneDrive).
- [ ] Disk: **60 GB**. Leave **"Allocate all disk space now" unticked** (thin). Choose "Store virtual disk as a single file".
- [ ] **Customize Hardware:** Memory **4 GB**, Processors **2**, Network **NAT**, CD/DVD → **Use ISO image** → your Server 2025 ISO
- [ ] Remove the sound card and printer (they aren't needed on a server)

### 1.2 Install Windows Server

- [ ] Power on and press a key to boot from the DVD
- [ ] Choose **Windows Server 2025 Standard Evaluation (Desktop Experience)**
- [ ] Custom install → the unallocated drive → Next
- [ ] Set a strong local Administrator password and save it in your password manager
- [ ] Log in, then **VM → Install VMware Tools** and run setup from the D: drive. Reboot.
- 📸 `p1-01-server-installed.png` (desktop showing Server Manager)

### 1.3 Basic config

- [ ] Rename the computer to **DC01** (Settings → System → About → Rename this PC). Reboot.
- [ ] Set the time zone to **(UTC-05:00) Eastern Time**
- [ ] Set a static IP (ncpa.cpl → Ethernet0 → IPv4 Properties):
  - IP `10.10.10.10`, mask `255.255.255.0`, gateway `10.10.10.2`
  - Preferred DNS `10.10.10.2` for now (it changes after promotion)
- [ ] Run Windows Update until no updates are left
- ✔ `ping 10.10.10.2` and `ping microsoft.com` both reply
- ✔ `hostname` returns `DC01`
- 📸 `p1-02-static-ip.png` (`ipconfig /all`)
- [ ] Shut down → **Snapshot: `DC01-clean-os`**
- [ ] `git push` (notes + screenshots)

---

## Phase 2: Active Directory + DNS · ~1 day

### 2.1 Promote to domain controller

- [ ] Server Manager → **Add roles and features** → **Active Directory Domain Services** → Install
- [ ] Click the flag → **Promote this server to a domain controller**
  - **Add a new forest** → Root domain: `bayview.internal`
  - Functional levels: leave the defaults. Check DNS server. Set a DSRM password and save it.
  - NetBIOS name: `BAYVIEW`
- [ ] Review → Install. The server reboots.
- ✔ The login screen shows `BAYVIEW\Administrator`
- 📸 `p2-01-promotion-complete.png` (Server Manager showing AD DS and DNS)

> **Why `.internal`?** It's reserved for private networks, so it can never clash with a real public domain. `.local` causes problems with mDNS on Macs and phones. Expect to be asked this in an interview.

### 2.2 DNS

- [ ] Check DC01's IPv4 DNS settings now show **Preferred: `10.10.10.10`**, **Alternate: `127.0.0.1`**. Fix them if not.
- [ ] DNS Manager → DC01 → Properties → **Forwarders** → add `10.10.10.2`
- [ ] Create a **Reverse Lookup Zone**: Primary, AD-integrated, IPv4, network ID `10.10.10`
- [ ] In the forward zone, open the `DC01` A record and tick **Update associated PTR record**
- ✔ `nslookup dc01.bayview.internal` returns `.10`
- ✔ `nslookup 10.10.10.10` returns `dc01.bayview.internal`
- ✔ `nslookup microsoft.com` works (through the forwarder)
- 📸 `p2-02-dns.png` (DNS Manager with both zones + the nslookup results)

### 2.3 OUs, groups and accounts (Active Directory Users and Computers)

- [ ] Turn on **View → Advanced Features** (handy later)
- [ ] Create the OU tree from the README: `Bayview` → `Users` (Office, Production, Shipping, Management, IT), `Computers` (Workstations), `Groups`, `Service Accounts`, `Admin Accounts`, `Disabled Users`
- [ ] In `Bayview\Groups`, create **Global Security** groups: `GG-Office`, `GG-Production`, `GG-Shipping`, `GG-Management`, `GG-IT`
- [ ] Create users (fill in **First name, Last name, Display name, Job title and Department**; set an initial password; untick "must change password" for now so you can test easily):

| User          | Username  | OU         | Group         | Title                  |
| ------------- | --------- | ---------- | ------------- | ---------------------- |
| Karen Walsh   | kwalsh    | Management | GG-Management | General Manager        |
| Sarah Chen    | schen     | Office     | GG-Office     | Office Administrator   |
| Priya Nair    | pnair     | Office     | GG-Office     | Accounts Payable Clerk |
| Mike Kowalski | mkowalski | Production | GG-Production | Production Supervisor  |
| Dan Rossi     | drossi    | Production | GG-Production | Machinist              |
| Tom Bergeron  | tbergeron | Shipping   | GG-Shipping   | Shipping Coordinator   |
| Eric Mignardi | emignardi | IT         | GG-IT         | IT Support             |

- [ ] Create a **Shipping template** account `_tmpl-shipping` (disabled, member of GG-Shipping, Department and Company filled in). You'll copy it in BAY-001.
- [ ] In `Admin Accounts`: `adm-emignardi` → member of **Domain Admins**. From now on, do admin work as this account, not Administrator.
- [ ] In `Service Accounts`: `svc-osticket` → standard user (Domain Users only), **Password never expires** ✓, **User cannot change password** ✓, with a long random password saved in your password manager
- [ ] Optional but good: run `Get-ADUser -Filter * -SearchBase "OU=Bayview,DC=bayview,DC=internal" | Select Name,SamAccountName,Enabled` in PowerShell
- ✔ Log off and log in as `BAYVIEW\adm-emignardi`
- 📸 `p2-03-ou-structure.png` · `p2-04-users.png` · `p2-05-groups.png`

### 2.4 Password and lockout policy

- [ ] Group Policy Management → Default Domain Policy → **Edit** → Computer Config → Policies → Windows Settings → Security Settings → Account Policies
  - **Password Policy:** minimum length **12**, complexity **Enabled**, maximum age **90 days**
  - **Account Lockout Policy:** threshold **5**, duration **15 min**, reset counter after **15 min**
- [ ] Run `gpupdate /force` on DC01
- ✔ `net accounts /domain` shows the new values
- 📸 `p2-06-password-lockout-policy.png`
- [ ] Shut down → **Snapshot: `DC01-ad-ready`**. Delete `DC01-clean-os` if you need the space.
- [ ] `git push`

---

## Phase 3: DHCP + CLIENT01 · ~1 day

### 3.1 DHCP on DC01

- [ ] Add roles → **DHCP Server** → Install → **Complete DHCP configuration** (this authorizes it in AD)
- [ ] DHCP console → IPv4 → **New Scope** `Bayview-LAN`:
  - Range `10.10.10.100` to `10.10.10.199`, mask `/24`
  - Exclusions: none. Lease: 8 days.
  - Router (003): `10.10.10.2` · DNS (006): `10.10.10.10` · Domain name (015): `bayview.internal`
  - Activate the scope
- 📸 `p3-01-dhcp-scope.png` (scope + options)

### 3.2 Create CLIENT01

- [ ] New VM → Typical → install OS later → **Windows 11 x64**
- [ ] **Encryption** (required for Windows 11's TPM): choose **"Only the files needed to support a TPM are encrypted"**. Save the encryption password in your password manager. You'll need it if you ever move the VM.
- [ ] Name `CLIENT01`, disk **64 GB thin**, single file, Memory **4 GB**, CPUs **2**, Network **NAT**, ISO = Windows 11 Enterprise eval
- [ ] Install Windows 11. At sign-in, choose **Sign-in options → Domain join instead** to create a local account (`localadmin`).
- [ ] Install VMware Tools, reboot
- ✔ `ipconfig /all` shows an IP between `.100` and `.199`, DNS server `10.10.10.10` and suffix `bayview.internal`. **This proves DHCP works.**
- ✔ `nslookup dc01.bayview.internal` works from CLIENT01
- 📸 `p3-02-client-dhcp-lease.png` (client `ipconfig /all` + the DC's Address Leases view)

### 3.3 Join the domain

- [ ] Rename the PC to `CLIENT01`, reboot
- [ ] Settings → System → About → **Domain or workgroup** → Domain: `bayview.internal` → credentials `BAYVIEW\adm-emignardi` → reboot
  - (PowerShell equivalent you should know: `Add-Computer -DomainName bayview.internal -Credential BAYVIEW\adm-emignardi -Restart`)
- [ ] On DC01, move `CLIENT01` from the default **Computers** container into `Bayview\Computers\Workstations`
- [ ] Log in to CLIENT01 as `BAYVIEW\schen`
- ✔ `whoami` → `bayview\schen` · `echo %LOGONSERVER%` → `\\DC01`
- 📸 `p3-03-domain-joined.png`
- [ ] Shut down both VMs → **Snapshot: `CLIENT01-joined`**
- [ ] `git push`

---

## Phase 4: File shares, permissions and GPOs · ~1.5 days

### 4.1 Company file share (on DC01)

- [ ] Create `C:\Shares\Company` with subfolders `Office`, `Production`, `Shipping`, `Management`
- [ ] Share `Company` as `Company`. Share permissions: **Authenticated Users: Change** (NTFS does the real control).
- [ ] NTFS on `Company`: disable inheritance (convert), remove `Users`, keep `SYSTEM` + `Administrators` Full. Add **Domain Users: Read & execute** on _this folder only_.
- [ ] NTFS on each department subfolder: add that department's group with **Modify**. On `Management`, **only** GG-Management (and admins).
- ✔ Test from CLIENT01 as `schen`: she can create a file in `Office`, can't create one in `Production`, and gets **Access denied** on `Management`
- 📸 `p4-01-ntfs-management.png` (Advanced Security on Management) · `p4-02-access-test.png`

> **Interview point:** share permissions vs NTFS permissions, and why "share = Change, NTFS = real control" is a common pattern. When both apply, the most restrictive wins.

### 4.2 GPO: drive maps (`BAY-U-DriveMaps` → link to `Bayview\Users`)

- [ ] User Config → Preferences → Windows Settings → **Drive Maps** → New:
  - **S:** `\\DC01\Company`, Action **Update**, Label `Company`
  - **M:** `\\DC01\Company\Management`, Action **Update** → Common tab → **Item-level targeting** → Security Group = `BAYVIEW\GG-Management`
- ✔ On CLIENT01: log in as `schen` → S: present, M: absent. Log in as `kwalsh` → both.
- ✔ Run `gpresult /r` and confirm `BAY-U-DriveMaps` appears under **Applied Group Policy Objects**
- 📸 `p4-03-drive-maps.png`

### 4.3 GPO: screen lock (`BAY-U-Desktop` → link to `Bayview\Users`)

- [ ] User Config → Policies → Admin Templates → Control Panel → Personalization: **Enable screen saver**, **Password protect the screen saver**, **Screen saver timeout = 600**
- ✔ After `gpupdate /force` and a re-logon, the screen locks after 10 minutes

### 4.4 Print server + GPO printer

- [ ] On DC01: Add roles → **Print and Document Services** → Print Server
- [ ] Print Management → Printers → **Add Printer** → new TCP/IP port `10.10.10.50` (it will say the device isn't found: choose **Generic Network Card** / continue) → driver **Generic / Text Only** → name `Office-Copier`, share as `Office-Copier`, location `Office`
- [ ] GPO `BAY-U-Printers` → link to `Bayview\Users` → User Config → Preferences → Control Panel Settings → **Printers** → New **Shared Printer** → `\\DC01\Office-Copier`, Action **Update** → item-level targeting: group `GG-Office` **OR** `GG-Management`
- ✔ As `schen` on CLIENT01, `Office-Copier` shows in Printers & scanners. As `drossi` (Production), it doesn't.
- 📸 `p4-04-print-management.png` · `p4-05-printer-on-client.png`

> If the printer won't install and asks for admin rights, you've hit the **PrintNightmare** driver restriction (Microsoft's 2021 security fix). Don't weaken it. Screenshot it, write it up as a bonus ticket, and ask Claude for the safe fix (pre-installing the driver as admin).

### 4.5 GPO: software deployment (`BAY-C-Software` → link to `Bayview\Computers\Workstations`)

- [ ] On DC01: create `C:\Shares\Software`, share it as `Software$` (the `$` hides it). Share: Authenticated Users **Read**. NTFS: **Domain Computers: Read** (the computer account installs it at startup).
- [ ] Download the latest **7-Zip x64 .msi** from 7-zip.org into `Software$`
- [ ] **Don't link the GPO yet.** BAY-008 is the ticket where you deploy it. For now, create the GPO and leave it unlinked.
- [ ] Shut down both VMs → **Snapshot DC01: `DC01-services-ready`** (delete the oldest DC01 snapshot so you stay at 2)
- [ ] `git push`

---

## Phase 5: osTicket in Docker · ~1 day

### 5.1 Start the stack (on the host, in this folder)

- [ ] Make sure Docker Desktop is running
- [ ] `copy .env.example .env`, then open `.env` and set two strong passwords plus `DC_IP=10.10.10.10`
- [ ] `docker compose up -d --build`
  - The first run downloads `php:8.3-apache` and `mariadb:11.4` and builds the image (5–10 min)
- ✔ `docker compose ps` shows `db` as **healthy** and `osticket` as **running**
- ✔ `docker compose logs osticket` shows `entrypoint: new install, open .../setup/`
- If the build fails, copy the **last 30 lines** of the output and ask Claude. Don't guess.

### 5.2 Run the web installer

- [ ] On the host, go to `http://localhost:8080/setup/`
- [ ] Prerequisites: all required items green (screenshot this)
- [ ] System settings:
  - Helpdesk name `Bayview IT Help Desk` · default email `helpdesk@bayview.internal`
  - Admin user: **`ostadmin`**, your own name, a strong password. This is your **break-glass** login if AD is down.
  - Database: MySQL hostname **`db`**, database **`osticket`**, username **`osticket`**, password = `DB_PASSWORD` from `.env`, table prefix `ost_`
- [ ] Install Now → "Congratulations"
- [ ] `docker compose restart osticket`
- ✔ The logs now show `osTicket installed, config locked, setup folder removed`
- ✔ `http://localhost:8080/setup/` returns **Not Found**
- 📸 `p5-01-installer-prereqs.png` · `p5-02-install-complete.png`

### 5.3 Reach it from CLIENT01

- [ ] On CLIENT01, open Edge → `http://10.10.10.1:8080`
- ✔ The osTicket portal loads
- If it times out, it's the **host's** Windows Firewall. On the host: Windows Defender Firewall → Advanced → **Inbound Rules → New Rule** → Port → TCP **8080** → Allow → all profiles → name `Lab osTicket 8080` → then open the rule → **Scope → Remote IP: `10.10.10.0/24`** only. This lets the lab VMs in without opening the port to everything.
- 📸 `p5-03-portal-from-client.png`

### 5.4 Configure the help desk (Staff Panel → Admin Panel, as `ostadmin`)

- [ ] **Agents → Departments:** rename `Support` to `IT Support`
- [ ] **Manage → SLA:** `Standard` (grace 24 h, default) and `Urgent` (grace 4 h)
- [ ] **Manage → Help Topics:** Account & Password, Access Request, New Hire / Offboarding, Hardware, Printer, Network & Connectivity, Software Request. All route to IT Support. Set **Account & Password** to the Urgent SLA.
- [ ] **Agents → Canned Responses:** at least 4 (Password reset complete · Need more information · Request needs manager approval · Issue resolved, please confirm)
- [ ] **Settings → Users:** require users to sign in before creating tickets (registration method: users sign in with their account)
- ✔ Submit a test ticket from the portal and see it in the Staff Panel queue
- 📸 `p5-04-help-topics.png` · `p5-05-sla.png` · `p5-06-test-ticket.png`
- [ ] `git push`

> Menu names in 1.18 may differ slightly from this list. Screenshot what you actually see and match by meaning.

---

## Phase 6: Certificate authority + AD sign-in for osTicket · ~1 day

**Why this phase exists:** Windows Server 2025 domain controllers **require LDAP signing by default**, so a plain username and password sent over port 389 is rejected. The secure fix is to encrypt the connection with TLS, which needs a certificate on the DC. Weakening the DC's security policy would be the wrong fix, so don't.

### 6.1 Install AD Certificate Services (DC01, as `adm-emignardi`)

- [ ] Add roles → **Active Directory Certificate Services** → role service **Certification Authority** → Install
- [ ] Configure: **Enterprise CA** → **Root CA** → new private key → defaults (SHA256) → CA name `Bayview-Root-CA` → validity 5 years
- [ ] Run `gpupdate /force` then `certutil -pulse` (asks the DC to enrol its own certificate). Reboot DC01.
- ✔ `certlm.msc` → Personal → Certificates contains a cert **issued to `DC01.bayview.internal`** by `Bayview-Root-CA` (template _Kerberos Authentication_ or _Domain Controller_)
- ✔ Run `ldp.exe` → Connection → Connect → server `dc01.bayview.internal`, port **636**, **SSL** ticked → it connects without errors
- 📸 `p6-01-dc-certificate.png` · `p6-02-ldp-636.png`

### 6.2 Give the root certificate to the osTicket container

- [ ] On DC01 in PowerShell:
  ```powershell
  certutil -ca.cert C:\Bayview-Root-CA.cer
  certutil -encode C:\Bayview-Root-CA.cer C:\bayview-root-ca.crt
  notepad C:\bayview-root-ca.crt
  ```
- [ ] Copy all the text (`-----BEGIN CERTIFICATE-----` to `-----END CERTIFICATE-----`) and paste it into a new file on the host: `certs\bayview-root-ca.crt`
- [ ] `docker compose restart osticket`
- ✔ The logs show `entrypoint: lab root certificate trusted`

### 6.3 Test the connection from the container _before_ touching osTicket

```powershell
docker compose exec osticket ldapsearch -H ldap://dc01.bayview.internal -ZZ -x -D "svc-osticket@bayview.internal" -W -b "OU=Bayview,DC=bayview,DC=internal" "(sAMAccountName=schen)" cn mail
```

(Enter the `svc-osticket` password when prompted. `-ZZ` means "StartTLS must succeed".)

- ✔ Returns Sarah Chen's entry
- Common failures and what they mean:
  - `Can't contact LDAP server`: the container can't reach the DC. Check DC_IP in `.env`, that DC01 is on, and `ping 10.10.10.10` from the host.
  - `Connect error` with a certificate message: the root CA isn't trusted, or you used an IP address instead of `dc01.bayview.internal`
  - `Invalid credentials (49)`: wrong service account password
- 📸 `p6-03-ldapsearch-success.png`

> **This command is a great interview story:** "Before configuring the app, I proved the connection worked from inside the container with ldapsearch, so I knew any later problem was the app's config, not the network or certificates."

### 6.4 Install the LDAP plugin

- [ ] Download the **LDAP / Active Directory authentication** plugin from the osTicket download page and save it as `plugins\auth-ldap.phar` (see `plugins/README.md`)
- [ ] `docker compose restart osticket` → the logs show `plugins copied`
- [ ] Admin Panel → **Manage → Plugins → Add New Plugin** → install the LDAP plugin → open it → **Instances → Add New Instance**, name `Bayview AD`, status **Active**:
  - Default Domain: `bayview.internal`
  - DNS Servers: _(leave blank)_
  - LDAP servers: `dc01.bayview.internal`
  - Use TLS: ✓
  - Search User: `svc-osticket@bayview.internal` · Password: _(svc password)_
  - Search Base: `OU=Bayview,DC=bayview,DC=internal`
  - LDAP Schema: **Microsoft® Active Directory**
  - Staff Authentication ✓ · Client Authentication ✓
- ✔ Saving shows **"LDAP configuration updated successfully"**
- [ ] Admin Panel → **Agents → Add New Agent**: username `emignardi`, department IT Support, **authentication backend: LDAP**
- ✔ Log out of `ostadmin`. Log in to the **Staff Panel** as `emignardi` with your **AD password**.
- ✔ On CLIENT01 as `schen`: open the portal → **Sign In** → `schen` + AD password → submit a ticket
- 📸 `p6-04-plugin-config.png` (hide the password) · `p6-05-agent-ad-login.png` · `p6-06-user-ad-ticket.png`
- [ ] Shut down both VMs → snapshot each (`DC01-lab-complete`, `CLIENT01-lab-complete`), deleting older ones to stay at 2 per VM
- [ ] `git push`

---

## Phase 7: Work the tickets · ~2 days

Work through [TICKETS.md](TICKETS.md) in order. For **each** ticket:

- [ ] **Set up the problem** using the "Lab setup" steps (as admin, on DC01 or CLIENT01)
- [ ] **Log in as the affected user** on CLIENT01 and **submit the ticket through the portal** in their words, with the right help topic
- [ ] **Work it as `emignardi`** in the Staff Panel: assign it to yourself, add **internal notes** as you troubleshoot, reply to the user, and **close** it with a resolution
- [ ] **Fill in the write-up** in TICKETS.md (try first, _then_ open the hint)
- 📸 At least 2 per ticket: the evidence of the problem and the proof it's fixed (ticket thread or command output)
- [ ] Push after every 2–3 tickets

---

## Phase 8: Wrap up · ~0.5 day

- [ ] Replace the `10.10.10` placeholders in the README with your real lab values (they're private lab IPs, so they're safe to publish)
- [ ] Add your best 8–12 screenshots to the README under **Screenshots**
- [ ] Write **Lessons learned** (3–5 bullets: what broke, what surprised you, what you'd do differently)
- [ ] Change the README status to ✅ Complete
- [ ] Check snapshots: 2 per VM max. Keep `*-lab-complete`, because Idea 3 runs on this lab.
- [ ] Final `git push`, then **pin the repo** on your GitHub profile
- [ ] Tell Claude "Idea 1 is finished" → get final resume bullets + the profile update

---

## Quick reference

| Task                        | Command                                                                                                           |
| --------------------------- | ----------------------------------------------------------------------------------------------------------------- |
| Which GPOs applied?         | `gpresult /r` (summary) · `gpresult /h report.html` (full)                                                        |
| Force a policy refresh      | `gpupdate /force`                                                                                                 |
| Network details             | `ipconfig /all` · `ipconfig /release` · `ipconfig /renew` · `ipconfig /flushdns`                                  |
| DNS lookup                  | `nslookup dc01.bayview.internal`                                                                                  |
| Find locked-out users       | `Search-ADAccount -LockedOut`                                                                                     |
| Unlock                      | `Unlock-ADAccount -Identity schen`                                                                                |
| User details                | `Get-ADUser schen -Properties LockedOut,LastLogonDate,PasswordLastSet,MemberOf`                                   |
| Secure channel check        | `Test-ComputerSecureChannel -Verbose`                                                                             |
| osTicket logs               | `docker compose logs -f osticket`                                                                                 |
| Restart osTicket            | `docker compose restart osticket`                                                                                 |
| Stop the stack (keeps data) | `docker compose down`                                                                                             |
| ⚠️ Wipe all osTicket data   | `docker compose down -v`. **This deletes the database and config volumes. Only use it to start over on purpose.** |
