// version 0.1a1

var vpaidjs = vpaidjs || {};

// defaults
vpaidjs.options = {
  volume: 1,
  swfPath: "vpaidjs.swf",
  debug: false
};

var VPAID = function(playerId, options) {
  var player = this;
  this.ad = new Object;

  this.playerId = playerId;
  this.options = vpaidjs.options;
  this.baseVolume = vpaidjs.options.volume;
  this.isMuted = false;

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
      "10.5",   // XXX: not sure what's safe here
      "",
      flashvars,
      params,
      attributes,
      cbOnCreate
    );
  };

  /*
   *  VPAID Protocol Methods
   */

  this.initAd = function(config) {

    if (player.options.debug) {
      config.debug = {
        "levels": "fatal, config, vast_template, vpaid, http_calls, playlist, api"
      };
    }

    player.ad.initAd(config);
  };

  this.startAd = function() {
    player.ad.startAd();
    player.volume(player.baseVolume);
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
    // not implemented
  };

  this.resumeAd = function() {
    // not implemented
  };

  this.expandAd = function() {
    // not implemented
  };

  this.collapseAd = function() {
    // not implemented
  };


  this.volume = function(level) {
    if (level == 0) {
      player.isMuted = true;
    } else {
      player.isMuted = false;
      player.baseVolume = level;
    }

    // TODO: no idea why setting needs to happen twice, and only from JS
    player.ad.volume(level);
    player.ad.volume(level);
  };

  // works as a toggle too
  this.mute = function() {
    if (!player.isMuted) {
      player.volume(0);
    } else {
      player.volume(player.baseVolume);
    }
  };

  this.destroy = function() {
    swfobject.removeSWF(player.playerId);
  };

  // ridiculously overzealous way of verifying SWF fully loaded,
  // including the readiness of initAd() itself
  function cbOnCreate(e) {
    if (!e.success || !e.ref ) {
      vpaidjs.log("Failed to embed SWF.")
      return false;
    }

    // wait just a smidge for Flash to start
    var readyCheck = setInterval(function () {
      if (typeof e.ref.PercentLoaded !== "undefined" && e.ref.PercentLoaded()) {
        clearInterval(readyCheck);
        // timer to wait for swf object to fully load
        var loadCheck = setInterval(function () {
          vpaidjs.log(player.options.swfPath + " " + e.ref.PercentLoaded() + "% loaded." );
          if (e.ref.PercentLoaded() === 100) {
            player.ad = document.getElementById(player.playerId);

            if (typeof player.ad.initAd == "function") {
              if (typeof player.options.success == "function") {
                player.options.success();
              }
            }
            clearInterval(loadCheck);
          }
        }, 100);
      }
    }, 100);
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

// External function called from vpaidjs.swf
vpaidjs.AdLog = function(message) {
  vpaidjs.log("[AdLog] " + message)
};
var __vpaidjs__ = window.vpaidjs = vpaidjs;
