var vpaidjs = vpaidjs || {};

vpaidjs.version = "1.0.0";

// defaults
vpaidjs.options = {
  volume: 0.8,
  swfPath: "vpaidjs.swf",
  autoplay: false,
  timeout: 0,
  debug: false
};

vpaidjs.activeAds = {};

var VPAID = function(playerId, options) {
  var player = this;
  this.ad = {};
  this.registeredEvents = [];

  this.playerId = playerId;
  this.options = vpaidjs.options;
  this.container = window.document.getElementById(playerId).parentElement;

  for (var option in options) {
    this.options[option] = options[option];
  }

  this.width = this.container.style.width.replace(/[^\d]/g, "") ||
               this.container.width;

  this.height = this.container.style.height.replace(/[^\d]/g, "") ||
                this.container.parentElement.height;

  this.create = function() {
    var flashvars = {};
    var params = {
      wmode: "transparent",
      allowScriptAccess: "always",
      bgcolor: "#000000"
    };

    // TODO: do i need these?
    var attributes = {
      id: player.playerId,
      name: player.playerId
    };

    swfobject.embedSWF(
      player.options.swfPath,
      player.playerId,
      this.width,
      this.height,
      "10.5",
      "",
      flashvars,
      params,
      attributes,
      onCreate
    );
  };

  this.initAd = function (adTag) {
    player.ad.initAd(adTag);
  };

  this.resizeAd = function (width, height) {
    if (player.ad) {
      player.ad.resizeAd(width, height);

      player.width = width;
      player.height = height;
    }
  };

  this.startAd = function () {
    player.ad.startAd();
  };

  this.stopAd = function() {
    player.ad.stopAd();
  };

  this.skipAd = function() {
    player.ad.skipAd();
  };

  this.pauseAd = function() {
    player.ad.pauseAd();
  };

  this.resumeAd = function() {
    player.ad.resumeAd();
  };

  this.expandAd = function() {
    player.ad.expandAd();
  };

  this.collapseAd = function() {
    player.ad.collapseAd();
  };

  this.volume = function (level) {
    player.ad.volume(level);
  };

  this.destroy = function () {
    for (var i in player.registeredEvents) {
      var eventName = player.registeredEvents[i][0];
      var cb = player.registeredEvents[i][1];

      // TODO XXX verify works with new CustomEvent work
      document.removeEventListener(eventName, cb);
    }

    swfobject.removeSWF(player.playerId);
    delete vpaidjs.activeAds[player.playerId];
  };

  this.on = function(eventName, cb) {
    // also accept lists of events and space-delimited event strings
    var events = typeof eventName === "object" ? eventName : eventName.split(" ");

    for (var i in events) {
      var nsEvent = player.playerId + ":" + events[i];

      document.addEventListener(nsEvent, cb);
      player.registeredEvents.push([nsEvent, cb]);
    }
  };

  // utilities
  function onCreate(e) {
    if (!e.success || !e.ref) {
      vpaidjs.util.log("Failed to embed SWF.");
      return false;
    }
    waitForSwfObject(e);
  }

  function waitForSwfObject(e) {
    var swfWait = setInterval(function () {
      if (typeof e.ref.PercentLoaded !== "undefined" && e.ref.PercentLoaded()) {
        clearInterval(swfWait);
        waitForAdInterface(e);
      }
    }, 100);
  }

  function waitForAdInterface(e) {
    // timer to wait for swf object to fully load
    var adWait = setInterval(function() {
      vpaidjs.util.log(player.options.swfPath + " " + e.ref.PercentLoaded() + "% loaded.");
      if (e.ref.PercentLoaded() === 100) {
        player.ad = document.getElementById(player.playerId);

        // add to list of active players
        vpaidjs.activeAds[player.playerId] = player;

        if (typeof player.ad.initAd === "function") {
          clearInterval(adWait);
          onAdInit();
        }
      }
    }, 100);
  }

  function onAdInit() {
    if (player.options.tag) {
      player.initAd(player.options.tag);
    }

    if (player.options.autoplay) {
      player.on("AdLoaded", function(e) {
        player.startAd();
      });
    }

    // you never know when sound gets turned on
    player.on("AdStarted AdVideoStart", function(e) {
      player.volume(player.options.volume);
    });

    player.on("AdComplete", function(e) {
      player.destroy();
    });

    if (typeof player.options.success === "function") {
      player.options.success();
    }
  }

  // now start it up
  this.create();
};

vpaidjs.util = {};
vpaidjs.util.log = function(message) {
  if (vpaidjs.options.debug) {
    try {
      window.top.console.log("vpaidjs: " + message);
    } catch(e) {}
  }
};

// TODO XXX make sure this is ie?+ compatible
vpaidjs.util.ping = function(uri) {
  var xhr = new XMLHttpRequest();
  xhr.open("GET", encodeURI(uri));
  xhr.send();     // NOTE: no HTTP status code checking
};

vpaidjs.util.triggerEvent = function(objectId, eventType, dataObj) {
  var vpaidEvent = document.createEvent("Event");
  vpaidEvent.initEvent(objectId + ":" + eventType, true, true);
  vpaidEvent.detail = JSON.parse(dataObj || "{}");

  // TODO XXX test IE legacy support: ie8? ie9/10? ie11?
  document.dispatchEvent(vpaidEvent);

  var logMessage = eventType;
  if (vpaidEvent.detail.hasOwnProperty("data") && vpaidEvent.detail.data !== "{}") {
    logMessage += ": " + JSON.stringify(vpaidEvent.detail.data);
  }
  vpaidjs.util.log(logMessage);
};

vpaidjs.VPAIDEvents = ["AdReady", "AdLoading", "AdLoaded", "AdStarted", "AdPaused", "AdStopped", "AdLinearChange", "AdExpandedChange", "AdVolumeChange", "AdImpression", "AdVideoStart", "AdVideoFirstQuartile", "AdVideoMidpoint", "AdVideoThirdQuartile", "AdVideoComplete", "AdClickThru", "AdUserAcceptInvitation", "AdUserMinimize", "AdUserClose", "AdPlaying", "AdLog", "AdError", "AdSkipped", "AdSkippableStateChange", "AdSizeChange", "AdDurationChange", "AdInteraction", "MouseOver", "AdComplete"];

window.vpaidjs = vpaidjs;

