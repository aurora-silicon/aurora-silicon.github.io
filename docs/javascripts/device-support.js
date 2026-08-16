/* Device support modals for the feature-support catalog.
 *
 * Adding a machine:   add one CATALOG line, keyed by its device ID.
 * Recording a state:  add an entry to STATES, keyed by device ID, mapping a
 *                     feature name to "works", "partial" or "none".
 *
 * Any feature without a recorded state renders as "not recorded". Nothing here
 * asserts support; the states are deliberately empty until measured.
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

  /* deviceId: [model, chip, socId, profile] */
  var CATALOG = {
    /* M1 */
    j274:  ["Mac mini", "M1", "t8103", "desktop"],
    j293:  ["MacBook Pro 13-inch", "M1", "t8103", "laptop"],
    j313:  ["MacBook Air", "M1", "t8103", "laptop"],
    j456:  ["iMac 24-inch, 4x USB-C", "M1", "t8103", "imac"],
    j457:  ["iMac 24-inch, 2x USB-C", "M1", "t8103", "imac"],
    j314s: ["MacBook Pro 14-inch", "M1 Pro", "t6000", "laptop"],
    j316s: ["MacBook Pro 16-inch", "M1 Pro", "t6000", "laptop"],
    j314c: ["MacBook Pro 14-inch", "M1 Max", "t6001", "laptop"],
    j316c: ["MacBook Pro 16-inch", "M1 Max", "t6001", "laptop"],
    j375c: ["Mac Studio", "M1 Max", "t6001", "desktop"],
    j375d: ["Mac Studio", "M1 Ultra", "t6002", "desktop"],

    /* M2 */
    j413:  ["MacBook Air 13-inch", "M2", "t8112", "laptop"],
    j493:  ["MacBook Pro 13-inch", "M2", "t8112", "laptop"],
    j473:  ["Mac mini", "M2", "t8112", "desktop"],
    j415:  ["MacBook Air 15-inch", "M2", "t8112", "laptop"],
    j414s: ["MacBook Pro 14-inch", "M2 Pro", "t6020", "laptop"],
    j416s: ["MacBook Pro 16-inch", "M2 Pro", "t6020", "laptop"],
    j474s: ["Mac mini", "M2 Pro", "t6020", "desktop"],
    j414c: ["MacBook Pro 14-inch", "M2 Max", "t6021", "laptop"],
    j416c: ["MacBook Pro 16-inch", "M2 Max", "t6021", "laptop"],
    j475c: ["Mac Studio", "M2 Max", "t6021", "desktop"],
    j475d: ["Mac Studio", "M2 Ultra", "t6022", "desktop"],
    j180d: ["Mac Pro", "M2 Ultra", "t6022", "desktop"],

    /* M3 */
    j433:  ["iMac 24-inch, 2x USB-C", "M3", "t8122", "imac"],
    j434:  ["iMac 24-inch, 4x USB-C", "M3", "t8122", "imac"],
    j504:  ["MacBook Pro 14-inch", "M3", "t8122", "laptop"],
    j613:  ["MacBook Air 13-inch", "M3", "t8122", "laptop"],
    j615:  ["MacBook Air 15-inch", "M3", "t8122", "laptop"],
    j514s: ["MacBook Pro 14-inch", "M3 Pro", "t6030", "laptop"],
    j516s: ["MacBook Pro 16-inch", "M3 Pro", "t6030", "laptop"],
    j514c: ["MacBook Pro 14-inch", "M3 Max, 16-core", "t6031", "laptop"],
    j516c: ["MacBook Pro 16-inch", "M3 Max, 16-core", "t6031", "laptop"],
    j514m: ["MacBook Pro 14-inch", "M3 Max, 14-core", "t6034", "laptop"],
    j516m: ["MacBook Pro 16-inch", "M3 Max, 14-core", "t6034", "laptop"],
    j575d: ["Mac Studio", "M3 Ultra", "t6032", "desktop"],

    /* M4 */
    j604:  ["MacBook Pro 14-inch", "M4", "t8132", "laptop"],
    j773g: ["Mac mini", "M4", "t8132", "desktop"],
    j623:  ["iMac 24-inch, 2x USB-C", "M4", "t8132", "imac"],
    j624:  ["iMac 24-inch, 4x USB-C", "M4", "t8132", "imac"],
    j713:  ["MacBook Air 13-inch", "M4", "t8132", "laptop"],
    j715:  ["MacBook Air 15-inch", "M4", "t8132", "laptop"],

    /* Recorded by the team; no upstream device trees yet. */
    j813:  ["MacBook Air", "M5", "t8142", "laptop"],
    j700:  ["MacBook Neo", "A18 Pro", "t8140", "laptop"]
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

    var note = el("p", "device-modal__note");
    note.textContent =
      "No support states are recorded for this machine yet. The feature list " +
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
      entry[1] + " · " + entry[2] + " · " + id;

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

    var cells = document.querySelectorAll(".id-table td code, .split-table td code");
    Array.prototype.forEach.call(cells, function (code) {
      var id = code.textContent.trim();
      if (!CATALOG[id]) return;
      if (code.parentNode.classList.contains("device-link")) return;

      var button = el("button", "device-link");
      button.type = "button";
      button.setAttribute("aria-label", "Support detail for " + id);
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
