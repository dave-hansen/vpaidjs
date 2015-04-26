/**
 * Copyright (c) 2014 Dave Hansen <dave@davehansen.org>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

package org.vpaidjs {
    import com.adobe.serialization.json.JSON;
    import flash.display.Sprite;
    import flash.external.ExternalInterface;
    import flash.system.Security;

    import org.openvideoads.vast.VASTController;
    import org.openvideoads.vast.config.Config;
    import org.openvideoads.vast.config.ConfigLoadListener;
    import org.openvideoads.vast.config.groupings.VPAIDConfig;
    import org.openvideoads.vast.events.NonLinearSchedulingEvent;
    import org.openvideoads.vast.events.StreamSchedulingEvent;
    import org.openvideoads.vast.events.VPAIDAdDisplayEvent;
    import org.openvideoads.vast.schedule.ads.AdSlot
    import org.openvideoads.vpaid.IVPAID;
    import org.openvideoads.vpaid.VPAIDBase;
    import org.openvideoads.util.DisplayProperties;

    public class VPAIDJSPlayer extends Sprite implements ConfigLoadListener {
        private var _version:String = "0.1.1a";

        private var _ad:IVPAID = new VPAIDBase();
        private var _vastController:VASTController;
        private var _display:DisplayProperties;

         //  XXX: no idea why the width has to be pinned in order to fill the region...
        private var _playerWidth:Number = 500;
        private var _playerHeight:Number = 375;

        private var _playerVolume:Number = 1;         // 100%

        public function VPAIDJSPlayer():void {
            Security.allowDomain("*");
            registerExternalAPI();
        }

        // junk to statisfy inheritance
        public function isOVAConfigLoading():Boolean {
            return false;
        }

        // Called automatically by OVA when after .initAd() completes
        public function onOVAConfigLoaded():void {
            if (_vastController.config.adsConfig.vpaidConfig.hasLinearRegionSpecified() == false) {
                _vastController.config.adsConfig.vpaidConfig.linearRegion = VPAIDConfig.RESERVED_FULLSCREEN_TRANSPARENT;
            }

            if (_vastController.config.adsConfig.vpaidConfig.hasNonLinearRegionSpecified() == false) {
                _vastController.config.adsConfig.vpaidConfig.nonLinearRegion = VPAIDConfig.RESERVED_FULLSCREEN_TRANSPARENT;
            }

            _vastController.addEventListener(VPAIDAdDisplayEvent.LINEAR_COMPLETE, onComplete);
            _vastController.addEventListener(VPAIDAdDisplayEvent.LINEAR_LOADED, onLoaded);
            _vastController.addEventListener(VPAIDAdDisplayEvent.LINEAR_START, onStart);

            _vastController.addEventListener(VPAIDAdDisplayEvent.NON_LINEAR_START, onStart);
            _vastController.addEventListener(VPAIDAdDisplayEvent.NON_LINEAR_LOADED, onLoaded);
            _vastController.addEventListener(VPAIDAdDisplayEvent.NON_LINEAR_COMPLETE, onComplete);

            registerExternalEvent(VPAIDAdDisplayEvent.LINEAR_LOADING, "AdLoading");
            registerExternalEvent(VPAIDAdDisplayEvent.NON_LINEAR_LOADING, "AdLoading");
            registerExternalEvent(VPAIDAdDisplayEvent.LINEAR_LOADED, "AdLoaded");
            registerExternalEvent(VPAIDAdDisplayEvent.NON_LINEAR_LOADED, "AdLoaded");
            registerExternalEvent(VPAIDAdDisplayEvent.LINEAR_START, "AdStarted");
            registerExternalEvent(VPAIDAdDisplayEvent.NON_LINEAR_START, "AdStarted");
            registerExternalEvent(VPAIDAdDisplayEvent.LINEAR_PAUSE, "AdPaused");
            registerExternalEvent(VPAIDAdDisplayEvent.NON_LINEAR_PAUSE, "AdPaused");
            registerExternalEvent(VPAIDAdDisplayEvent.LINEAR_COMPLETE, "AdStopped");
            registerExternalEvent(VPAIDAdDisplayEvent.NON_LINEAR_COMPLETE, "AdStopped");
            registerExternalEvent(VPAIDAdDisplayEvent.LINEAR_LINEAR_CHANGE, "AdLinearChange");
            registerExternalEvent(VPAIDAdDisplayEvent.NON_LINEAR_LINEAR_CHANGE, "AdLinearChange");
            registerExternalEvent(VPAIDAdDisplayEvent.LINEAR_EXPANDED_CHANGE, "AdExpandedChange");
            registerExternalEvent(VPAIDAdDisplayEvent.NON_LINEAR_EXPANDED_CHANGE, "AdExpandedChange");
            registerExternalEvent(VPAIDAdDisplayEvent.LINEAR_VOLUME_CHANGE, "AdVolumeChange");
            registerExternalEvent(VPAIDAdDisplayEvent.NON_LINEAR_VOLUME_CHANGE, "AdVolumeChange");
            registerExternalEvent(VPAIDAdDisplayEvent.LINEAR_IMPRESSION, "AdImpression");
            registerExternalEvent(VPAIDAdDisplayEvent.NON_LINEAR_IMPRESSION, "AdImpression");
            registerExternalEvent(VPAIDAdDisplayEvent.VIDEO_AD_START, "AdVideoStart");
            registerExternalEvent(VPAIDAdDisplayEvent.VIDEO_AD_FIRST_QUARTILE, "AdVideoFirstQuartile");
            registerExternalEvent(VPAIDAdDisplayEvent.VIDEO_AD_MIDPOINT, "AdVideoMidpoint");
            registerExternalEvent(VPAIDAdDisplayEvent.VIDEO_AD_THIRD_QUARTILE, "AdVideoThirdQuartile");
            registerExternalEvent(VPAIDAdDisplayEvent.VIDEO_AD_COMPLETE, "AdVideoComplete");
            registerExternalEvent(VPAIDAdDisplayEvent.LINEAR_CLICK_THRU, "AdClickThru");
            registerExternalEvent(VPAIDAdDisplayEvent.NON_LINEAR_CLICK_THRU, "AdClickThru");
            registerExternalEvent(VPAIDAdDisplayEvent.LINEAR_USER_ACCEPT_INVITATION, "AdUserAcceptInvitation");
            registerExternalEvent(VPAIDAdDisplayEvent.NON_LINEAR_USER_ACCEPT_INVITATION, "AdUserAcceptInvitation");
            registerExternalEvent(VPAIDAdDisplayEvent.LINEAR_USER_MINIMIZE, "AdUserMinimize");
            registerExternalEvent(VPAIDAdDisplayEvent.NON_LINEAR_USER_MINIMIZE, "AdUserMinimize");
            registerExternalEvent(VPAIDAdDisplayEvent.LINEAR_USER_CLOSE, "AdUserClose");
            registerExternalEvent(VPAIDAdDisplayEvent.NON_LINEAR_USER_CLOSE, "AdUserClose");
            registerExternalEvent(VPAIDAdDisplayEvent.LINEAR_PLAYING, "AdPlaying");
            registerExternalEvent(VPAIDAdDisplayEvent.NON_LINEAR_PLAYING, "AdPlaying");
            registerExternalEvent(VPAIDAdDisplayEvent.AD_LOG, "AdLog");
            registerExternalEvent(VPAIDAdDisplayEvent.LINEAR_ERROR, "AdError");
            registerExternalEvent(VPAIDAdDisplayEvent.NON_LINEAR_ERROR, "AdError");

            // VPAID 2.x events
            registerExternalEvent(VPAIDAdDisplayEvent.SKIPPED, "AdSkipped");
            registerExternalEvent(VPAIDAdDisplayEvent.SKIPPABLE_STATE_CHANGE, "AdSkippableStateChange");
            registerExternalEvent(VPAIDAdDisplayEvent.SIZE_CHANGE, "AdSizeChange");
            registerExternalEvent(VPAIDAdDisplayEvent.DURATION_CHANGE, "AdDurationChange");
            registerExternalEvent(VPAIDAdDisplayEvent.AD_INTERACTION, "AdInteraction");

            // Extra events
            registerExternalEvent(NonLinearSchedulingEvent.SCHEDULE, "AdReady");
            registerExternalEvent(StreamSchedulingEvent.SCHEDULE, "AdReady");

            _vastController.disableRegionDisplay();

            _display = new DisplayProperties(
                this,
                _playerWidth,
                _playerHeight,
                'normal',
                _vastController.getActiveDisplaySpecification(false),
                false,
                0,
                -1
            );

            _vastController.enableRegionDisplay(_display);

            // Ok, let's load up the VAST data from our Ad Server
            _vastController.load();
        }

        // register an event to publish to the vpaid.js javascript ad object
        protected function registerExternalEvent(ovaEvent:String, vpaidEvent:String):void {
            _vastController.addEventListener(ovaEvent, function(event:*) {
                var dataObj:Object = new Object();
                dataObj["data"] = event.hasOwnProperty("data") ? event.data : null;

                if (event.hasOwnProperty("adSlot")) {
                    dataObj.adSlot = event.adSlot.toJSObject();
                } if (event.hasOwnProperty("stream")) {
                    dataObj.stream = event.stream.toJSObject();
                }

                // bridge as3 objects to js by sending it as a full JSON string
                var jsonData:String = com.adobe.serialization.json.JSON.encode(dataObj);
                ExternalInterface.call("vpaidjs.triggerEvent", ExternalInterface.objectID, vpaidEvent, jsonData);
            });
        }

        protected function onStart(event:VPAIDAdDisplayEvent):void {
            _ad = _vastController.getActiveVPAIDAd();
        }

        protected function onLoaded(event:VPAIDAdDisplayEvent):void {
        }

        protected function onComplete(event:VPAIDAdDisplayEvent):void {
            _ad = new VPAIDBase();
        }

         // Named in the same format as the IAB-specified AS3 interfact, just drop the 'Ad' suffix
        protected function registerExternalAPI():void {
            try {
                ExternalInterface.addCallback("initAd", jsInitAd);
                ExternalInterface.addCallback("startAd", jsStartAd);
                ExternalInterface.addCallback("resizeAd", jsResizeAd);
                ExternalInterface.addCallback("stopAd", jsStopAd);
                ExternalInterface.addCallback("pauseAd", jsPauseAd);
                ExternalInterface.addCallback("resumeAd", jsResumeAd);
                ExternalInterface.addCallback("skipAd", jsSkipAd);
                ExternalInterface.addCallback("expandAd", jsExpandAd);
                ExternalInterface.addCallback("collapseAd", jsCollapseAd);
                ExternalInterface.addCallback("volume", jsVolume);
            }
            catch (e:Error) {}
        }

        /**
         *  JAVASCRIPT API
         */

        public function jsVolume(level:Number):void {
            _playerVolume = level;
            if (_ad != null) {
                _ad.adVolume = level;
            }
        }

        //  Request, load, and prepare Flash adw
        public function jsInitAd(adTag:String, debug:Boolean):void {
            _vastController = new VASTController();
            _vastController.startStreamSafetyMargin = 100;
            _vastController.endStreamSafetyMargin = 300;

            var playerConfig:Config = new Config();
            playerConfig.playerConfig = _vastController.getDefaultPlayerConfig();

            var ovaConfig:Object = {
                ads: {
                    schedule: [{
                        tag: adTag,
                        position: "pre-roll"    // for OVA's sake, treat all as pre-roll
                    }]
                }
            };

            if (debug == true) {
                ovaConfig.debug = {
                    "levels": "fatal, config, vast_template, vpaid, http_calls, playlist, api"
                };
            }

            _vastController.initialise(ovaConfig, false, this, playerConfig);
        }

        public function jsStartAd(adSlotIndex:Number=0):void {
            if (_vastController != null) {
                // TODO: play all scheduled ads if adSlotIndex not defined
                var slot:AdSlot = _vastController.adSchedule.adSlots[adSlotIndex];

                _vastController.playVPAIDAd(slot, false, false, _playerVolume);
            }
        }

        public function jsStopAd():void {
            _ad.stopAd();
        }

        public function jsSkipAd():void {
            _ad.skipAd();
        }

        public function jsPauseAd():void {
            _ad.pauseAd();
        }

        public function jsResumeAd():void {
            _ad.resumeAd();
        }

        public function jsExpandAd():void {
            _ad.expandAd();
        }

        public function jsResizeAd(width:Number, height:Number):void {
            if(_vastController != null && _display != null) {
                // TODO: resize AND scale, but not beyond the initial values; re-align to center if you're really cool
                _display.displayWidth = width;
                _display.displayHeight = height;

                _vastController.resizeOverlays(_display);
            }
        }

        public function jsCollapseAd():void {
            _ad.collapseAd();
        }
    }
}
