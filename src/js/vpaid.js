// version 0.2a

var vpaidjs = vpaidjs || {};

// defaults
vpaidjs.options = {
  volume: 0.8,
  swfPath: "vpaidjs.swf",
  autoplay: false,
  debug: false
};
vpaidjs.activeAds = {};

var VPAID = function(playerId, options) {
  var player = this;
  this.ad = new Object();

  this.playerId = playerId;
  this.options = vpaidjs.options;

  for (var option in options) {
    player.options[option] = options[option];
  }

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

    swfobject.embedSWF(player.options.swfPath, player.playerId, "100%", "100%", "10.5", "", flashvars, params, attributes, onCreate);
  };

  this.initAd = function (adTag) {
    player.ad.initAd(adTag, player.options.debug);
  };

  this.resizeAd = function (x, y) {
    player.ad.resizeAd(x, y);
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
    if (typeof player.ad !== "undefined") {
      player.ad.stopAd();
    }
    swfobject.removeSWF(player.playerId);
  };

  this.on = function(eventName, cb) {
    // also accept lists of events and space-delimited event strings
    var events = typeof eventName === "object" ? eventName : eventName.split(" ");

    for (i in events) {
      player.ad.addEventListener(events[i], cb);
    }
  };

  // utilities
  function onCreate(e) {
    if (!e.success || !e.ref) {
      vpaidjs.log("Failed to embed SWF.");
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
      vpaidjs.log(player.options.swfPath + " " + e.ref.PercentLoaded() + "% loaded.");
      if (e.ref.PercentLoaded() === 100) {
        player.ad = document.getElementById(player.playerId);

        if (typeof player.ad.initAd == "function") {
          clearInterval(adWait);
		
          // add to list of active players
          vpaidjs.activeAds[player.playerId] = player;

          startEvents();
        }
      }
    }, 100);
  }

  function startEvents() {
    if (player.options.tag) {
      player.initAd(player.options.tag);
    }

    if (player.options.autoplay) {
      player.on("AdReady", function(e, data) {
        player.startAd();
      });
    }

    player.on("AdStopped", function(e, data) {
      delete vpaidjs.activeAds[player.playerId];
    });

    if (typeof player.options.success === "function") {
      player.options.success();
    }
  }

  // now start it up
  this.create();
};

vpaidjs.log = function(message) {
  if (vpaidjs.options.debug) {
    try {
      window.top.console.log("vpaidjs: " + message);
    } catch(e) {}
  }
};

// TODO: document ExternalInterface bridge
vpaidjs.triggerEvent = function(objectId, eventType, dataObj) {
  vpaidjs.log("[vpaid.js] event: " + eventType);

  var targetPlayer = window.document.getElementById(objectId);
  var vpaidEvent = new CustomEvent(eventType, { detail: JSON.parse(dataObj) });

  targetPlayer.dispatchEvent(vpaidEvent);
};

vpaidjs.VPAIDEvents = ["AdReady", "AdLoading", "AdLoaded", "AdStarted", "AdPaused", "AdStopped", "AdLinearChange", "AdExpandedChange", "AdVolumeChange", "AdImpression", "AdVideoStart", "AdVideoFirstQuartile", "AdVideoMidpoint", "AdVideoThirdQuartile", "AdVideoComplete", "AdClickThru", "AdUserAcceptInvitation", "AdUserMinimize", "AdUserClose", "AdPlaying", "AdLog", "AdError", "AdSkipped", "AdSkippableStateChange", "AdSizeChange", "AdDurationChange", "AdInteraction"];

var __vpaidjs__ = window.vpaidjs = vpaidjs;
