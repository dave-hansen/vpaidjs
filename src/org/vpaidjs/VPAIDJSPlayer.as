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
    import flash.display.Sprite;
    import flash.external.ExternalInterface;

    import org.openvideoads.vast.VASTController;
    import org.openvideoads.vast.config.Config;
    import org.openvideoads.vast.config.ConfigLoadListener;
    import org.openvideoads.vast.config.groupings.VPAIDConfig;
    import org.openvideoads.vast.schedule.ads.AdSlot
    import org.openvideoads.vpaid.IVPAID;
    import org.openvideoads.util.DisplayProperties;

    import org.openvideoads.vast.events.VPAIDAdDisplayEvent;
    import org.openvideoads.vpaid.VPAIDEvent;

    public class VPAIDJSPlayer extends Sprite implements ConfigLoadListener {
        // lazy assignments because our JS overlay doesn't have control bars
        private var _controlBarHeight:Number = -1;
        private var _controlBarWidth:Number = 0;

        private var _vastController:VASTController;
        private var _display:DisplayProperties;

         //  XXX: no idea why the width has to be pinned in order to fill the region...
        private var _playerWidth:Number = 500;
        private var _playerHeight:Number = 375;

        private var _playerVolume:Number = 1;         // 100%

        public function VPAIDJSPlayer():void {
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

            _vastController.addEventListener(VPAIDAdDisplayEvent.AD_LOG, externalAdLog);
            _vastController.disableRegionDisplay();

            _display = new DisplayProperties(
                this,
                _playerWidth,
                _playerHeight,
                'normal',
                _vastController.getActiveDisplaySpecification(false),
                false,
                _controlBarWidth,
                _controlBarHeight
            );

            _vastController.enableRegionDisplay(_display);

            // Ok, let's load up the VAST data from our Ad Server
            _vastController.load();
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

        protected function externalAdLog(event:VPAIDAdDisplayEvent):void {
            var message:String = "";
            try {
              message = event.data.message;
            } catch(e) {}

            ExternalInterface.call("vpaidjs.AdLog", message);
        }

        protected function triggerJsEvent(eventName:String):void {
            ExternalInterface.call("vpaidjs.Event", eventName);
        }

        /**
         *  JAVASCRIPT API
         */

        public function jsVolume(level:Number):void {
            var ad:IVPAID = _vastController.getActiveVPAIDAd();
            if (_vastController != null && ad != null) {
                if (ad != null) {
                    ad.adVolume = _playerVolume;
                }
                _playerVolume = level;
            }
        }

        //  Request and parse VPAID, given the JSON from Javascript interface
        public function jsInitAd(ovaConfig:Object):void {
            if (ovaConfig != null) {
                _vastController = new VASTController();
                _vastController.startStreamSafetyMargin = 100;
                _vastController.endStreamSafetyMargin = 300;

                var playerConfig:Config = new Config();
                playerConfig.playerConfig = _vastController.getDefaultPlayerConfig();

                _vastController.initialise(ovaConfig, false, this, playerConfig);
            }
        }

        public function jsStartAd(adSlotIndex:Number=0):void {
            if (_vastController != null) {
                // TODO: play all scheduled ads if adSlotIndex not defined
                var slot:AdSlot = _vastController.adSchedule.adSlots[adSlotIndex];

                _vastController.playVPAIDAd(slot, false, false, _playerVolume);
            }
        }

        public function jsStopAd():void {
            var ad:IVPAID = _vastController.getActiveVPAIDAd();
            if (_vastController != null && ad != null) {
                ad.stopAd();
                triggerJsEvent(VPAIDEvent.AdStopped);
            }
        }

        public function jsSkipAd():void {
            var ad:IVPAID = _vastController.getActiveVPAIDAd();
            if (_vastController != null && ad != null) {
                ad.skipAd();
            }
        }

        public function jsResizeAd(width:Number, height:Number):void {
            if(_vastController != null && _display != null) {
                // TODO: resize AND scale, but not beyond the initial values; re-align to center if you're really cool
                _display.displayWidth = width;
                _display.displayHeight = height;

                _vastController.resizeOverlays(_display);
            }
        }

        // TODO: check if ad is capable of being paused AND currently playing
        public function jsPauseAd():void {
            var ad:IVPAID = _vastController.getActiveVPAIDAd();
            if (_vastController != null && ad != null) {
                ad.pauseAd();
            }
        }

        // TODO: check if ad is capable of being paused AND currently paused
        public function jsResumeAd():void {
            var ad:IVPAID = _vastController.getActiveVPAIDAd();
            if (_vastController != null && ad != null) {
                ad.resumeAd();
            }
        }

        // TODO: don't work; probably need to check if possible/allowed
        public function jsExpandAd():void {
            var ad:IVPAID = _vastController.getActiveVPAIDAd();
            if (_vastController != null && ad != null) {
                ad.expandAd();
            }
        }

        // TODO: don't work; probably need to check if possible/allowed
        public function jsCollapseAd():void {
            var ad:IVPAID = _vastController.getActiveVPAIDAd();
            if (_vastController != null && ad != null) {
                ad.collapseAd();
            }
        }
    }
}