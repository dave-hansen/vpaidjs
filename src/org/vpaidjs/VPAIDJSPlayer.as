/*
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

    import org.openvideoads.util.DisplayProperties;
    import org.openvideoads.vast.VASTController;
    import org.openvideoads.vast.config.Config;
    import org.openvideoads.vast.config.ConfigLoadListener;
    import org.openvideoads.vast.config.groupings.VPAIDConfig;
    import org.openvideoads.vast.schedule.ads.AdSlot

    import org.openvideoads.vpaid.VPAIDEvent;
    import org.openvideoads.vast.events.AdTagEvent;
    import org.openvideoads.vast.events.VPAIDAdDisplayEvent;
    import org.openvideoads.vast.server.events.TemplateEvent;

    public class VPAIDJSPlayer extends Sprite implements ConfigLoadListener {
        private var _controlBarWidth:Number = 0;

        // lazy assignments because our JS overlay doesn't have control bars
        private var _controlBarHeight:Number = -1;
        private var _vastController:VASTController;

        /*
         *  XXX: craziest hack ever, no idea why the width has to be pinned in order
         *       to fill the ad DOM object
         */
        private var _playerWidth:Number = 500;
        private var _playerHeight:Number = 375;

        public function VPAIDJSPlayer():void {
            registerExternalAPI();

            // TODO: use a JS callback fired from 'cbOnCreate' within vpaid.js
            vpaidJSEvent("vpaidjs-init");
        }

        // junk to statisfy
        public function isOVAConfigLoading():Boolean {
            return false;
        }

        /*
         *  Called automatically by OVA when after .initAd() completes
         */
        public function onOVAConfigLoaded():void {
            if (_vastController.config.adsConfig.vpaidConfig.hasLinearRegionSpecified() == false) {
                _vastController.config.adsConfig.vpaidConfig.linearRegion = VPAIDConfig.RESERVED_FULLSCREEN_TRANSPARENT;
            }

            if (_vastController.config.adsConfig.vpaidConfig.hasNonLinearRegionSpecified() == false) {
                _vastController.config.adsConfig.vpaidConfig.nonLinearRegion = VPAIDConfig.RESERVED_FULLSCREEN_TRANSPARENT;
            }

            _vastController.addEventListener(VPAIDAdDisplayEvent.LINEAR_LOADED, vpaidEvent);
            _vastController.addEventListener(VPAIDAdDisplayEvent.NON_LINEAR_LOADED, vpaidEvent);
            _vastController.addEventListener(VPAIDAdDisplayEvent.LINEAR_LOADING, vpaidEvent);
            _vastController.addEventListener(VPAIDAdDisplayEvent.NON_LINEAR_LOADING, vpaidEvent);
            _vastController.addEventListener(VPAIDAdDisplayEvent.LINEAR_IMPRESSION, vpaidEvent);
            _vastController.addEventListener(VPAIDAdDisplayEvent.NON_LINEAR_IMPRESSION, vpaidEvent);
            _vastController.addEventListener(VPAIDAdDisplayEvent.LINEAR_COMPLETE, vpaidEvent);
            _vastController.addEventListener(VPAIDAdDisplayEvent.LINEAR_LINEAR_CHANGE, vpaidEvent);
            _vastController.addEventListener(VPAIDAdDisplayEvent.LINEAR_TIME_CHANGE, vpaidEvent);
            _vastController.addEventListener(VPAIDAdDisplayEvent.NON_LINEAR_START, vpaidEvent);
            _vastController.addEventListener(VPAIDAdDisplayEvent.NON_LINEAR_COMPLETE, vpaidEvent);
            _vastController.addEventListener(VPAIDAdDisplayEvent.NON_LINEAR_LINEAR_CHANGE, vpaidEvent);
            _vastController.addEventListener(VPAIDAdDisplayEvent.NON_LINEAR_TIME_CHANGE, vpaidEvent);
            _vastController.addEventListener(VPAIDAdDisplayEvent.VIDEO_AD_START, vpaidEvent);
            _vastController.addEventListener(VPAIDAdDisplayEvent.VIDEO_AD_FIRST_QUARTILE, vpaidEvent);
            _vastController.addEventListener(VPAIDAdDisplayEvent.VIDEO_AD_MIDPOINT, vpaidEvent);
            _vastController.addEventListener(VPAIDAdDisplayEvent.VIDEO_AD_THIRD_QUARTILE, vpaidEvent);
            _vastController.addEventListener(VPAIDAdDisplayEvent.VIDEO_AD_COMPLETE, vpaidEvent);
            _vastController.addEventListener(VPAIDAdDisplayEvent.LINEAR_CLICK_THRU, vpaidEvent);
            _vastController.addEventListener(VPAIDAdDisplayEvent.NON_LINEAR_CLICK_THRU, vpaidEvent);
            _vastController.addEventListener(VPAIDAdDisplayEvent.LINEAR_USER_ACCEPT_INVITATION, vpaidEvent);
            _vastController.addEventListener(VPAIDAdDisplayEvent.LINEAR_USER_MINIMIZE, vpaidEvent);
            _vastController.addEventListener(VPAIDAdDisplayEvent.LINEAR_USER_CLOSE, vpaidEvent);
            _vastController.addEventListener(VPAIDAdDisplayEvent.NON_LINEAR_USER_ACCEPT_INVITATION, vpaidEvent);
            _vastController.addEventListener(VPAIDAdDisplayEvent.NON_LINEAR_USER_MINIMIZE, vpaidEvent);
            _vastController.addEventListener(VPAIDAdDisplayEvent.NON_LINEAR_USER_CLOSE, vpaidEvent);
            _vastController.addEventListener(VPAIDAdDisplayEvent.LINEAR_VOLUME_CHANGE, vpaidEvent);
            _vastController.addEventListener(VPAIDAdDisplayEvent.NON_LINEAR_VOLUME_CHANGE, vpaidEvent);

            // helpful little guys
            _vastController.addEventListener(AdTagEvent.CALL_COMPLETE, vpaidEvent);
            _vastController.addEventListener(TemplateEvent.LOADED, vpaidEvent);
            _vastController.addEventListener(TemplateEvent.LOAD_FAILED, vpaidEvent);

            _vastController.disableRegionDisplay();

            var display:DisplayProperties = new DisplayProperties(
                this,
                _playerWidth,
                _playerHeight,
                'normal',
                _vastController.getActiveDisplaySpecification(false),
                false,
                _controlBarWidth,     // hardcoded 'control bar height'
                _controlBarHeight     // hardcoded 'control bar width'
            )

            _vastController.enableRegionDisplay(display);

            // Ok, let's load up the VAST data from our Ad Server
            _vastController.load();

            vpaidJSEvent("vpaidjs-loaded");
        }

        /*
         *  Named in the same format as the IAB-specified AS3 interfact, just
         *      drop the 'Ad' suffix
         */
        protected function registerExternalAPI():void {
            try {
                ExternalInterface.addCallback("init", externalInit);
                ExternalInterface.addCallback("play", externalPlay);
                ExternalInterface.addCallback("stop", externalStop);
                ExternalInterface.addCallback("resize", externalResize);

                vpaidJSEvent("vpaidjs-api-loaded");
            }
            catch (e:Error) {}
        }

        /*
         *  Reconstruct the VPAID event event handlers, since the core
         *  VPAIDEvent class isn't exposed outside the OVA framework,
         *  ugly but simple enough
         */
        protected function vpaidEvent(event:*):void {

            // EVENTS SKIPPED (related to lower-level playback functions)
            // AdStopped
            // AdPaused
            // AdPlaying

            switch(event.type) {
                case VPAIDAdDisplayEvent.LINEAR_LOADED:
                case VPAIDAdDisplayEvent.NON_LINEAR_LOADED:
                    vpaidJSEvent(VPAIDEvent.AdLoaded);
                    break;
                case VPAIDAdDisplayEvent.LINEAR_START:
                case VPAIDAdDisplayEvent.NON_LINEAR_START:
                    vpaidJSEvent(VPAIDEvent.AdStarted);
                    break;
                case VPAIDAdDisplayEvent.LINEAR_LINEAR_CHANGE:
                    vpaidJSEvent(VPAIDEvent.AdLinearChange);
                    break;
                case VPAIDAdDisplayEvent.LINEAR_EXPANDED_CHANGE:
                case VPAIDAdDisplayEvent.NON_LINEAR_EXPANDED_CHANGE:
                    vpaidJSEvent(VPAIDEvent.AdExpandedChange);
                    break;
                case VPAIDAdDisplayEvent.LINEAR_TIME_CHANGE:
                case VPAIDAdDisplayEvent.NON_LINEAR_TIME_CHANGE:
                    vpaidJSEvent(VPAIDEvent.AdRemainingTimeChange);
                    break;
                case VPAIDAdDisplayEvent.LINEAR_VOLUME_CHANGE:
                case VPAIDAdDisplayEvent.NON_LINEAR_VOLUME_CHANGE:
                    vpaidJSEvent(VPAIDEvent.AdVolumeChange);
                    break;
                case VPAIDAdDisplayEvent.LINEAR_IMPRESSION:
                case VPAIDAdDisplayEvent.NON_LINEAR_IMPRESSION:
                    vpaidJSEvent(VPAIDEvent.AdImpression);
                    break;
                case VPAIDAdDisplayEvent.VIDEO_AD_START:
                    vpaidJSEvent(VPAIDEvent.AdVideoStart);
                    break;
                case VPAIDAdDisplayEvent.VIDEO_AD_FIRST_QUARTILE:
                    vpaidJSEvent(VPAIDEvent.AdVideoFirstQuartile);
                    break;
                case VPAIDAdDisplayEvent.VIDEO_AD_MIDPOINT:
                    vpaidJSEvent(VPAIDEvent.AdVideoMidpoint);
                    break;
                case VPAIDAdDisplayEvent.VIDEO_AD_THIRD_QUARTILE:
                    vpaidJSEvent(VPAIDEvent.AdVideoThirdQuartile);
                    break;
                case VPAIDAdDisplayEvent.VIDEO_AD_COMPLETE:
                    vpaidJSEvent(VPAIDEvent.AdVideoComplete);
                    break;
                case VPAIDAdDisplayEvent.LINEAR_CLICK_THRU:
                case VPAIDAdDisplayEvent.NON_LINEAR_CLICK_THRU:
                    vpaidJSEvent(VPAIDEvent.AdClickThru);
                    break;
                case VPAIDAdDisplayEvent.LINEAR_USER_ACCEPT_INVITATION:
                case VPAIDAdDisplayEvent.NON_LINEAR_USER_ACCEPT_INVITATION:
                    vpaidJSEvent(VPAIDEvent.AdUserAcceptInvitation);
                    break;
                case VPAIDAdDisplayEvent.LINEAR_USER_MINIMIZE:
                case VPAIDAdDisplayEvent.NON_LINEAR_USER_MINIMIZE:
                    vpaidJSEvent(VPAIDEvent.AdUserMinimize);
                    break;
                case VPAIDAdDisplayEvent.LINEAR_USER_CLOSE:
                case VPAIDAdDisplayEvent.NON_LINEAR_USER_CLOSE:
                    vpaidJSEvent(VPAIDEvent.AdUserClose);
                    break;
                case VPAIDAdDisplayEvent.AD_LOG:
                    vpaidJSEvent(VPAIDEvent.AdLog);
                    vpaidJSAdLog(event.data.message);
                    break;
                case VPAIDAdDisplayEvent.LINEAR_ERROR:
                case VPAIDAdDisplayEvent.NON_LINEAR_ERROR:
                    vpaidJSEvent(VPAIDEvent.AdError);
                    break;
                case VPAIDAdDisplayEvent.SKIPPED:
                    vpaidJSEvent(VPAIDEvent.AdSkipped);
                    break;
                case VPAIDAdDisplayEvent.SIZE_CHANGE:
                    vpaidJSEvent(VPAIDEvent.AdSizeChange);
                    break;
                case VPAIDAdDisplayEvent.SKIPPABLE_STATE_CHANGE:
                    vpaidJSEvent(VPAIDEvent.AdSkippableStateChange);
                    break;
                case VPAIDAdDisplayEvent.DURATION_CHANGE:
                    vpaidJSEvent(VPAIDEvent.AdDurationChange);
                    break;
                case VPAIDAdDisplayEvent.AD_INTERACTION:
                    vpaidJSEvent(VPAIDEvent.AdInteraction);
                    break;

                // Bonus events thanks to OVA !!!
                case VPAIDAdDisplayEvent.LINEAR_LOADING:
                case VPAIDAdDisplayEvent.NON_LINEAR_LOADING:
                    vpaidJSEvent("AdLoading");
                    break;
                case VPAIDAdDisplayEvent.LINEAR_COMPLETE:
                case VPAIDAdDisplayEvent.NON_LINEAR_COMPLETE:
                    vpaidJSEvent("AdComplete");
                    break;
                default:
                    vpaidJSEvent(event.type);
            }
        }

        /**
         *  JAVASCRIPT API
         *
         **/

        /*
         *  Request and parse VPAID, given the JSON from Javascript interface
         */
        public function externalInit(ovaConfig:Object):void {
            _vastController = new VASTController();
            _vastController.startStreamSafetyMargin = 100;
            _vastController.endStreamSafetyMargin = 300;

            var playerConfig:Config = new Config();
            playerConfig.playerConfig = _vastController.getDefaultPlayerConfig();

            _vastController.initialise(ovaConfig, false, this, playerConfig);

            vpaidJSEvent("vpaidjs-ad-init");
        }

        public function externalPlay(adSlotIndex:Number=0):void {
            // TODO: play all scheduled ads if (adSlotIndex == -1)
            var slot:AdSlot = _vastController.adSchedule.adSlots[adSlotIndex];

            _vastController.playVPAIDAd(slot, false, false, 0.9);
            vpaidJSEvent("vpaidjs-ad-play");

        }

        public function externalStop():void {
            // NOT IMPLEMENTED
        }

        public function externalResize():void {
            // NOT IMPLEMENTED
        }

        /*
         *  FIX ME: ugly interaces for event and log handlers
         */
        protected function vpaidJSAdLog(message:String):void {
            ExternalInterface.call("AdLog", message);
        }

        protected function vpaidJSEvent(eventName:String):void {
            ExternalInterface.call("onVPAIDEvent", eventName, "");
        }
    }
}