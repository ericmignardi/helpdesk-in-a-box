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

| Field            | Value                             |
| ---------------- | --------------------------------- |
| Reported by      | Karen Walsh (General Manager)     |
| Help topic / SLA | New Hire / Offboarding · Standard |
| Priority         | Normal                            |

**User's words:** "Jordan Lee starts Monday as a Shipping & Receiving clerk. Can you set up their login, drives and whatever else Shipping usually has? Thanks."

**Lab setup:** nothing to break. Submit the ticket as `kwalsh`.

**Write-up**

- **Triage questions asked:** Confirmed start date, job title and manager; whether Jordan needs any access beyond standard Shipping; whether a PC is needed; how the temporary password should be delivered.
- **Steps taken:** Copied the `_tmpl-shipping` template to create `jlee` in the Shipping OU (inherits GG-Shipping, department and company). Added the email address (`jlee@bayview.internal`), set a temporary password with "User must change password at next logon", and enabled the account (the template copy starts disabled).
- **Verification:** Signed in as `jlee` on CLIENT01: forced password change worked, S: mapped, could create a file in Shipping, osTicket portal sign-in worked. Will check in with Jordan on day one.
- **Message to the requester:**

  > Hi Karen,
  >
  > Jordan's account is ready for Monday. They'll have access to the Shipping folder on the S: drive, the same as the rest of the Shipping team. I'll give Jordan their temporary password in person on their first morning, and they'll choose their own password when they first sign in.
  >
  > Does Jordan need access to anything beyond the usual Shipping setup, or a computer of their own? If not, there's nothing else needed from you.
  >
  > Thanks,
  > Eric

- **Time to resolve:** About 15 minutes, including testing.

<details><summary>Hint / expected approach</summary>

Copy the `_tmpl-shipping` template in ADUC (right-click → Copy). That carries over the group membership and Department. New user `jlee` in the Shipping OU, temporary password, **"User must change password at next logon" ✓**, enabled. Test: log in as `jlee` on CLIENT01, get forced to change the password, S: drive present, `Shipping` folder writable, no printer (Shipping isn't targeted, which is correct). In the reply to Karen, don't send the password in the ticket; say it will be given to Jordan in person. Mention templates as the reason it's consistent.

</details>

---

## BAY-002: Forgotten password

| Field            | Value                                                                      |
| ---------------- | -------------------------------------------------------------------------- |
| Reported by      | Dan Rossi (Machinist), via Mike Kowalski's login because Dan can't sign in |
| Help topic / SLA | Account & Password · Urgent                                                |
| Priority         | High                                                                       |

**User's words:** "Dan forgot his password after the long weekend and can't log in to the shop terminal."

**Lab setup:** nothing to break. Submit as `mkowalski` on Dan's behalf.

**Write-up**

- **How identity was verified:** The request came from Mike Kowalski's account on Dan's behalf, so I called Dan back at his known extension and confirmed his identity before making any changes.
- **Steps taken:** Checked the Account tab in ADUC: the account was not locked out, only the password was forgotten. Reset the password with "User must change password at next logon". Gave Dan the temporary password over the verified call (not in the ticket or email). In osTicket, changed the ticket owner to Dan and added Mike as a collaborator.
- **Verification:** Dan signed in on CLIENT01 with the temporary password, was prompted to choose his own, and signed in successfully.
- **Message to the user:**

  > Hi Dan (cc Mike),
  >
  > Your password has been reset, and you should now be able to sign in to the shop terminal. As we discussed on the phone, you'll be asked to choose a new password the first time you sign in. It needs to be at least 12 characters, with upper- and lower-case letters plus a number or symbol.
  >
  > If you have any trouble, reply here or call me.
  >
  > Thanks,
  > Eric

<details><summary>Hint / expected approach</summary>

**Verify identity before resetting.** In a real shop that's a call-back to Dan's known extension or his supervisor confirming in person, never just "someone emailed." Check he isn't also locked out (ADUC → Account tab). Reset the password in ADUC with **User must change password at next logon** ✓. Verify by logging in as `drossi`, which forces the change. Note in the ticket _how_ identity was verified (with no password in the ticket).

</details>

---

## BAY-003: Account locked out

| Field            | Value                             |
| ---------------- | --------------------------------- |
| Reported by      | Sarah Chen (Office Administrator) |
| Help topic / SLA | Account & Password · Urgent       |
| Priority         | High                              |

**User's words:** "It says my account is locked. I'm sure I typed my password right!"

**Lab setup:** on CLIENT01, try to log in as `schen` with a wrong password **5 times**. Sarah can't sign in, so she phones the help desk and the agent logs the ticket (Source: Phone).

**Write-up**

- **Evidence found:** `Search-ADAccount -LockedOut` listed `schen`, and `Get-ADUser schen` showed `LockedOut = True` with the time of the last bad password attempt. On DC01, Security log **Event ID 4740** recorded the lockout with **Caller Computer Name: CLIENT01**, so the bad attempts came from her own workstation, not another device.
- **Root cause:** Five incorrect password attempts at the CLIENT01 sign-in screen (user confirmed a likely Caps Lock typo and no other devices) reached the domain lockout threshold of 5 and locked the account for 15 minutes.
- **Fix:** Called Sarah back to confirm her identity, then unlocked the account with `Unlock-ADAccount -Identity schen` (no password reset, since she knew her password). Confirmed `LockedOut = False`, and Sarah signed in on CLIENT01 with her normal password, with S: and the copier available.
- **Prevention / user advice:** Told Sarah to check Caps Lock, and that if she changes her password she should update it on any other device that uses her account (a common cause of repeat lockouts). Explained that accounts unlock automatically after 15 minutes. Checking Event 4740 for the source first means a device sending an old password would be found instead of the account being repeatedly unlocked.

<details><summary>Hint / expected approach</summary>

Confirm: `Search-ADAccount -LockedOut` or ADUC → schen → Account tab. Find the **source**: on DC01, Event Viewer → Windows Logs → Security → filter **Event ID 4740**. It names the caller computer (CLIENT01). Unlock: `Unlock-ADAccount schen` or the ADUC checkbox. Ask her whether her password changed recently and whether she's logged in anywhere else (a phone or second PC with an old password is the classic repeat-lockout cause). Explain the policy: 5 attempts, 15 minutes. **Don't reset her password** if she knows it; unlocking is enough.

</details>

---

## BAY-004: "My S: drive is gone"

| Field            | Value                               |
| ---------------- | ----------------------------------- |
| Reported by      | Tom Bergeron (Shipping Coordinator) |
| Help topic / SLA | Network & Connectivity · Standard   |
| Priority         | Normal                              |

**User's words:** "The S: drive disappeared this morning. I need the shipping schedule on it!"

**Lab setup:** on DC01, **move `tbergeron` out of `Bayview\Users\Shipping` into the default `Users` container** (simulating an admin mistake). Log in as `tbergeron` on CLIENT01.

**Write-up**

- **Triage questions asked:** Is anyone else in Shipping missing S:? (No, single user.) When did it start? (This morning.) Has anything changed on your PC? (No.) Tom also reported the help desk portal returned "access denied", so he phoned it in and the ticket was logged by the agent (Source: Phone).
- **Diagnostic commands and what they showed:**
  - Before the ticket, an existing S: mapping stayed visible after the move because the drive map was remembered in Tom's profile (`net use` showed it even though the GPO no longer applied). Removed it with `net use S: /delete` to reproduce the real symptom.
  - `gpresult /r` (as Tom, on CLIENT01): USER SETTINGS showed `CN=Tom Bergeron,CN=Users,DC=bayview,DC=internal`, and BAY-U-DriveMaps, BAY-U-Desktop and BAY-U-Printers were missing from Applied Group Policy Objects.
  - `Get-ADUser tbergeron | Select DistinguishedName` (DC01) confirmed the account was in the built-in `CN=Users` container instead of `OU=Shipping,OU=Users,OU=Bayview`.
- **Root cause:** Tom's account had been moved out of `Bayview\Users\Shipping` into the built-in Users container (simulated admin mistake). GPOs can't be linked to that container, so none of the `BAY-U-*` user policies applied, including the S: drive map. The osTicket LDAP plugin only searches `OU=Bayview`, so the same move also broke his portal sign-in. His GG-Shipping membership was unaffected, because OU placement and group membership are separate.
- **Fix + verification:** Moved the account back with `Move-ADObject -TargetPath "OU=Shipping,OU=Users,OU=Bayview,DC=bayview,DC=internal"` and confirmed the new DN. On CLIENT01 as Tom: `gpupdate /force`, then signed out and back in. S: returned, `S:\Shipping` opened, `gpresult /r` showed the Shipping OU with BAY-U-DriveMaps applied, and Tom could sign in to the help desk portal again.
- **Prevention:** Check OU placement when moving or creating accounts (the Idea 3 onboarding scripts will place users in the correct OU automatically). Tick **"Remove this item when it is no longer applied"** on GPO drive maps so remembered drives don't hide a policy problem. Watch for one cause producing several symptoms: here a single misplaced account broke both drive mapping and help desk sign-in.

<details><summary>Hint / expected approach</summary>

Scope first: is it just Tom? (Log in as `schen`, and her S: is fine, so it's one user.) On CLIENT01 as Tom: `gpresult /r` shows `BAY-U-DriveMaps` **missing** from Applied GPOs. Check Tom's OU in ADUC: he's in `Users`, where the GPO isn't linked. Move him back to `Bayview\Users\Shipping`, `gpupdate /force`, log off and on. S: returns. Prevention: check the OU when moving or creating accounts; the Idea 3 scripts will place users in the right OU automatically.

</details>

---

## BAY-005: Access denied to the Management folder

| Field            | Value                         |
| ---------------- | ----------------------------- |
| Reported by      | Priya Nair (Accounts Payable) |
| Help topic / SLA | Access Request · Standard     |
| Priority         | Normal                        |

**User's words:** "I get 'access denied' on the Management folder. I need the vendor contracts in there to process invoices."

**Lab setup:** nothing to break. This is working as designed. Log in as `pnair` and try to open `S:\Management`.

**Write-up**

- **Is this a fault or a request?** A request, not a fault. `Get-ADUser pnair -Properties MemberOf` showed Priya is in GG-Office only, and the Management folder's NTFS permissions allow GG-Management only, so "access denied" was the permissions working as designed. Clarified with Priya that she needs to **read** the vendor contracts to match invoices, not edit them, and not the rest of the Management folder.
- **Who approved it, and how:** Replied to Priya with the "Request needs manager approval" response and kept the ticket open. Karen Walsh (General Manager, data owner for Management files) approved **read-only access to vendor contracts only**; the approval was recorded as an internal note on the ticket before any change was made.
- **Action taken:**
  - Created `Management\Vendor Contracts` for the contracts, instead of opening up the whole Management folder.
  - Created the global security group `GG-Contracts-Read` and gave it **Read & execute** on that folder only.
  - Added Priya to `GG-Contracts-Read` (not to GG-Management, which would have granted far more than she needs).
  - Added a **V: (Vendor Contracts)** drive map to BAY-U-DriveMaps, targeted at `GG-Contracts-Read`. Priya can open the subfolder by path without rights on its parent, thanks to the default "Bypass traverse checking" right.
  - Checked the result with **Effective Access** for `pnair` (read only, no write, modify or delete).
  - Verified as Priya after signing out and back in: V: appeared, the contract opened, saving a new file was denied, and `S:\Management` was still denied.
- **Message to the user:**

  > Hi Priya,
  >
  > Karen has approved your request, and you now have read-only access to the vendor contracts. You'll find them on the new V: drive (Vendor Contracts). You can open and read the contracts but can't change them, and the rest of the Management folder stays private.
  >
  > If you need anything else in there, just ask and I'll check with Karen.
  >
  > Thanks,
  > Eric

<details><summary>Hint / expected approach</summary>

This is **not** a fault. Permissions are working. It's an **access request**, and access to management data needs the **data owner's approval** (Karen). Reply to Priya that the request has been sent for approval. In the lab, play Karen: she approves **read-only** access to just the contracts, not the whole Management folder. Best practice is a subfolder `Management\Vendor Contracts` with a new group `GG-Contracts-Read` (Read) and Priya added to it, rather than putting her in GG-Management. She must **log off and on** (her group membership is fixed at logon). Verify she can read contracts but can't open the rest. Interview point: **least privilege** plus **approval before access**.

</details>

---

## BAY-006: Printer missing

| Field            | Value                             |
| ---------------- | --------------------------------- |
| Reported by      | Sarah Chen (Office Administrator) |
| Help topic / SLA | Printer · Standard                |
| Priority         | Normal                            |

**User's words:** "The office copier isn't in my printer list anymore."

**Lab setup:** on DC01, **remove `schen` from `GG-Office`**. Log in as `schen` on CLIENT01 (log off and on first).

**Write-up**

- **Diagnostic steps:**
  - Scope: the copier was still deployed for other targeted users (Karen), so the printer and print server were fine. Single user.
  - `gpresult /r` (as Sarah): **BAY-U-Printers was applied**, so the GPO reached her. The printer inside it uses item-level targeting (GG-Office **or** GG-Management), so the problem had to be her group membership.
  - `whoami /groups | findstr GG-`: no GG-Office in her token.
  - DC01 Security log, **Event ID 4729** (member removed from a security-enabled global group): showed `schen` removed from GG-Office by `adm-emignardi`, with the time, and no ticket for the change.
- **Root cause:** Sarah had been removed from GG-Office (simulated unapproved change). Without that group, the printer's item-level targeting skipped her, so the copier wasn't deployed at sign-in.
- **Fix + verification:** Confirmed Sarah (Office Administrator) should still have Office access, then re-added her with `Add-ADGroupMember -Identity GG-Office -Members schen`. After she signed out and back in: Office-Copier was back in Printers & scanners, `S:\Office` opened again, and `whoami /groups` listed GG-Office.
- **Side effects noticed:**
  - The same group controls **S:\Office** access, so she had also lost that folder even though she only reported the printer. Checking related access caught it before she ran into it.
  - While setting up the problem, `S:\Office` stayed accessible after the removal even though `whoami /groups` no longer showed GG-Office: most likely Windows was reusing a cached connection and Kerberos ticket to DC01. I cleared them with `klist purge` and `net use S: /delete` and signed in again, but didn't re-test the folder before moving on, so this wasn't confirmed. **Lesson:** removing access doesn't affect a session that's already open until its tickets refresh, which is why access removals (especially for leavers) also mean signing the user out or disabling the account.
  - Group changes should go through a ticket, so there's an approval record to match Event 4729 against.

<details><summary>Hint / expected approach</summary>

Is the printer up for others? (Log in as `kwalsh`: it's there.) So it's user-specific. `gpresult /r` as Sarah: `BAY-U-Printers` applies, but its item-level targeting checks group membership. `whoami /groups` shows **no GG-Office**. Also check S:\Office, which she'll have lost too (a good side effect to notice). Re-add her to GG-Office, log off and on, and the printer returns. Prevention: group changes should come through a ticket. Note which ticket or person removed her (check DC01's Security log, **Event ID 4729**, if auditing captured it).

</details>

---

## BAY-007: Print jobs stuck in the queue

| Field            | Value                                 |
| ---------------- | ------------------------------------- |
| Reported by      | Sarah Chen (Office Administrator) |
| Help topic / SLA | Printer · Standard                    |
| Priority         | Normal                                |

**User's words:** "I sent a document to the copier 3 times and nothing came out."

**Lab setup:** as `schen` on CLIENT01, print a test page to `Office-Copier` 3 times. The copier IP has no device, so the jobs sit in the queue.
*(Originally planned with Mike Kowalski added temporarily to GG-Office, but the copier wouldn't deploy or connect for him even though BAY-U-Printers applied, so the ticket was run as Sarah instead. Mike's printer connection problem is logged as a separate follow-up, BAY-012.)*

**Write-up**

- **What the queue showed:** Print Management → Office-Copier → Open Printer Queue (and `Get-PrintJob -PrinterName Office-Copier`) showed Sarah's 3 jobs stuck and never completing. Office-Copier is a shared queue, so the problem would affect everyone who prints to it, not just Sarah.
- **Root cause:** The copier itself was offline. `Test-NetConnection 10.10.10.50 -Port 9100` returned `TcpTestSucceeded: False`, meaning nothing answered on the standard network-printing port, while the print server and its queue were working. Staff near the copier reported an error code on its display, which pointed to a hardware fault (simulated: the lab has no device at that IP).
- **Action taken (including escalation):**
  - Asked Sarah whether she still needed the queued jobs. She would resend, so I cleared them with `Get-PrintJob -PrinterName Office-Copier | Remove-PrintJob` to avoid 3 duplicate copies printing once the copier came back. (If the jobs had refused to delete, the next step would have been stopping the spooler, clearing `C:\Windows\System32\spool\PRINTERS`, and restarting it, after warning users, since that interrupts all printing on the server.)
  - Escalated the hardware fault to the copier vendor (fictional "Lakeshore Office Systems", ref LOS-4471, ETA next business day) and tracked it as a **task** on the ticket.
  - Kept the ticket **open** and gave Sarah a workaround (print to PDF and save to `S:\Office`) with the expected repair time.
  - After the vendor repair (simulated), closed the task, told Sarah to resend, and resolved the ticket.
- **Message to the user:**

  > Hi Sarah,
  >
  > The office copier is offline with a hardware fault, so nothing can print to it right now, for anyone. I've cleared your 3 stuck jobs so you won't get duplicates later, and I've booked a service call with the copier company. A technician is expected tomorrow morning.
  >
  > In the meantime, you can print to PDF and save documents to S:\Office, or I can help you get something printed another way if it's urgent.
  >
  > I'll update you as soon as it's fixed.
  >
  > Thanks,
  > Eric

  Follow-up after the repair: "The copier has been repaired and is working again. Please go ahead and resend your documents, and let me know if they don't come out."

<details><summary>Hint / expected approach</summary>

On DC01: Print Management → Printers → `Office-Copier` → **Open Printer Queue**. The jobs show "Error" or are stuck. Test the device: `Test-NetConnection 10.10.10.50 -Port 9100` fails, so the **copier is offline**. Clear the stuck jobs (cancel them, or for a corrupt queue: `Stop-Service Spooler`, clear `C:\Windows\System32\spool\PRINTERS`, `Start-Service Spooler`; know this procedure). Since the device itself is down, **escalate** to the copier vendor (fictional "Lakeshore Office Systems") and tell Mike the ETA and a workaround (print to PDF and save to S:\Production). This ticket shows **escalation**, which the Zavasoft listing asks for. Remove Mike from GG-Office afterwards.

</details>

---

## BAY-008: Software request (7-Zip)

| Field            | Value                               |
| ---------------- | ----------------------------------- |
| Reported by      | Tom Bergeron (Shipping Coordinator) |
| Help topic / SLA | Software Request · Standard         |
| Priority         | Low                                 |

**User's words:** "A supplier sends packing lists as .7z files and I can't open them. Can I get 7-Zip?"

**Lab setup:** nothing to break. Confirm 7-Zip isn't installed on CLIENT01.

**Write-up**

- **Approval / checks before installing:** Confirmed 7-Zip wasn't already installed on CLIENT01. Checked that it's free and open source (LGPL, fine for business use), that the installer was the official MSI from 7-zip.org (already in `\\DC01\Software$`), and that no existing approved tool covered `.7z` files (Windows opens `.zip` but not `.7z`). Recorded the approval as an internal note before deploying. Priority set to Low, since Tom could keep working while it was set up.
- **Deployment method and why:** Deployed with Group Policy software installation instead of installing by hand. Added the MSI to **BAY-C-Software** (Computer Configuration → Software Settings → Software installation) using the **UNC path** `\\DC01\Software$\...msi`, set to **Assigned**, and linked the GPO to `Bayview\Computers\Workstations`. Assigning it to computers means it installs automatically at startup on every workstation, the same way each time, with no admin rights needed for the user. A local `C:\` path would have failed, because the client installs from the network. The `Software$` share gives Domain Computers read access, since the computer account does the install at startup.
- **Verification:** Ran `gpupdate /force` on CLIENT01 and restarted when prompted (computer software installs only at startup). Signed in as Tom: 7-Zip was in Installed apps and the Start menu, and `gpresult /r /scope computer` listed BAY-C-Software under Applied Group Policy Objects. Replied to Tom with how to open the supplier's `.7z` files and resolved the ticket.

<details><summary>Hint / expected approach</summary>

Check that the software is approved and free for business use (7-Zip is, under the LGPL). Standard users can't install software, which is correct, so deploy it centrally: in `BAY-C-Software`, go to Computer Config → Policies → Software Settings → **Software installation** → New Package → **UNC path** `\\DC01\Software$\7z….msi` (never a local `C:\` path) → **Assigned**. Link the GPO to `Workstations`. On CLIENT01: `gpupdate /force`, then **reboot** (computer software installs only at startup). Verify 7-Zip appears in Installed apps. Bonus: `gpresult /r /scope computer`.

</details>

---

## BAY-009: "Internet works but nothing else does"

| Field            | Value                           |
| ---------------- | ------------------------------- |
| Reported by      | Dan Rossi (Machinist)           |
| Help topic / SLA | Network & Connectivity · Urgent |
| Priority         | High                            |

**User's words:** "Websites work fine, but company links with the full server name won't open, and Windows showed an error about the domain. My S: drive still works though."

**Lab setup:** on CLIENT01 as `.\localadmin`, set the network adapter's DNS manually to **8.8.8.8** (simulating a contractor "fixing" the internet). Then, as `drossi`, run `ipconfig /flushdns`. Without that, the DNS cache and short-name fallback (NetBIOS/LLMNR) hide the problem, so S: and `\\DC01` keep working. Submit the ticket as Dan from the portal at `http://10.10.10.1:8080`; it still loads because it's addressed by IP, not by name.

**Write-up**

- **Diagnostic commands and output:**
  - `ipconfig /all`: **DNS Servers: 8.8.8.8** instead of `10.10.10.10`; the IP address from DHCP was normal.
  - `ping 10.10.10.10`: replies, so the network path to DC01 was fine.
  - `nslookup dc01.bayview.internal`: failed; the query went to Google's public DNS, which knows nothing about the internal domain.
  - `nslookup dc01.bayview.internal 10.10.10.10`: succeeded, so DC01's DNS was healthy and the PC was asking the wrong server.
  - `nslookup microsoft.com`: succeeded, which explains why websites still worked.
  - Symptoms before the fix: `\\dc01.bayview.internal\Company` couldn't be found and `gpupdate /force` failed, while `S:` and `\\DC01` still opened.
- **Theory → test → result:**
  - *Network down?* → ping DC01 → replies → ruled out.
  - *DC01's DNS broken?* → `nslookup` directly against 10.10.10.10 → works → ruled out.
  - *Client using the wrong DNS server?* → `ipconfig /all` + `nslookup` via the default server → 8.8.8.8, internal names fail → **confirmed**.
  - *Why does S: still work?* Short names like `DC01` can be resolved by broadcast fallback (NetBIOS/LLMNR) on the same subnet, and the DNS cache had also held DC01's address until `ipconfig /flushdns`. Full names (FQDNs) and domain functions such as Group Policy need real DNS, so they failed. That's why wrong DNS often looks like a partial, confusing outage.
- **Root cause:** The adapter's DNS server had been set by hand to 8.8.8.8 (simulated contractor change made with local admin rights), so the PC couldn't resolve anything in `bayview.internal`.
- **Fix + verification:** Opened the adapter's IPv4 settings with the **local** admin account (not Domain Admin, so domain admin credentials aren't exposed on a workstation) and set DNS back to **Obtain DNS server address automatically**. Ran `ipconfig /flushdns` and `ipconfig /renew`; `ipconfig /all` then showed DNS `10.10.10.10` from DHCP. As Dan: `nslookup dc01.bayview.internal` worked, `\\dc01.bayview.internal\Company` opened, and `gpupdate /force` completed without errors.
- **Prevention:** Only IT should have local admin rights. Standard users like Dan can't change adapter settings, so the change came from an admin account. Manage local admin passwords centrally (Microsoft LAPS). Let DHCP hand out DNS settings instead of configuring them by hand. When "the internet works but internal things don't", check DNS first.

<details><summary>Hint / expected approach</summary>

`ipconfig /all`: DNS server is `8.8.8.8` instead of `10.10.10.10`. `nslookup dc01.bayview.internal` fails because public DNS knows nothing about your internal domain, while `ping 10.10.10.10` works, so the network is fine and **DNS** is the problem. Fix: set the adapter back to **"Obtain DNS server address automatically"**, `ipconfig /flushdns`, `ipconfig /renew`, and verify with `nslookup`, S:, and `gpupdate`. Root cause: a manually set DNS server. Prevention: standard users can't change adapter settings; remove local admin rights from anyone who doesn't need them. Classic interview line: _"it's always DNS."_

</details>

---

## BAY-010: Nobody can sign in to the help desk

| Field            | Value                                                         |
| ---------------- | ------------------------------------------------------------- |
| Reported by      | Karen Walsh (by phone, since the portal won't take her login) |
| Help topic / SLA | Account & Password · Urgent                                   |
| Priority         | Emergency                                                     |

**User's words:** "Several people say the help desk site rejects their password, but Windows login works fine."

**Lab setup:** on DC01, **disable the `svc-osticket` account** in ADUC. Then try to sign in to the portal as `kwalsh`. Log the ticket yourself in the Staff Panel as **`ostadmin`** (the break-glass account, which is exactly why it exists).

**Write-up**

- **Scope (who's affected, what still works):** Every AD sign-in to osTicket failed, for end users (Karen) and agents (`emignardi`), while Windows sign-in worked for everyone. The local break-glass account `ostadmin` could still sign in. So AD was healthy and osTicket was running; only osTicket's connection to AD was failing. The ticket was logged by phone as `ostadmin`.
- **Diagnostic steps:**
  - Re-ran the RUNBOOK 6.3 `ldapsearch` bind test from the osTicket container. The first attempt returned `Invalid credentials (49)` with `data 52e` (wrong password) because I mistyped the password. AD only reports account restrictions such as "disabled" once the password is correct, so a typo hides the real cause. With the correct password it returned **`data 533` (account disabled)**.
  - Checked for an accidental lockout from the bad attempt (`LockedOut`, `BadLogonCount`) before retrying.
  - `Get-ADUser svc-osticket -Properties Enabled,...` showed `Enabled: False`.
  - DC01 Security log, **Event ID 4725** (a user account was disabled): `svc-osticket` disabled by `adm-emignardi`, with the time, and no change record.
- **Root cause:** The `svc-osticket` service account, which the LDAP plugin uses to search AD before checking each user's password, had been disabled (simulated: mistaken for an unused account). With the bind failing, every AD sign-in to osTicket failed, even though users' own accounts were fine.
- **Fix + verification:** Re-enabled the account with `Enable-ADAccount -Identity svc-osticket` and confirmed `Enabled: True`. Re-ran `ldapsearch` and got `result: 0 Success`. Signed in to the Agent Panel as `emignardi` and to the portal as `kwalsh`, both with AD passwords. Resolved the ticket from the `emignardi` account, which itself proved the fix.
- **Prevention:**
  - Added a description to the account in AD: *"Used by osTicket LDAP sign-in (read-only directory searches). Owner: IT. Do not disable."*
  - Keep a list of service accounts (what uses each one, who owns it) and route account changes through tickets.
  - Keep a tested break-glass local account on critical systems. `ostadmin` is how this outage could still be logged and worked.
  - Consider alerting on Event 4725 (account disabled) for accounts in the Service Accounts OU.
  - AD bind error codes are worth knowing: `52e` wrong password, `533` disabled, `775` locked out, `532` password expired, `701` account expired.

<details><summary>Hint / expected approach</summary>

Scope: Windows logins work, so AD itself is fine. Only the **app's** AD logins fail, so look at what the app uses to talk to AD: the service account. Run the RUNBOOK 6.3 `ldapsearch` from the container, which fails with **Invalid credentials (49)**. On DC01: ADUC shows `svc-osticket` **disabled**. The Security log on DC01 (**Event ID 4725**, a user account was disabled) shows who disabled `svc-osticket` and when. The `ldapsearch` error also includes `data 533`, AD's code for "account disabled". Re-enable it, re-test `ldapsearch`, then sign in to the portal as `kwalsh`. Prevention: document service accounts (what uses them, who owns them) and add a description in AD: _"Used by osTicket LDAP. Do not disable."_ (Add it now.)

</details>

---

## Stretch tickets (optional)

### BAY-011: "The trust relationship between this workstation and the primary domain failed"

**Lab setup:** on DC01, ADUC → CLIENT01 → right-click → **Reset Account**. Reboot CLIENT01 and try to log in as any domain user.

<details><summary>Hint</summary>Log in with the **local** admin account. Run `Test-ComputerSecureChannel` (returns False), then `Test-ComputerSecureChannel -Repair -Credential BAYVIEW\adm-emignardi`, then reboot. Know the older fix (rejoining the domain) and why `-Repair` is better: no reboot loop and no lost profile mappings.</details>

### BAY-012: Printer won't deploy or connect for one user (open follow-up)
Found during BAY-007: after adding `mkowalski` to GG-Office, `gpresult /r` showed BAY-U-Printers applied, but Office-Copier never appeared, and connecting manually through `\\DC01` didn't add it either. Sarah's deployment on the same PC works.
**Next steps:** as Mike, check Event Viewer → Application (source **Group Policy Printers**, often Event 4098) and **Microsoft → Windows → PrintService → Admin** for the error code, then work from there (driver installation restriction, permissions or spooler on CLIENT01).
