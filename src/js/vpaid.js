// version 0.2a

var vpaidjs = vpaidjs || {};

// defaults
vpaidjs.options = {
  volume: 0.8,
  swfPath: "vpaidjs.swf",
  autoplay: false,
  debug: false
}

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

  // these don't need paramters passed, so assign them blindly
  this.stopAd = player.ad.stopAd;
  this.skipAd = player.ad.skipAd;
  this.pauseAd = player.ad.pauseAd;
  this.resumeAd = player.ad.resumeAd;
  this.expandAd = player.ad.expandAd;
  this.collapseAd = player.ad.collapseAd;

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
    // gather all events into list
    var events = typeof eventName === "object" ? eventName : eventName.replace(/\s/g, '').split(',');

    for (i in events) {
      player.ad.addEventListener(events[i], cb);
    }
  };

  // now start it up
  this.create();

  // take extra care verifying SWF and ad fully ready
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

          if (player.options.tag) {
            player.initAd(player.options.tag);
          }

          if (player.options.autoplay) {
            player.on("AdReady", function(e) {
              player.startAd();
            });
          }

          player.on("AdStopped", function(e) {
            delete vpaidjs.activeAds[player.playerId];
          });

          if (typeof player.options.success == "function") {
            player.options.success();
          }
        }
      }
    }, 100);
  }

};

vpaidjs.log = function(message) {
  if (vpaidjs.options.debug) {
    try {
      window.top.console.log("vpaidjs: " + message);
    } catch(e) {}
  }
};

// in order to bridge events, actionscript objects arrive here as json strings,
//   these are converted to javascript objects and sent on their way
vpaidjs.triggerEvent = function(objectId, eventType, dataObj) {
  vpaidjs.log("[vpaid.js] event: " + eventType);

  var targetPlayer = window.document.getElementById(objectId);
  var vpaidEvent = new CustomEvent(eventType, JSON.parse(dataObj));

  targetPlayer.dispatchEvent(vpaidEvent);
};

vpaidjs.VPAIDEvents = ["AdReady", "AdLoading", "AdLoaded", "AdStarted", "AdPaused", "AdStopped", "AdLinearChange", "AdExpandedChange", "AdVolumeChange", "AdImpression", "AdVideoStart", "AdVideoFirstQuartile", "AdVideoMidpoint", "AdVideoThirdQuartile", "AdVideoComplete", "AdClickThru", "AdUserAcceptInvitation", "AdUserMinimize", "AdUserClose", "AdPlaying", "AdLog", "AdError", "AdSkipped", "AdSkippableStateChange", "AdSizeChange", "AdDurationChange", "AdInteraction"];

var __vpaidjs__ = window.vpaidjs = vpaidjs;
