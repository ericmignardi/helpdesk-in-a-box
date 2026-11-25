# Practice Tickets: Bayview Precision Fabrication

Ten realistic help desk tickets, each set up in the lab, submitted through osTicket by the affected user, and worked by me (`emignardi`) from triage to closure.

**How to use this file**
1. Do the **Lab setup** steps to create the problem. They're not part of the write-up; they're how the problem gets into the lab.
2. Submit the ticket from CLIENT01 as the user, in their words.
3. Troubleshoot it **yourself first**. Open the hint only if you're stuck or want to check your approach.
4. Fill in every **Write-up** field in your own words. That's what interviewers and readers will see.

**Method (CompTIA troubleshooting steps):** identify the problem → theory of probable cause → test the theory → plan and fix → verify full functionality and prevent it happening again → document.

---

## BAY-001: New hire setup (Shipping)

| Field | Value |
|---|---|
| Reported by | Karen Walsh (General Manager) |
| Help topic / SLA | New Hire / Offboarding · Standard |
| Priority | Normal |

**User's words:** "Jordan Lee starts Monday as a Shipping & Receiving clerk. Can you set up their login, drives and whatever else Shipping usually has? Thanks."

**Lab setup:** nothing to break. Submit the ticket as `kwalsh`.

**Write-up**
- **Triage questions asked:** _…_
- **Steps taken:** _…_
- **Verification:** _…_
- **Message to the requester:** _…_
- **Time to resolve:** _…_

<details><summary>Hint / expected approach</summary>

Copy the `_tmpl-shipping` template in ADUC (right-click → Copy). That carries over the group membership and Department. New user `jlee` in the Shipping OU, temporary password, **"User must change password at next logon" ✓**, enabled. Test: log in as `jlee` on CLIENT01, get forced to change the password, S: drive present, `Shipping` folder writable, no printer (Shipping isn't targeted, which is correct). In the reply to Karen, don't send the password in the ticket; say it will be given to Jordan in person. Mention templates as the reason it's consistent.
</details>

---

## BAY-002: Forgotten password

| Field | Value |
|---|---|
| Reported by | Dan Rossi (Machinist), via Mike Kowalski's login because Dan can't sign in |
| Help topic / SLA | Account & Password · Urgent |
| Priority | High |

**User's words:** "Dan forgot his password after the long weekend and can't log in to the shop terminal."

**Lab setup:** nothing to break. Submit as `mkowalski` on Dan's behalf.

**Write-up**
- **How identity was verified:** _…_
- **Steps taken:** _…_
- **Verification:** _…_
- **Message to the user:** _…_

<details><summary>Hint / expected approach</summary>

**Verify identity before resetting.** In a real shop that's a call-back to Dan's known extension or his supervisor confirming in person, never just "someone emailed." Check he isn't also locked out (ADUC → Account tab). Reset the password in ADUC with **User must change password at next logon** ✓. Verify by logging in as `drossi`, which forces the change. Note in the ticket *how* identity was verified (with no password in the ticket).
</details>

---

## BAY-003: Account locked out

| Field | Value |
|---|---|
| Reported by | Sarah Chen (Office Administrator) |
| Help topic / SLA | Account & Password · Urgent |
| Priority | High |

**User's words:** "It says my account is locked. I'm sure I typed my password right!"

**Lab setup:** on CLIENT01, try to log in as `schen` with a wrong password **5 times**. Submit the ticket afterwards from `kwalsh`'s session ("on Sarah's behalf").

**Write-up**
- **Evidence found:** _…_
- **Root cause:** _…_
- **Fix:** _…_
- **Prevention / user advice:** _…_

<details><summary>Hint / expected approach</summary>

Confirm: `Search-ADAccount -LockedOut` or ADUC → schen → Account tab. Find the **source**: on DC01, Event Viewer → Windows Logs → Security → filter **Event ID 4740**. It names the caller computer (CLIENT01). Unlock: `Unlock-ADAccount schen` or the ADUC checkbox. Ask her whether her password changed recently and whether she's logged in anywhere else (a phone or second PC with an old password is the classic repeat-lockout cause). Explain the policy: 5 attempts, 15 minutes. **Don't reset her password** if she knows it; unlocking is enough.
</details>

---

## BAY-004: "My S: drive is gone"

| Field | Value |
|---|---|
| Reported by | Tom Bergeron (Shipping Coordinator) |
| Help topic / SLA | Network & Connectivity · Standard |
| Priority | Normal |

**User's words:** "The S: drive disappeared this morning. I need the shipping schedule on it!"

**Lab setup:** on DC01, **move `tbergeron` out of `Bayview\Users\Shipping` into the default `Users` container** (simulating an admin mistake). Log in as `tbergeron` on CLIENT01.

**Write-up**
- **Triage questions asked:** _…_
- **Diagnostic commands and what they showed:** _…_
- **Root cause:** _…_
- **Fix + verification:** _…_
- **Prevention:** _…_

<details><summary>Hint / expected approach</summary>

Scope first: is it just Tom? (Log in as `schen`, and her S: is fine, so it's one user.) On CLIENT01 as Tom: `gpresult /r` shows `BAY-U-DriveMaps` **missing** from Applied GPOs. Check Tom's OU in ADUC: he's in `Users`, where the GPO isn't linked. Move him back to `Bayview\Users\Shipping`, `gpupdate /force`, log off and on. S: returns. Prevention: check the OU when moving or creating accounts; the Idea 3 scripts will place users in the right OU automatically.
</details>

---

## BAY-005: Access denied to the Management folder

| Field | Value |
|---|---|
| Reported by | Priya Nair (Accounts Payable) |
| Help topic / SLA | Access Request · Standard |
| Priority | Normal |

**User's words:** "I get 'access denied' on the Management folder. I need the vendor contracts in there to process invoices."

**Lab setup:** nothing to break. This is working as designed. Log in as `pnair` and try to open `S:\Management`.

**Write-up**
- **Is this a fault or a request?** _…_
- **Who approved it, and how:** _…_
- **Action taken:** _…_
- **Message to the user:** _…_

<details><summary>Hint / expected approach</summary>

This is **not** a fault. Permissions are working. It's an **access request**, and access to management data needs the **data owner's approval** (Karen). Reply to Priya that the request has been sent for approval. In the lab, play Karen: she approves **read-only** access to just the contracts, not the whole Management folder. Best practice is a subfolder `Management\Vendor Contracts` with a new group `GG-Contracts-Read` (Read) and Priya added to it, rather than putting her in GG-Management. She must **log off and on** (her group membership is fixed at logon). Verify she can read contracts but can't open the rest. Interview point: **least privilege** plus **approval before access**.
</details>

---

## BAY-006: Printer missing

| Field | Value |
|---|---|
| Reported by | Sarah Chen (Office Administrator) |
| Help topic / SLA | Printer · Standard |
| Priority | Normal |

**User's words:** "The office copier isn't in my printer list anymore."

**Lab setup:** on DC01, **remove `schen` from `GG-Office`**. Log in as `schen` on CLIENT01 (log off and on first).

**Write-up**
- **Diagnostic steps:** _…_
- **Root cause:** _…_
- **Fix + verification:** _…_
- **Side effects noticed:** _…_

<details><summary>Hint / expected approach</summary>

Is the printer up for others? (Log in as `kwalsh`: it's there.) So it's user-specific. `gpresult /r` as Sarah: `BAY-U-Printers` applies, but its item-level targeting checks group membership. `whoami /groups` shows **no GG-Office**. Also check S:\Office, which she'll have lost too (a good side effect to notice). Re-add her to GG-Office, log off and on, and the printer returns. Prevention: group changes should come through a ticket. Note which ticket or person removed her (check DC01's Security log, **Event ID 4729**, if auditing captured it).
</details>

---

## BAY-007: Print jobs stuck in the queue

| Field | Value |
|---|---|
| Reported by | Mike Kowalski (Production Supervisor) |
| Help topic / SLA | Printer · Standard |
| Priority | Normal |

**User's words:** "I sent the work orders to the copier 3 times and nothing came out."

**Lab setup:** temporarily add `mkowalski` to `GG-Office` so he gets the printer (remove him again after). Log in as him on CLIENT01 and print a test page to `Office-Copier` 3 times. The copier IP has no device, so the jobs will sit in the queue.

**Write-up**
- **What the queue showed:** _…_
- **Root cause:** _…_
- **Action taken (including escalation):** _…_
- **Message to the user:** _…_

<details><summary>Hint / expected approach</summary>

On DC01: Print Management → Printers → `Office-Copier` → **Open Printer Queue**. The jobs show "Error" or are stuck. Test the device: `Test-NetConnection 10.10.10.50 -Port 9100` fails, so the **copier is offline**. Clear the stuck jobs (cancel them, or for a corrupt queue: `Stop-Service Spooler`, clear `C:\Windows\System32\spool\PRINTERS`, `Start-Service Spooler`; know this procedure). Since the device itself is down, **escalate** to the copier vendor (fictional "Lakeshore Office Systems") and tell Mike the ETA and a workaround (print to PDF and save to S:\Production). This ticket shows **escalation**, which the Zavasoft listing asks for. Remove Mike from GG-Office afterwards.
</details>

---

## BAY-008: Software request (7-Zip)

| Field | Value |
|---|---|
| Reported by | Tom Bergeron (Shipping Coordinator) |
| Help topic / SLA | Software Request · Standard |
| Priority | Low |

**User's words:** "A supplier sends packing lists as .7z files and I can't open them. Can I get 7-Zip?"

**Lab setup:** nothing to break. Confirm 7-Zip isn't installed on CLIENT01.

**Write-up**
- **Approval / checks before installing:** _…_
- **Deployment method and why:** _…_
- **Verification:** _…_

<details><summary>Hint / expected approach</summary>

Check that the software is approved and free for business use (7-Zip is, under the LGPL). Standard users can't install software, which is correct, so deploy it centrally: in `BAY-C-Software`, go to Computer Config → Policies → Software Settings → **Software installation** → New Package → **UNC path** `\\DC01\Software$\7z….msi` (never a local `C:\` path) → **Assigned**. Link the GPO to `Workstations`. On CLIENT01: `gpupdate /force`, then **reboot** (computer software installs only at startup). Verify 7-Zip appears in Installed apps. Bonus: `gpresult /r /scope computer`.
</details>

---

## BAY-009: "Internet works but nothing else does"

| Field | Value |
|---|---|
| Reported by | Dan Rossi (Machinist) |
| Help topic / SLA | Network & Connectivity · Urgent |
| Priority | High |

**User's words:** "Websites load fine, but the S: drive won't open, the copier's gone, and Windows keeps saying the domain isn't available."

**Lab setup:** on CLIENT01 as `localadmin`, set the network adapter's DNS manually to **8.8.8.8** (simulating a contractor "fixing" the internet). Log in as `drossi` (cached credentials let him in). Submit the ticket as Dan from the portal at `http://10.10.10.1:8080`; it still loads because it's addressed by IP, not by name. (That's a clue in itself.)

**Write-up**
- **Diagnostic commands and output:** _…_
- **Theory → test → result:** _…_
- **Root cause:** _…_
- **Fix + verification:** _…_
- **Prevention:** _…_

<details><summary>Hint / expected approach</summary>

`ipconfig /all`: DNS server is `8.8.8.8` instead of `10.10.10.10`. `nslookup dc01.bayview.internal` fails because public DNS knows nothing about your internal domain, while `ping 10.10.10.10` works, so the network is fine and **DNS** is the problem. Fix: set the adapter back to **"Obtain DNS server address automatically"**, `ipconfig /flushdns`, `ipconfig /renew`, and verify with `nslookup`, S:, and `gpupdate`. Root cause: a manually set DNS server. Prevention: standard users can't change adapter settings; remove local admin rights from anyone who doesn't need them. Classic interview line: *"it's always DNS."*
</details>

---

## BAY-010: Nobody can sign in to the help desk

| Field | Value |
|---|---|
| Reported by | Karen Walsh (by phone, since the portal won't take her login) |
| Help topic / SLA | Account & Password · Urgent |
| Priority | Emergency |

**User's words:** "Several people say the help desk site rejects their password, but Windows login works fine."

**Lab setup:** on DC01, **disable the `svc-osticket` account** in ADUC. Then try to sign in to the portal as `kwalsh`. Log the ticket yourself in the Staff Panel as **`ostadmin`** (the break-glass account, which is exactly why it exists).

**Write-up**
- **Scope (who's affected, what still works):** _…_
- **Diagnostic steps:** _…_
- **Root cause:** _…_
- **Fix + verification:** _…_
- **Prevention:** _…_

<details><summary>Hint / expected approach</summary>

Scope: Windows logins work, so AD itself is fine. Only the **app's** AD logins fail, so look at what the app uses to talk to AD: the service account. Run the RUNBOOK 6.3 `ldapsearch` from the container, which fails with **Invalid credentials (49)**. On DC01: ADUC shows `svc-osticket` **disabled**. The Security log on DC01 (**Event ID 4625**, failed logon) shows `svc-osticket` failing from the Docker host. Re-enable it, re-test `ldapsearch`, then sign in to the portal as `kwalsh`. Prevention: document service accounts (what uses them, who owns them) and add a description in AD: *"Used by osTicket LDAP. Do not disable."* (Add it now.)
</details>

---

## Stretch tickets (optional)

### BAY-011: "The trust relationship between this workstation and the primary domain failed"
**Lab setup:** on DC01, ADUC → CLIENT01 → right-click → **Reset Account**. Reboot CLIENT01 and try to log in as any domain user.
<details><summary>Hint</summary>Log in with the **local** admin account. Run `Test-ComputerSecureChannel` (returns False), then `Test-ComputerSecureChannel -Repair -Credential BAYVIEW\adm-emignardi`, then reboot. Know the older fix (rejoining the domain) and why `-Repair` is better: no reboot loop and no lost profile mappings.</details>

### BAY-012: Printer install blocked by an admin prompt (PrintNightmare)
Only if it happened to you in Phase 4.4. Write up what you saw and the safe fix.
