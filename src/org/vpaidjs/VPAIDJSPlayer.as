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
import com.hinish.spec.iab.vast.parsers.VASTParser;
import com.hinish.spec.iab.vast.vos.VAST;
import com.hinish.spec.iab.vpaid.AdEvent;
import com.hinish.spec.iab.vpaid.AdViewMode;

import flash.display.DisplayObject;

import flash.display.Loader;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.external.ExternalInterface;
import flash.media.SoundMixer;
import flash.media.SoundTransform;
import flash.net.URLLoader;
import flash.net.URLRequest;
import flash.system.ApplicationDomain;
import flash.system.LoaderContext;
import flash.system.Security;
import flash.system.SecurityDomain;
import flash.utils.ByteArray;
import flash.utils.describeType;


public class VPAIDJSPlayer extends Sprite {
        private var _version:String = "0.3";
//
//        private var _ad:IVPAID = new VPAIDBase();
//        private var _vastController:VASTController;
//        private var _display:DisplayProperties;
//
//           XXX: no idea why the width has to be pinned in order to fill the region...
//        private var _playerWidth:Number = 500;
//        private var _playerHeight:Number = 375;
//
//        private var _playerVolume:Number = 1;         // 100%

    private const VPAID_VERSION:String = "2.0";

    private var _adVPAIDVersion:String;

    private var _vastResponse:VAST;
    private var _loader:Loader;

    private var _ad:Object;

        public function VPAIDJSPlayer():void {
            Security.allowDomain("*");
            registerExternalAPI();


        }

    /*
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

            triggerExternalEvent(VPAIDAdDisplayEvent.LINEAR_LOADING, "AdLoading");
            triggerExternalEvent(VPAIDAdDisplayEvent.NON_LINEAR_LOADING, "AdLoading");
            triggerExternalEvent(VPAIDAdDisplayEvent.LINEAR_LOADED, "AdLoaded");
            triggerExternalEvent(VPAIDAdDisplayEvent.NON_LINEAR_LOADED, "AdLoaded");
            triggerExternalEvent(VPAIDAdDisplayEvent.LINEAR_START, "AdStarted");
            triggerExternalEvent(VPAIDAdDisplayEvent.NON_LINEAR_START, "AdStarted");
            triggerExternalEvent(VPAIDAdDisplayEvent.LINEAR_PAUSE, "AdPaused");
            triggerExternalEvent(VPAIDAdDisplayEvent.NON_LINEAR_PAUSE, "AdPaused");
            triggerExternalEvent(VPAIDAdDisplayEvent.LINEAR_COMPLETE, "AdStopped");
            triggerExternalEvent(VPAIDAdDisplayEvent.NON_LINEAR_COMPLETE, "AdStopped");
            triggerExternalEvent(VPAIDAdDisplayEvent.LINEAR_LINEAR_CHANGE, "AdLinearChange");
            triggerExternalEvent(VPAIDAdDisplayEvent.NON_LINEAR_LINEAR_CHANGE, "AdLinearChange");
            triggerExternalEvent(VPAIDAdDisplayEvent.LINEAR_EXPANDED_CHANGE, "AdExpandedChange");
            triggerExternalEvent(VPAIDAdDisplayEvent.NON_LINEAR_EXPANDED_CHANGE, "AdExpandedChange");
            triggerExternalEvent(VPAIDAdDisplayEvent.LINEAR_VOLUME_CHANGE, "AdVolumeChange");
            triggerExternalEvent(VPAIDAdDisplayEvent.NON_LINEAR_VOLUME_CHANGE, "AdVolumeChange");
            triggerExternalEvent(VPAIDAdDisplayEvent.LINEAR_IMPRESSION, "AdImpression");
            triggerExternalEvent(VPAIDAdDisplayEvent.NON_LINEAR_IMPRESSION, "AdImpression");
            triggerExternalEvent(VPAIDAdDisplayEvent.VIDEO_AD_START, "AdVideoStart");
            triggerExternalEvent(VPAIDAdDisplayEvent.VIDEO_AD_FIRST_QUARTILE, "AdVideoFirstQuartile");
            triggerExternalEvent(VPAIDAdDisplayEvent.VIDEO_AD_MIDPOINT, "AdVideoMidpoint");
            triggerExternalEvent(VPAIDAdDisplayEvent.VIDEO_AD_THIRD_QUARTILE, "AdVideoThirdQuartile");
            triggerExternalEvent(VPAIDAdDisplayEvent.VIDEO_AD_COMPLETE, "AdVideoComplete");
            triggerExternalEvent(VPAIDAdDisplayEvent.LINEAR_CLICK_THRU, "AdClickThru");
            triggerExternalEvent(VPAIDAdDisplayEvent.NON_LINEAR_CLICK_THRU, "AdClickThru");
            triggerExternalEvent(VPAIDAdDisplayEvent.LINEAR_USER_ACCEPT_INVITATION, "AdUserAcceptInvitation");
            triggerExternalEvent(VPAIDAdDisplayEvent.NON_LINEAR_USER_ACCEPT_INVITATION, "AdUserAcceptInvitation");
            triggerExternalEvent(VPAIDAdDisplayEvent.LINEAR_USER_MINIMIZE, "AdUserMinimize");
            triggerExternalEvent(VPAIDAdDisplayEvent.NON_LINEAR_USER_MINIMIZE, "AdUserMinimize");
            triggerExternalEvent(VPAIDAdDisplayEvent.LINEAR_USER_CLOSE, "AdUserClose");
            triggerExternalEvent(VPAIDAdDisplayEvent.NON_LINEAR_USER_CLOSE, "AdUserClose");
            triggerExternalEvent(VPAIDAdDisplayEvent.LINEAR_PLAYING, "AdPlaying");
            triggerExternalEvent(VPAIDAdDisplayEvent.NON_LINEAR_PLAYING, "AdPlaying");
            triggerExternalEvent(VPAIDAdDisplayEvent.AD_LOG, "AdLog");
            triggerExternalEvent(VPAIDAdDisplayEvent.LINEAR_ERROR, "AdError");
            triggerExternalEvent(VPAIDAdDisplayEvent.NON_LINEAR_ERROR, "AdError");

            // VPAID 2.x events
            triggerExternalEvent(VPAIDAdDisplayEvent.SKIPPED, "AdSkipped");
            triggerExternalEvent(VPAIDAdDisplayEvent.SKIPPABLE_STATE_CHANGE, "AdSkippableStateChange");
            triggerExternalEvent(VPAIDAdDisplayEvent.SIZE_CHANGE, "AdSizeChange");
            triggerExternalEvent(VPAIDAdDisplayEvent.DURATION_CHANGE, "AdDurationChange");
            triggerExternalEvent(VPAIDAdDisplayEvent.AD_INTERACTION, "AdInteraction");

            // Extra events
            triggerExternalEvent(NonLinearSchedulingEvent.SCHEDULE, "AdReady");
            triggerExternalEvent(StreamSchedulingEvent.SCHEDULE, "AdReady");

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



        protected function onLoaded(event:VPAIDAdDisplayEvent):void {
            _ad = _vastController.getActiveVPAIDAd();
        }

        protected function onStart(event:VPAIDAdDisplayEvent):void {
        }

        protected function onComplete(event:VPAIDAdDisplayEvent):void {
            _ad = new VPAIDBase();
        }

     */
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
            catch (e:Error) {
                ExternalInterface.call("console.log", "[vpaidjs.swf] exception registering external callbacks.");
            }
        }



        /**
         *  JAVASCRIPT API
         */

        public function jsVolume(level:Number):void {
            // ads find the funniest ways to unmute themselves, so turn it off at a low level when muted
            if (level == 0) {
                SoundMixer.soundTransform = new SoundTransform(0);
            } else {
                SoundMixer.soundTransform = new SoundTransform(1);
            }

            if (_ad != null) {
                _ad.adVolume = level;
            }
        }

        //  Request, load, and prepare Flash ad
        public function jsInitAd(adTag:String, debug:Boolean):void {
            var parser:VASTParser = new VASTParser();
            var urlRequest:URLRequest = new URLRequest(adTag);
            var urlLoader:URLLoader = new URLLoader();


            urlLoader.addEventListener(Event.COMPLETE, function urlLoader_complete(evt:Event):void {
                parser.setData(XML(evt.currentTarget.data));
                _vastResponse = parser.parse();

                // XXX: only worry about first ad for now
                if (_vastResponse.ads.length && _vastResponse.ads[0].creatives.length) {

                    // TODO:
                    // 1. queue up ads to play
                    // 1. playthrough of queueing of multiple ads
                    // 2. select appropriate creative (is this in `creatives` or `mediaFiles`?)

                    var url:String = _vastResponse.ads[0].creatives[0].source.mediaFiles[0].uri;

                    // TOOD: lame boilerplate from example code
//                    if (stage) {
//                         Only do these if this is the top-level SWF.
//                        stage.align = StageAlign.TOP_LEFT;
//                        stage.scaleMode = StageScaleMode.NO_SCALE;

                        createLoader(url);
//                    }
//                    else {
//                        addEventListener(Event.ADDED_TO_STAGE, function waitingToBeAdded(event:Event):void {
//                            removeEventListener(Event.ADDED_TO_STAGE, waitingToBeAdded);
//                            createLoader(url);
//                        });
//                    }
                }
            });

            urlLoader.load(urlRequest);
        }


    private function createLoader(adTag:String):void {
        _loader = new Loader();
        _loader.contentLoaderInfo.addEventListener(Event.COMPLETE, completeHandler);
        _loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, errorHandler);
        _loader.load(new URLRequest(adTag), new LoaderContext(false, ApplicationDomain.currentDomain, SecurityDomain.currentDomain));
    }

    private function errorHandler(event:Event):void {
        // Just kill the event for this example.
        event.preventDefault();
        event.stopImmediatePropagation();
    }

    private function completeHandler(event:Event):void
    {
        _loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, completeHandler);
        if (_loader.content)
        {
            _ad = _loader.content;
        }
        processAd();
    }

    private function processAd():void
    {
        if (_ad)
        {
            // TODO: wtf is this handshake stuff
            if (_ad.hasOwnProperty("handshakeVersion"))
            {
                _adVPAIDVersion = _ad.handshakeVersion(VPAID_VERSION);
            }

            _ad.addEventListener(AdEvent.AD_CLICK_THRU, triggerExternalEvent);
            _ad.addEventListener(AdEvent.AD_DURATION_CHANGE, triggerExternalEvent);
            _ad.addEventListener(AdEvent.AD_ERROR, triggerExternalEvent);
            _ad.addEventListener(AdEvent.AD_EXPANDED_CHANGE, triggerExternalEvent);
            _ad.addEventListener(AdEvent.AD_IMPRESSION, triggerExternalEvent);
            _ad.addEventListener(AdEvent.AD_INTERACTION, triggerExternalEvent);
            _ad.addEventListener(AdEvent.AD_LINEAR_CHANGE, triggerExternalEvent);
            _ad.addEventListener(AdEvent.AD_LOADED, triggerExternalEvent);
            _ad.addEventListener(AdEvent.AD_LOG, triggerExternalEvent);
            _ad.addEventListener(AdEvent.AD_PAUSED, triggerExternalEvent);
            _ad.addEventListener(AdEvent.AD_PLAYING, triggerExternalEvent);
            _ad.addEventListener(AdEvent.AD_REMAINING_TIME_CHANGE, triggerExternalEvent);
            _ad.addEventListener(AdEvent.AD_SIZE_CHANGE, triggerExternalEvent);
            _ad.addEventListener(AdEvent.AD_SKIPPABLE_STATE_CHANGED, triggerExternalEvent);
            _ad.addEventListener(AdEvent.AD_SKIPPED, triggerExternalEvent);
            _ad.addEventListener(AdEvent.AD_STARTED, triggerExternalEvent);
            _ad.addEventListener(AdEvent.AD_STOPPED, triggerExternalEvent);
            _ad.addEventListener(AdEvent.AD_USER_ACCEPT_INVITATION, triggerExternalEvent);
            _ad.addEventListener(AdEvent.AD_USER_CLOSE, triggerExternalEvent);
            _ad.addEventListener(AdEvent.AD_USER_MINIMIZE, triggerExternalEvent);
            _ad.addEventListener(AdEvent.AD_VIDEO_COMPLETE, triggerExternalEvent);
            _ad.addEventListener(AdEvent.AD_VIDEO_FIRST_QUARTILE, triggerExternalEvent);
            _ad.addEventListener(AdEvent.AD_VIDEO_MIDPOINT, triggerExternalEvent);
            _ad.addEventListener(AdEvent.AD_VIDEO_START, triggerExternalEvent);
            _ad.addEventListener(AdEvent.AD_VIDEO_THIRD_QUARTILE, triggerExternalEvent);
            _ad.addEventListener(AdEvent.AD_VOLUME_CHANGE, triggerExternalEvent);

            if (_ad.hasOwnProperty("initAd"))
            {
                ExternalInterface.call("vpaidjs.triggerEvent", ExternalInterface.objectID, "AdReady", "{}");

                // TODO: figure out these params

                addChild(_ad as DisplayObject);
                _ad.initAd(stage.stageWidth, stage.stageHeight, AdViewMode.NORMAL, 4800, "", "");
            }
        }
    }


    private function triggerExternalEvent(evt:Event):void {
        ExternalInterface.call("vpaidjs.triggerEvent", ExternalInterface.objectID, evt.type, "{}");
    }


    public function jsStartAd(adSlotIndex:Number=0):void {
        // TODO: resize if too big
        _ad.startAd()
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
//            if(_vastController != null && _display != null) {
                // TODO: re-align to center if you're really cool
//                _display.displayWidth = width;
//                _display.displayHeight = height;
//
//                stage.scaleMode = StageScaleMode.NO_SCALE;
//                stage.align = StageAlign.TOP_LEFT;
//
//                _vastController.resizeOverlays(_display);
//            }
//            _ad.resizeAd(_display);
        }

        public function jsCollapseAd():void {
//            _ad.collapseAd();
        }





    [Embed(source = "../../../resources/vast_sample_1.xml", mimeType = "application/octet-stream")]
    private static const SAMPLE_1:Class;

    [Embed(source = "../../../resources/vast_sample_2.xml", mimeType = "application/octet-stream")]
    private static const SAMPLE_2:Class;

//    public function VASTExample1()
//    {
//        setTimeout(parseVast, 2500);
//    }

    private function parseVast():void
    {
        var parser:VASTParser = new VASTParser();
//        parser.registerExtensionParser(new PreviousAdInformationParser());
//        parser.registerExtensionParser(new DARTInfoParser());


        var xml:XML;
        var urlRequest:URLRequest = new URLRequest("http://ll.cdn.bitmedianetwork.com.s3.amazonaws.com/video/test/honey.xml");

        var urlLoader:URLLoader = new URLLoader();
        urlLoader.addEventListener(Event.COMPLETE, function urlLoader_complete(evt:Event):void {
            parser.setData(XML(evt.currentTarget.data));
            var output1:VAST = parser.parse();

            xml = new XML(evt.currentTarget.data);
            var s:* = 'sdf';
//            textArea.text = xml.toXMLString();
        });
        urlLoader.load(urlRequest);

        parser.setData(XML(getContents(SAMPLE_1)));
        var output1:VAST = parser.parse();

        parser.setData(XML(getContents(SAMPLE_2)));
        var output2:VAST = parser.parse();
    }

    private function getContents(cls:Class):String
    {
        var ba:ByteArray = new cls();
        return ba.readUTFBytes(ba.length);
    }
}


    /*

        * initialize
        * parse params into adPlacement object
          - will eventually need to do things like picking bitrate, dimensions, format, etc
        * register ExternalInterface
        * register VPAID events
        * getVPAID() turned on /only/ when fully loaded
        * initAd(): what goes on in OVA during initAd()? loader?
        * startAd(): is this where
        *
        * then, VAST video playback with minimal events

     */
}
