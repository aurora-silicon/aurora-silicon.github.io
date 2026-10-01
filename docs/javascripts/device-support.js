/* Device support modals for the feature-support catalog.
 *
 * Adding a machine:   add one CATALOG line, keyed by its device ID.
 * Recording a state:  add an entry to STATES, keyed by device ID, mapping a
 *                     feature name to "works", "partial" or "none".
 *
 * Any feature without a recorded state renders as "not recorded". Nothing here
 * records Windows support only. Linux evidence is linked separately.
 */

(function () {
  "use strict";

  /* Feature lists are provisional. Trim each profile to the machine's actual
   * hardware as states are recorded — port sets differ between models. */
  var FEATURES = {
    laptop: [
      ["Platform", ["UEFI boot", "Windows Boot Manager", "SMP / all cores", "Internal storage"]],
      ["Display & input", ["Internal display", "Brightness control", "Keyboard", "Keyboard backlight", "Trackpad"]],
      ["Media", ["Speakers", "Microphone", "Camera", "Headset jack"]],
      ["Connectivity", ["USB-C", "Thunderbolt / USB4", "Wi-Fi", "Bluetooth"]],
      ["Power", ["Battery / charging", "Sleep / resume"]],
      ["Graphics", ["GPU acceleration"]]
    ],
    /* 14/16-inch MacBook Pro: the laptop set plus the hardware specific to
     * these machines — HDMI, SDXC slot, Touch ID, a ProMotion display and
     * active cooling. */
    mbp: [
      ["Platform", ["UEFI boot", "Windows Boot Manager", "SMP / all cores", "Internal storage", "Nested virtualization"]],
      ["Display & input", ["Internal display", "ProMotion (120 Hz / VRR / HDR)", "Brightness control", "Keyboard", "Keyboard backlight", "Trackpad", "Power button", "Touch ID"]],
      ["Media", ["Speakers", "Microphone", "Camera", "Headset jack"]],
      ["Connectivity", ["USB-C", "Thunderbolt / USB4", "HDMI", "SDXC card slot", "Wi-Fi", "Bluetooth"]],
      ["Power", ["Battery / charging", "Fan control", "Sleep / resume"]],
      ["Graphics", ["GPU acceleration"]]
    ],
    desktop: [
      ["Platform", ["UEFI boot", "Windows Boot Manager", "SMP / all cores", "Internal storage"]],
      ["Display", ["Display output", "HDMI"]],
      ["Media", ["Speaker", "Headset jack"]],
      ["Connectivity", ["USB-A", "USB-C", "Thunderbolt / USB4", "Ethernet", "Wi-Fi", "Bluetooth"]],
      ["Power", ["Sleep / resume"]],
      ["Graphics", ["GPU acceleration"]]
    ],
    imac: [
      ["Platform", ["UEFI boot", "Windows Boot Manager", "SMP / all cores", "Internal storage"]],
      ["Display", ["Internal display", "Brightness control"]],
      ["Media", ["Speakers", "Microphone", "Camera", "Headset jack"]],
      ["Connectivity", ["USB-C", "Thunderbolt / USB4", "Ethernet", "Wi-Fi", "Bluetooth"]],
      ["Power", ["Sleep / resume"]],
      ["Graphics", ["GPU acceleration"]]
    ]
  };

  /* deviceId: [model, chip, socId, profile]. Public catalog snapshot: 2026-10-01. */
  var CATALOG = {
    j274: ["Mac mini","M1","t8103","desktop"],
    j293: ["MacBook Pro 13-inch","M1","t8103","laptop"],
    j313: ["MacBook Air","M1","t8103","laptop"],
    j314c: ["MacBook Pro 14-inch","M1 Max","t6001","mbp"],
    j314s: ["MacBook Pro 14-inch","M1 Pro","t6000","mbp"],
    j316c: ["MacBook Pro 16-inch","M1 Max","t6001","mbp"],
    j316s: ["MacBook Pro 16-inch","M1 Pro","t6000","mbp"],
    j375c: ["Mac Studio","M1 Max","t6001","desktop"],
    j375d: ["Mac Studio","M1 Ultra","t6002","desktop"],
    j456: ["iMac 24-inch, 4× USB-C","M1","t8103","imac"],
    j457: ["iMac 24-inch, 2× USB-C","M1","t8103","imac"],
    j180d: ["Mac Pro","M2 Ultra","t6022","desktop"],
    j413: ["MacBook Air 13-inch","M2","t8112","laptop"],
    j414c: ["MacBook Pro 14-inch","M2 Max","t6021","mbp"],
    j414s: ["MacBook Pro 14-inch","M2 Pro","t6020","mbp"],
    j415: ["MacBook Air 15-inch","M2","t8112","laptop"],
    j416c: ["MacBook Pro 16-inch","M2 Max","t6021","mbp"],
    j416s: ["MacBook Pro 16-inch","M2 Pro","t6020","mbp"],
    j473: ["Mac mini","M2","t8112","desktop"],
    j474s: ["Mac mini","M2 Pro","t6020","desktop"],
    j475c: ["Mac Studio","M2 Max","t6021","desktop"],
    j475d: ["Mac Studio","M2 Ultra","t6022","desktop"],
    j493: ["MacBook Pro 13-inch","M2","t8112","laptop"],
    j433: ["iMac 24-inch, 2× USB-C","M3","t8122","imac"],
    j434: ["iMac 24-inch, 4× USB-C","M3","t8122","imac"],
    j504: ["MacBook Pro 14-inch","M3","t8122","mbp"],
    j514c: ["MacBook Pro 14-inch","M3 Max, 16-core","t6031","mbp"],
    j514m: ["MacBook Pro 14-inch","M3 Max, 14-core","t6034","mbp"],
    j514s: ["MacBook Pro 14-inch","M3 Pro","t6030","mbp"],
    j516c: ["MacBook Pro 16-inch","M3 Max, 16-core","t6031","mbp"],
    j516m: ["MacBook Pro 16-inch","M3 Max, 14-core","t6034","mbp"],
    j516s: ["MacBook Pro 16-inch","M3 Pro","t6030","mbp"],
    j575d: ["Mac Studio","M3 Ultra","t6032","desktop"],
    j613: ["MacBook Air 13-inch","M3","t8122","laptop"],
    j615: ["MacBook Air 15-inch","M3","t8122","laptop"],
    j575c: ["Mac Studio","M4 Max","t6041","desktop"],
    j604: ["MacBook Pro 14-inch","M4","t8132","mbp"],
    j614c: ["MacBook Pro 14-inch","M4 Max","t6041","mbp"],
    j614s: ["MacBook Pro 14-inch","M4 Pro","t6040","mbp"],
    j616c: ["MacBook Pro 16-inch","M4 Max","t6041","mbp"],
    j616s: ["MacBook Pro 16-inch","M4 Pro","t6040","mbp"],
    j623: ["iMac 24-inch, 2× USB-C","M4","t8132","imac"],
    j624: ["iMac 24-inch, 4× USB-C","M4","t8132","imac"],
    j713: ["MacBook Air 13-inch","M4","t8132","laptop"],
    j715: ["MacBook Air 15-inch","M4","t8132","laptop"],
    j773g: ["Mac mini","M4","t8132","desktop"],
    j773s: ["Mac mini","M4 Pro","t6040","desktop"],
    j704: ["MacBook Pro 14-inch","M5","t8142","mbp"],
    j714c: ["MacBook Pro 14-inch","M5 Max","t6050","mbp"],
    j714s: ["MacBook Pro 14-inch","M5 Pro","t6050","mbp"],
    j716c: ["MacBook Pro 16-inch","M5 Max","t6050","mbp"],
    j716s: ["MacBook Pro 16-inch","M5 Pro","t6050","mbp"],
    j775c: ["Mac Studio","M5 Max","t6050","desktop"],
    j775d: ["Mac Studio","M5 Ultra","t6050","desktop"],
    j813: ["MacBook Air 13-inch","M5","t8142","laptop"],
    j815: ["MacBook Air 15-inch","M5","t8142","laptop"],
    j873s: ["Mac mini","M5 Pro","t6050","desktop"],
    j873g: ["Mac mini","M6","t8152","desktop"],
    j700: ["MacBook Neo","A18 Pro","t8140","laptop"]
  };

  /* Dated Aurora Linux assessments, separate from Windows STATES below. */
  var LINUX_EVIDENCE = {
    j274: "/feature-support/linux/m1-mac-mini/",
    j293: "/feature-support/linux/m1-macbook-pro/",
    j313: "/feature-support/linux/m1-macbook-air/",
    j314c: "/feature-support/linux/m1-macbook-pro/",
    j314s: "/feature-support/linux/m1-macbook-pro/",
    j316c: "/feature-support/linux/m1-macbook-pro/",
    j316s: "/feature-support/linux/m1-macbook-pro/",
    j375c: "/feature-support/linux/m1-mac-studio/",
    j375d: "/feature-support/linux/m1-mac-studio/",
    j456: "/feature-support/linux/m1-imac/",
    j457: "/feature-support/linux/m1-imac/",
    j180d: "/feature-support/linux/m2-mac-pro/",
    j413: "/feature-support/linux/m2-macbook-air/",
    j414c: "/feature-support/linux/m2-macbook-pro/",
    j414s: "/feature-support/linux/m2-macbook-pro/",
    j415: "/feature-support/linux/m2-macbook-air/",
    j416c: "/feature-support/linux/m2-macbook-pro/",
    j416s: "/feature-support/linux/m2-macbook-pro/",
    j473: "/feature-support/linux/m2-mac-mini/",
    j474s: "/feature-support/linux/m2-mac-mini/",
    j475c: "/feature-support/linux/m2-mac-studio/",
    j475d: "/feature-support/linux/m2-mac-studio/",
    j493: "/feature-support/linux/m2-macbook-pro/",
    j433: "/feature-support/linux/m3-imac/",
    j434: "/feature-support/linux/m3-imac/",
    j504: "/feature-support/linux/m3-macbook-pro/",
    j514c: "/feature-support/linux/m3-macbook-pro/",
    j514m: "/feature-support/linux/m3-macbook-pro/",
    j514s: "/feature-support/linux/m3-macbook-pro/",
    j516c: "/feature-support/linux/m3-macbook-pro/",
    j516m: "/feature-support/linux/m3-macbook-pro/",
    j516s: "/feature-support/linux/m3-macbook-pro/",
    j575d: "/feature-support/linux/m3-mac-studio/",
    j613: "/feature-support/linux/m3-macbook-air/",
    j615: "/feature-support/linux/m3-macbook-air/",
    j575c: "/feature-support/linux/m4-mac-studio/",
    j604: "/feature-support/linux/m4-macbook-pro/",
    j614c: "/feature-support/linux/m4-macbook-pro/",
    j614s: "/feature-support/linux/m4-macbook-pro/",
    j616c: "/feature-support/linux/m4-macbook-pro/",
    j616s: "/feature-support/linux/m4-macbook-pro/",
    j623: "/feature-support/linux/m4-imac/",
    j624: "/feature-support/linux/m4-imac/",
    j713: "/feature-support/linux/m4-macbook-air/",
    j715: "/feature-support/linux/m4-macbook-air/",
    j773g: "/feature-support/linux/m4-mac-mini/",
    j773s: "/feature-support/linux/m4-mac-mini/",
    j704: "/feature-support/linux/m5-macbook-pro/",
    j714c: "/feature-support/linux/m5-macbook-pro/",
    j714s: "/feature-support/linux/m5-macbook-pro/",
    j716c: "/feature-support/linux/m5-macbook-pro/",
    j716s: "/feature-support/linux/m5-macbook-pro/",
    j775c: "/feature-support/linux/m5-mac-studio/",
    j775d: "/feature-support/linux/m5-mac-studio/",
    j813: "/feature-support/linux/m5-macbook-air/",
    j815: "/feature-support/linux/m5-macbook-air/",
    j873s: "/feature-support/linux/m5-mac-mini/",
    j873g: "/feature-support/linux/m6-mac-mini/",
    j700: "/feature-support/linux/a18-macbook-neo/"
  };

  /* Recorded support states, keyed by device ID then feature name. Feature
   * names must match the FEATURES strings above exactly; unmatched names are
   * reported in the browser console rather than failing silently.
   *
   * Valid states: "works" (green), "partial" (amber), "none" (red).
   * Leave a feature out entirely to keep it at "not recorded" — that is the
   * right thing to do for anything untested.
   *
   * A state may be either a plain string, or a [state, note] pair when the
   * bare word needs qualifying:
   *
   *   "Keyboard": "works",
   *   "USB-C": ["partial", "no hotplug or USB 3.0"]
   */
  var STATES = {
    j316s: {
      "UEFI boot": "works",
      "Windows Boot Manager": "works",
      "SMP / all cores": "works",
      "Internal display": "works",
      "Keyboard": "works",
      "Trackpad": "works",
      "USB-C": ["partial", "no hotplug or USB 3.0"]
    },

    /* MacBook Pro 14-inch, M2 Pro — the M2-series primary target. Recorded
     * from bring-up, 2026-08. These results qualify only this named board. */
    j414s: {
      "UEFI boot": "works",
      "Windows Boot Manager": "works",
      "SMP / all cores": ["works", "native P/E scheduling, cpufreq, power modes"],
      "Internal storage": "works",
      "Nested virtualization": ["none", "needed for WSL and VMs"],

      "Internal display": "works",
      "ProMotion (120 Hz / VRR / HDR)": ["none", "in progress"],
      "Keyboard": "works",
      "Keyboard backlight": "works",
      "Trackpad": ["works", "full gesture support"],
      "Power button": ["works", "bound to Win+L"],
      "Touch ID": ["none", "driver in development"],

      "Speakers": "none",
      "Microphone": "none",
      "Camera": "none",
      "Headset jack": "none",

      "USB-C": ["works", "USB 3; Ethernet via Realtek arm64 driver"],
      "Thunderbolt / USB4": "none",
      "HDMI": "none",
      "SDXC card slot": ["none", "in progress"],
      "Wi-Fi": "works",
      "Bluetooth": "works",

      "Battery / charging": ["works", "SMC battery and health reporting"],
      "Fan control": "works",
      "Sleep / resume": ["none", "deep sleep not implemented yet"],

      "GPU acceleration": ["partial", "Honeykrisp Vulkan and DXVK run; WDDM 2.1 in progress"]
    }
  };

  var LABELS = {
    works: "Working",
    partial: "Partial",
    none: "Not working",
    unknown: "Not recorded"
  };

  var dialog = null;

  function el(tag, cls, text) {
    var node = document.createElement(tag);
    if (cls) node.className = cls;
    if (text) node.textContent = text;
    return node;
  }

  function buildDialog() {
    dialog = el("dialog", "device-modal");
    dialog.setAttribute("aria-label", "Windows feature support");

    var head = el("div", "device-modal__head");
    var heading = el("div");
    heading.appendChild(el("p", "device-modal__title"));
    heading.appendChild(el("p", "device-modal__meta"));
    head.appendChild(heading);

    var close = el("button", "device-modal__close", "✕");
    close.setAttribute("aria-label", "Close");
    close.addEventListener("click", function () {
      dialog.close();
    });
    head.appendChild(close);

    dialog.appendChild(head);
    dialog.appendChild(el("div", "device-modal__body"));

    var evidence = el("p", "device-modal__evidence");
    var evidenceLink = el("a", "", "View the separate Aurora Linux assessment");
    evidence.appendChild(evidenceLink);
    dialog.appendChild(evidence);

    var note = el("p", "device-modal__note");
    note.textContent =
      "No Windows support states are recorded for this machine yet. The feature list " +
      "is provisional and will be trimmed to the machine's actual hardware.";
    dialog.appendChild(note);

    /* Clicking the backdrop closes; clicking the panel must not. */
    dialog.addEventListener("click", function (event) {
      if (event.target === dialog) dialog.close();
    });

    document.body.appendChild(dialog);
  }

  function openDevice(id) {
    var entry = CATALOG[id];
    if (!entry) return;
    if (!dialog || !dialog.isConnected) buildDialog();

    dialog.querySelector(".device-modal__title").textContent = entry[0];
    dialog.querySelector(".device-modal__meta").textContent =
      "Windows · " + entry[1] + " · " + entry[2] + " · " + id;

    dialog.querySelector(".device-modal__evidence a").href = LINUX_EVIDENCE[id];

    var body = dialog.querySelector(".device-modal__body");
    body.textContent = "";

    var recorded = STATES[id] || {};
    var groups = FEATURES[entry[3]] || FEATURES.laptop;
    var anyRecorded = false;

    /* A state keyed to a feature name this profile does not list would render
     * as nothing at all, so say so rather than dropping it silently. */
    var known = {};
    groups.forEach(function (group) {
      group[1].forEach(function (feature) {
        known[feature] = true;
      });
    });
    Object.keys(recorded).forEach(function (feature) {
      if (!known[feature]) {
        window.console.warn(
          "device-support: " + id + ' has a state for "' + feature +
          '", which is not a feature of the ' + entry[3] + " profile."
        );
      }
    });

    groups.forEach(function (group) {
      body.appendChild(el("p", "device-modal__group", group[0]));
      var list = el("div", "device-modal__feats");
      group[1].forEach(function (feature) {
        var value = recorded[feature];
        var state = "unknown";
        var note = "";

        if (typeof value === "string") {
          state = value;
        } else if (value && value.length) {
          state = value[0];
          note = value[1] || "";
        }
        if (state !== "unknown") anyRecorded = true;

        var pill = el("span", "feat feat--" + state, feature);
        if (note) pill.appendChild(el("span", "feat__note", note));
        pill.title = (LABELS[state] || LABELS.unknown) + (note ? " — " + note : "");
        list.appendChild(pill);
      });
      body.appendChild(list);
    });

    dialog.querySelector(".device-modal__note").hidden = anyRecorded;
    dialog.showModal();
  }

  function wire() {
    if (!dialog || !dialog.isConnected) buildDialog();

    /* The dialog is parented to <body>, which instant navigation leaves alone,
     * so it survives a page change — still open, if the reader left it open.
     * What it describes belongs to the page they have just left. */
    if (dialog.open) dialog.close();

    var cells = document.querySelectorAll(".id-table td code, .split-table td code");
    Array.prototype.forEach.call(cells, function (code) {
      var id = code.textContent.trim();
      if (!CATALOG[id]) return;
      if (code.parentNode.classList.contains("device-link")) return;

      var button = el("button", "device-link");
      button.type = "button";
      button.setAttribute("aria-label", "Windows support detail for " + id);
      code.parentNode.insertBefore(button, code);
      button.appendChild(code);
      button.addEventListener("click", function () {
        openDevice(id);
      });
    });
  }

  /* Instant navigation swaps content without a page load, so re-wire on each
   * document rather than only at startup. */
  if (typeof window.document$ !== "undefined" && window.document$.subscribe) {
    window.document$.subscribe(wire);
  } else if (document.readyState !== "loading") {
    wire();
  } else {
    document.addEventListener("DOMContentLoaded", wire);
  }
})();
