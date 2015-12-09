// version 0.1.1a


var vpaidjs = vpaidjs || {};

// defaults
vpaidjs.options = {
  volume: 0.8,
  swfPath: "vpaidjs.swf",
  debug: false
};

vpaidjs.VPAIDEvents = ["AdReady", "AdLoading", "AdLoaded", "AdStarted", "AdPaused", "AdStopped", "AdLinearChange", "AdExpandedChange", "AdVolumeChange", "AdImpression", "AdVideoStart", "AdVideoFirstQuartile", "AdVideoMidpoint", "AdVideoThirdQuartile", "AdVideoComplete", "AdClickThru", "AdUserAcceptInvitation", "AdUserMinimize", "AdUserClose", "AdPlaying", "AdLog", "AdError", "AdSkipped", "AdSkippableStateChange", "AdSizeChange", "AdDurationChange", "AdInteraction"];
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

    swfobject.embedSWF(
      player.options.swfPath,
      player.playerId,
      "100%",
      "100%",
      "10.5",
      "",
      flashvars,
      params,
      attributes,
      onCreate
    );
  };

  /*
   *  VPAID Protocol Methods
   */

  this.initAd = function(adTag) {
    player.ad.initAd(adTag, player.options.debug);
  };

  this.startAd = function() {
    player.ad.startAd();
  };

  this.resizeAd = function(x, y) {
    player.ad.resizeAd(x, y);
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

  this.volume = function(level) {
    player.ad.volume(level);
  };

  this.destroy = function() {
    if (player.ad) {
      player.ad.stopAd();
    }
    swfobject.removeSWF(player.playerId);
  };

  this.on = function(eventName, cb) {
    player.ad.addEventListener(eventName, cb);
  };

  // now start it up
  this.create();

  // take extra care verifying SWF and ad fully ready
  function onCreate(e) {
    if (!e.success || !e.ref ) {
      vpaidjs.log("Failed to embed SWF.");
      return false;
    }

    // wait just a smidge for Flash to start
    var readyCheck = setInterval(function () {
      if (typeof e.ref.PercentLoaded === "function") {
        clearInterval(readyCheck);
        // timer to wait for swf object to fully load
        var loadCheck = setInterval(function () {
          vpaidjs.log(player.options.swfPath + " " + e.ref.PercentLoaded() + "% loaded." );
          if (e.ref.PercentLoaded() === 100) {
            player.ad = document.getElementById(player.playerId);

            if (typeof player.ad.initAd == "function") {
              clearInterval(loadCheck);

              // add to list of active players
              vpaidjs.activeAds[player.playerId] = player;

              if (typeof player.options.success == "function") {
                player.options.success();
              }
            }
          }
        }, 100);
      }
    }, 100);
  }


  // TODO: is there an onDestroy() or whatever to remove completed ad from vpaidjs.activePlayers?
  //       elsewise, will need to add a AdComplete event within object itself; hopefully doesn't override external one too?

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
  var targetPlayer = window.document.getElementById(objectId);
  var vpaidEvent = new CustomEvent(eventType, JSON.parse(dataObj));

  targetPlayer.dispatchEvent(vpaidEvent);

  //$("#" + objectId).trigger(eventType, JSON.parse(dataObj));
  vpaidjs.log("[vpaid.js] event: " + eventType);
};


var __vpaidjs__ = window.vpaidjs = vpaidjs;
