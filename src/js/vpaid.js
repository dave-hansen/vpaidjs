var _playerId;    // XXX: assumes only one player present at the time

var VPAID = function(playerId, options) {
  var vpaid = this;
  vpaid.options = options || {};
  vpaid.playerId = playerId;

  vpaid.swfPath = vpaid.options.swfPath || "vpaidjs.swf";

  this.create = function() {
    var flashvars = {
      autoplay: false,
      preload: false
    };

    var params = {
      wmode: "transparent",
      allowScriptAccess: "always",
      bgcolor: "#000000"
    };

    var attributes = {
      id: vpaid.playerId,
      name: vpaid.playerId
    };

    swfobject.embedSWF(
      vpaid.swfPath + "?ts=" + new Date().getTime(),
      vpaid.playerId,
      "100%",
      "100%",
      "10.3",
      "",
      flashvars,
      params,
      attributes,
      cbOnCreate
    );
  };

  this.init = function(config) {
    var el = document.getElementById(vpaid.playerId);
    el.init(config);
  };

  this.play = function() {
    var el = document.getElementById(vpaid.playerId);
    el.play();
  };

  function cbOnCreate(e) {
    if (!e.success || !e.ref ) {
      return false;
    }

    // wait just a smidge for Flash to start
    setTimeout(function () {
      if (typeof e.ref.PercentLoaded !== "undefined" && e.ref.PercentLoaded()) {
        // timer to wait for swf object to fully load
        var loadCheck = setInterval(function () {
          if (e.ref.PercentLoaded() === 100) {
            // TODO: fire off .on('loaded') event

            if (typeof vpaid.options.onSuccess == "function") {
              vpaid.options.onSuccess();
            }
            clearInterval(loadCheck);
          }
        }, 100);
      }
    }, 100);
  }

  this.create();
};


function onVPAIDEvent(event, message) {
  if(event == null) {
    return;
  }
  if (message) {
    $("#ad-log").append("<li style='font-size: 14px; margin: 10px;'>" + message + "</li>");
  }

  vpaidPrintDebug(event);
  $("#" + event).removeClass("status-inactive").addClass("status-active");
  switch(event) {
    case "loaded":
      if ($("#vpaidjs-autoplay").is(":checked")) {
        play();
      }
      break;
  }

  $("#" + _playerId).trigger(event);
}

function vpaidPrintDebug(output) {
  try {
    console.log(output);
  }
  catch(error) {}
}
