---
title: Secure Boot
---

# Secure Boot

Notes on the Apple Silicon secure boot chain, the Secure Enclave's part in it,
and what a non-macOS operating system has to work within. Scope is M-series
Apple Silicon.

!!! warning "Work in progress — externally sourced only"

    Nothing on this page has been verified by our own reverse engineering or
    hardware probing. Every claim comes from the external sources listed at the
    bottom: Apple's platform security documentation, Asahi Linux's boot
    documentation, and community reports. Treat it as a reading of the public
    record, not as measured fact. Where sources conflict or fall silent, that is
    called out rather than smoothed over.

## Two chains, not one

Apple Silicon runs two independent secure boot chains. The Application
Processor's is the one most documentation describes; the Secure Enclave has its
own, rooted in different immutable code and keyed separately.

| | Application Processor | Secure Enclave |
| --- | --- | --- |
| Root of trust | Boot ROM (SecureROM) | Secure Enclave Boot ROM |
| Payload | LLB → iBoot → kernel | sepOS |
| Verification | Image4 manifest chain | Hash and signature check by SEP Boot ROM |
| Failure mode | DFU | SEP unusable until reset |
| Keys | — | UID (per device), GID (per SoC model) |

The two are coupled but not nested: iBoot allocates the memory the SEP Boot ROM
then initialises with cryptographic protections before sepOS loads.

## SEP boot chain

The Secure Enclave Boot ROM is immutable and is the SEP's hardware root of
trust. It receives the sepOS image and checks its hash and signature to confirm
sepOS is authorised for that device. A failed check leaves the Secure Enclave
unusable until reset rather than falling back.

From A13 onward a **Boot Monitor** strengthens this: it hashes the loaded sepOS,
updates System Coprocessor Integrity Protection settings to permit execution,
and maintains a running hash across boot. Apple's stated intent is that OS
keybinding cannot be bypassed even given a Secure Enclave ROM vulnerability.

Supporting hardware, per Apple's documentation:

| Component | Function |
| --- | --- |
| Memory Protection Engine | Encrypts SEP memory, AES in MAC-XEX mode, with authentication tags |
| Anti-replay (A11/S4+) | One-off numbers in dedicated SRAM |
| Secure Enclave AES Engine | Keys stay internal, unreadable even to sepOS |
| Public Key Accelerator | Asymmetric crypto; OS-bound keys combine UID with the sepOS hash |
| Secure Storage Component | Non-volatile, counter lockboxes |

UID and GID are not accessible over JTAG. GID being per-SoC-model rather than
per-device is why SEP firmware cannot be decrypted or substituted on a target
machine — a point that constrains everything downstream.

## AP boot chain

| Stage | Location | Responsibility |
| --- | --- | --- |
| SecureROM | On-die, immutable | Verifies and loads stage 1 from NOR; DFU on failure |
| LLB / iBoot1 | NOR | Reads `boot-volume` from NVRAM, queries the SEP for the proposed or blessed policy hash, loads LocalPolicy, loads system-paired firmware |
| iBoot2 | Preboot volume | Loads macOS-paired firmware, evaluates LocalPolicy directives, loads the Boot Kernel Collection |
| Kernel | — | SCIP applied to lock memory regions |

LocalPolicy is read from the iSCPreboot partition at
`/<volume-group-uuid>/LocalPolicy/<policy-hash>.img4`, mounted at
`/System/Volumes/iSCPreboot`. LLB consults the SEP-attached Secure Storage
Component for anti-replay values, which is what blocks both OS version rollback
and security policy downgrade.

Community reports note the policy is two files, not one: the `.img4` is the base
boot policy and a companion `.fuos.im4m` is the fuOS extension. They also warn
that `bputil -d` elides fields, so dumping the ASN.1 directly is the reliable
way to read what a policy actually contains.

## Runtime monitors — SPTM and TXM

A layer our earlier reading of the boot chain missed entirely, and the one that
most affects newer silicon.

iBoot locates two Image4 payloads co-packaged with the kernelcache —
`Ap,SecurePageTableMonitor` and `Ap,TrustedExecutionMonitor` — and carves out
the physical regions reserved for them from the device tree. The **Secure Page
Table Monitor** runs at a guarded level above the kernel with exclusive control
of frame management and page-table updates; the lower-privileged **Trusted
Execution Monitor** enforces the code-execution policy. XNU becomes a client of
SPTM rather than an owner of its own page tables, and a TXM compromise does not
imply an SPTM bypass.

Apple documents SPTM and TXM as replacing the Page Protection Layer on **A15 and
M2 or later**, built on an evolution of the Fast Permission Restrictions
primitive. Community reports from mid-2026 state that under macOS 27 the monitors
extend to everything, A13 included — newer than Apple's published wording, which
may simply lag.

Two consequences matter for booting anything else:

| Boot object | SPTM |
| --- | --- |
| Raw binary | Not loaded — reported plainly as "there is no sptm in raw boot mode" |
| Mach-O | Loaded; the object runs under SPTM |

Kernels built with SPTM enabled carry a distinct `__TEXT_BOOT_EXEC` entry point,
observed present for T6020 and T6041 and absent for T6000. SPTM is also why m1n1
lacks M4-and-later support: hypervising macOS requires putting SPTM in the
hypervisor too, which is active work rather than a solved problem.

### Exclaves

Newer still, and specific to our targets. Exclavecore is described as a separate
RTOS running in the guarded execution environment under SPTM acting as its
hypervisor, hosting applets that hold resources the kernel cannot reclaim —
the mechanism behind indicator-light guarantees for camera and microphone.

Community reporting from July 2026 puts exclaves on **A18 Pro and M5 only** under
macOS 27, with SPTM everywhere. The open question raised in the same discussion,
and not answered there, is whether a kernel on such a machine can boot at all
without an exclavecore image loaded, since the kernel may expect exclaves to be
running. That is unresolved and directly relevant to
[A18 Pro](../../feature-support/a18-pro.md) and [M5](../../feature-support/m5.md).

## LocalPolicy

An Image4 file — ASN.1 DER — signed by the Secure Enclave rather than by Apple
centrally. That local signing is the mechanism that makes per-device policy
possible at all. Apple documents these 4CC fields:

| Field | Meaning |
| --- | --- |
| `lpnh` | LocalPolicy Nonce Hash, SHA-384; anti-replay |
| `rpnh` | Remote Policy Nonce Hash; changes on Find My enrolment change |
| `ronh` | recoveryOS Nonce Hash |
| `nsih` | Next Stage Image4 Manifest Hash — iBoot, trust cache, kernel collection, SSV root hash |
| `spih` | Cryptex1 Image4 Manifest Hash |
| `stng` | Cryptex1 generation, 64-bit anti-replay counter |
| `auxp` | AuxKC policy hash — the user-authorised kext list |
| `auxi` | AuxKC Image4 Manifest Hash |
| `auxr` | AuxKC receipt hash |
| `coih` | **CustomOS Image4 Manifest Hash — mutable in 1TR only** |
| `vuid` | APFS volume group UUID |
| `kuid` | KEK group UUID |
| `prot` | Paired recoveryOS hash, linking recoveryOS to the macOS policy |

Security mode flags, and the SIP bits alongside them:

| Flag | Effect |
| --- | --- |
| `smb0` | Accept a globally-signed manifest (Reduced Security) |
| `smb1` | **Accept a Secure Enclave–signed custom kernel (Permissive Security)** |
| `smb2` | Allow third-party kexts via AuxKC |
| `smb3` | Device-management authentication |
| `smb4` | Apple School/Business Manager control |
| `sip0` | SIP policy bits, 64-bit |
| `sip1` | Permit SSV verification failure |
| `sip2` | Disable CTRR locking |
| `sip3` | Disable boot-args NVRAM filtering |

The policy also carries the Owner Identity Certificate and an embedded
RemotePolicy. The Owner Identity Key that signs it is protected under the same
key hierarchy as Sealed Key Protection, sharing the KEK with the volume
encryption key.

## Security modes

| Mode | Signature | Consequence |
| --- | --- | --- |
| Full | Personalised, ECID-bound, from Apple's signing server | Usable only by that CPU; rollback protection |
| Reduced | Global vendor signature | Older macOS, third-party kexts; no rollback protection |
| Permissive | Locally Secure Enclave–signed | Custom kernels accepted; untrusted kernels get restricted key access |

Signature verification still runs the whole chain under Permissive Security —
the mode changes *which* signing authority is acceptable, not whether
verification happens. There is no equivalent to switching Secure Boot off on a
PC. Full and Reduced are reachable from Startup Security Utility; Permissive is
command-line only, which Apple documents as deliberate discouragement.

## Boot modes and 1TR

The SEP tracks which boot mode the machine is in and gates privileged operations
on it. Editing boot policy is restricted to **1TR** — One True recoveryOS,
entered by holding the power button, which loads the recoveryOS paired with the
active OS volume. Asahi's documentation reports that attempting a restricted
operation outside 1TR fails with error 11, "AP boot mode".

Sources disagree on the mode count. Asahi's boot flow page lists five modes the
SEP distinguishes — macOS, 1TR, plain recoveryOS, kcOS and restoreOS — while
their platform introduction describes three states. This is unresolved here.

1TR requires machine owner credentials and grants both boot policy modification
and pairing authority. Notably for third-party OS work, the SEP is put to sleep
before the OS kernel boots, which is why it is optional for a non-macOS system —
and why anything wanting the SEP later has to bring it up itself.

## Custom OS path

Installing a third-party kernel means downgrading a policy to Permissive
Security and inserting the custom object's hash into the boot policy, which
preserves the chain rather than breaking it. iBoot2 will then load that specific
image only; replacing it requires another trip through 1TR. Asahi terms the
result **fuOS**.

Community reports describe the practical workflow: `kmutil configure-boot --raw
--entry-point 2048 --lowest-virtual-address 0` to install a raw boot object, a
permissive policy applied with `bputil`, and `bputil -n` to revert to XNU before
an update or recovery. Reports also note a bare boot object with nothing
concatenated reaches its proxy, while appended parameters caused reliable iBoot
panics traced to installer-added trailing zero padding.

The individual `bputil` flags are not authoritatively documented in public
sources. Reported usage varies in flag order — both `-nckas` and `-nkcas`
appear — so treat the string as reported usage rather than a verified
decomposition.

Two further points from the community record. The SEP itself refuses to sign a
custom kernel outside 1TR, which is the enforcement behind the policy gate
rather than a userspace check. And the raw-versus-Mach-O split above is the
consequential choice: a raw boot object escapes SPTM entirely, while a Mach-O
object is loaded under it.

## Implications for Windows

This section is inference from the sources above, not a finding.

Windows on ARM expects UEFI Secure Boot: a firmware-held key hierarchy of
PK, KEK, `db` and `dbx`, verifying PE binaries at load. Apple Silicon provides
none of that. Its chain is Image4 manifests verified by immutable ROM and
iBoot, with per-device personalisation and SEP-held anti-replay — a different
mechanism with a different trust root.

The consequence is that the two chains cannot be reconciled, only joined
end to end. The Apple chain terminates at whatever object the boot policy
blesses; any UEFI environment above that starts its own chain, and its Secure
Boot state is a property of that environment rather than of the machine. Asahi's
stated design goal is the same shape: independent secure boot chains per OS,
bridged to the machine chain of trust by the user with owner credentials at
install time.

Consequences worth confirming before relying on them: Permissive Security is a
prerequisite for any custom boot object, so a machine running Windows this way
is not in Full Security; and the SEP sleeping before kernel handoff means SEP
services — see [Touch ID](touch-id.md) — need explicit bring-up rather than
inheritance.

## Open questions

- Whether a kernel on an exclave-bearing machine (A18 Pro, M5) can boot without
  an exclavecore image loaded. Raised in community discussion, unanswered.
- Whether the SEP distinguishes three boot modes or five, and what `kcOS` and
  `restoreOS` gate specifically.
- The exact semantics of each `bputil` flag, and whether flag order is
  significant.
- How Image4 personalisation interacts with a boot object that is not an XNU
  kernel collection, beyond the raw entry-point and virtual-address parameters
  reported above.
- Whether SPTM changes anything about policy evaluation itself, as opposed to
  post-handoff enforcement.
- Whether anything in the SEPROM handshake changes between M-series generations
  in a way that affects policy evaluation, as distinct from the sepOS boot
  differences noted for T8110 and later.

## Sources

- Apple Platform Security — [boot process for a Mac with Apple silicon](https://support.apple.com/guide/security/boot-process-for-a-mac-with-apple-silicon-secac71d5623/web)
- Apple Platform Security — [contents of a LocalPolicy file](https://support.apple.com/guide/security/contents-a-localpolicy-file-mac-apple-silicon-secc745a0845/web)
- Apple Platform Security — [Startup Disk security policy control](https://support.apple.com/guide/security/startup-disk-security-policy-control-sec7d92dc49f/web)
- Apple Platform Security — [Secure Enclave](https://support.apple.com/guide/security/secure-enclave-sec59b0b31ff/web)
- Apple Platform Security — [operating system integrity, SPTM and TXM](https://support.apple.com/guide/security/operating-system-integrity-sec8b776536b/web)
- Wang et al. — [*Modern iOS Security Features: A Deep Dive into SPTM, TXM, and Exclaves*](https://arxiv.org/pdf/2510.09272), arXiv 2510.09272
- Asahi Linux — [Apple Silicon boot flow](https://asahilinux.org/docs/fw/boot/)
- Asahi Linux — [introduction to Apple Silicon, recoveryOS and 1TR](https://asahilinux.org/docs/platform/introduction/)
- Asahi Linux — [open OS platform interoperability](https://asahilinux.org/docs/platform/open-os-interop/)
- Asahi Linux — [SEP documentation](https://asahilinux.org/docs/hw/soc/sep/)
- `#asahi-dev` and `#asahi-re` on OFTC — community reports, logs spanning
  2021-01-05 to 2026-08-17. Where these conflict with older published
  documentation, the later report is preferred and the conflict noted in place.
