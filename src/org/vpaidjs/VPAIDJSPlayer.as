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
    import flash.display.DisplayObject;
    import flash.display.Loader;
    import flash.display.MovieClip;
    import flash.display.Sprite;
    import flash.display.StageAlign;
    import flash.display.StageScaleMode;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.events.NetStatusEvent;
    import flash.events.UncaughtErrorEvent;
    import flash.external.ExternalInterface;
    import flash.media.SoundMixer;
    import flash.media.SoundTransform;
    import flash.media.Video;
    import flash.net.NetConnection;
    import flash.net.NetStream;
    import flash.net.URLLoader;
    import flash.net.URLRequest;
    import flash.net.navigateToURL;
    import flash.system.ApplicationDomain;
    import flash.system.LoaderContext;
    import flash.system.Security;
    import flash.system.SecurityDomain;

    import com.hinish.spec.iab.vast.parsers.VASTParser;
    import com.hinish.spec.iab.vast.vos.VAST;
    import com.hinish.spec.iab.vpaid.AdEvent;
    import com.hinish.spec.iab.vpaid.AdViewMode;


    public class VPAIDJSPlayer extends Sprite {
        private var _version:String = "0.3";

        // TODO: not 3.0? and why do i need this again?
        protected const VPAID_VERSION:String = "2.0";
        protected var _adVPAIDVersion:String;

        // TODO XXX: be sure to clear/garbage collect these after playback
        protected var _ad:Object;           // TODO XXX: is it safe to use different types between flash vs video playback?
        protected var _display:DisplayObject;
        protected var _loader:Loader;
        protected var _vastResponse:VAST;

        public function VPAIDJSPlayer():void {
            Security.allowDomain("*");
            registerExternalAPI();

            stage.align = StageAlign.TOP_LEFT;
            stage.scaleMode = StageScaleMode.NO_SCALE;
        }

        private function registerExternalAPI():void {
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


        private function createFlashLoader(adTag:String, adData:Object):void {
            if (_loader) {
                // TODO: XXX does this actually do anything?
                _loader.unload();
            }
            _loader = new Loader();

            // TODO: XXX does this actually work?
            loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, function (event:UncaughtErrorEvent):void {
                ExternalInterface.call("console.log", "unhandled exception: [" + event.type +"]: " + event.text);

                // TODO: smart to have?
                event.preventDefault();
                event.stopImmediatePropagation();
            });

            _loader.contentLoaderInfo.addEventListener(Event.COMPLETE, function completeHandler(event:Event):void {
                _loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, completeHandler);
                if (_loader.content) {
                    _ad = _loader.content;

                    initiateFlashAd();
                } else {
                    // TODO: exception?
                }
            });

            _loader.load(
                new URLRequest(adTag),
                new LoaderContext(false, ApplicationDomain.currentDomain, SecurityDomain.currentDomain)
            );
        }

        private function initiateFlashAd():void {
            if (_ad) {
                // TODO: wtf is this handshake stuff
                if (_ad.hasOwnProperty("handshakeVersion")) {
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

                // TODO: maybe this could be .getVAID() or killed altogether?
                if (_ad.hasOwnProperty("initAd")) {
                    ExternalInterface.call("vpaidjs.triggerEvent", ExternalInterface.objectID, "AdReady", "{}");

                    _display = _ad as DisplayObject;
                    addChild(_display);

                    // TODO: figure out these params
                    _ad.initAd(
                        stage.stageWidth,
                        stage.stageHeight,
                        AdViewMode.NORMAL,
                        4800,       // TODO: could probably a better ideal default bitrate
                        "",
                        ""
                    );

                    // TODO XXX: don't hack to use ExternalInterface here...
                    ExternalInterface.call("vpaidjs.triggerEvent", ExternalInterface.objectID, "AdReady", "{}");
                }
            }
        }


        private function startVideoPlayback(adTag:String, adData:Object) {
            _ad = new MovieClip();
            var vastVideo:Video = new Video(stage.stageWidth, stage.stageHeight);
            var isPaused:Boolean = false;

            _ad.addChild(vastVideo);
            _display = _ad as DisplayObject;
            addChild(_display);

            var nc:NetConnection = new NetConnection();
            nc.connect(null);
            var ns:NetStream = new NetStream(nc);

            // these callbacks are required or else NetConnection will blow up on you
            ns.client = {};
            ns.client.onCuePoint = function() {};
            ns.client.onMetaData = function(info:Object) {
                // TODO: calculate quartile reporting using `info.duration`
            };

            vastVideo.attachNetStream(ns);
            ns.play(adTag);

            ns.addEventListener(NetStatusEvent.NET_STATUS, function (event:NetStatusEvent):void {
                // TODO XXX: is there an obvious event on playback start?

                if (event.info.code == "NetStream.Play.Start") {
                    // TODO: ping on playback start to `Impression`
                    var impressionRequest:URLRequest = new URLRequest("http://localhost");
                    var impressionRequestLoader:URLLoader = new URLLoader();
                    impressionRequestLoader.load(impressionRequest);

                } else if (event.info.code == "NetStream.Play.Stop") {
                    // TODO ?
                }
            });

            _ad.addEventListener(MouseEvent.CLICK, function (event:MouseEvent):void {

                if (!isPaused) {
                    isPaused = true;
                    // VAST ClickThru event

                    var clickThru:URLRequest = new URLRequest("http://www.utorrent.com");
                    navigateToURL(clickThru, "_blank");
                } else {
                    isPaused = false;
                }

                ns.togglePause();
            });

            // TODO XXX: smart to have?
            _ad.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, function (event:UncaughtErrorEvent):void {
                event.preventDefault();
                event.stopImmediatePropagation();
            });


            // TODO XXX: what other pings?
        }

        private function registerVastTrackingEvents() {

        }


        private static function triggerExternalEvent(event:Event):void {
            // TODO: end some add data
            ExternalInterface.call("vpaidjs.triggerEvent", ExternalInterface.objectID, event.type, "{}");
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
                // TODO: handle VAST
                _ad.adVolume = level;
            }
        }


        // TODO any need for a debug flag anymore?
        public function jsInitAd(adTag:String, debug:Boolean):void {
            var parser:VASTParser = new VASTParser();
            var adTagRequest:URLRequest = new URLRequest(adTag);
            var adTagRequestLoader:URLLoader = new URLLoader();

            adTagRequestLoader.addEventListener(Event.COMPLETE, function adTagLoader_complete(event:Event):void {
                parser.setData(XML(event.currentTarget.data));
                _vastResponse = parser.parse();

                // TODO XXX: only worry about first ad for now
                var currentAd = _vastResponse.ads[0];
                var url:String = currentAd.creatives[0].source.mediaFiles[0].uri;

                var splitUrl:Array = url.split(".");

                var creativeType:String = splitUrl[splitUrl.length-1];

                if (creativeType == "swf") {
                    createFlashLoader(url, currentAd);
                } else if (creativeType == "mp4" || creativeType == "flv" || creativeType == "avi") {    // TODO: more types
                    startVideoPlayback(url, currentAd);
                } else {
                     // TODO: invalid creative type
                }

                // TODO: actually iterate
            });

            adTagRequestLoader.load(adTagRequest);
        }


        public function jsStartAd(adSlotIndex:Number=0):void {
            // TODO: resize if too big
            _ad.startAd()
        }


        public function jsStopAd():void {
            _ad.stopAd();
            // TODO: handle VAST
        }


        public function jsSkipAd():void {
            _ad.skipAd();
        }


        public function jsPauseAd():void {
            _ad.pauseAd();
            // TODO: handle VAST
        }


        public function jsResumeAd():void {
            _ad.resumeAd();
            // TODO: handle VAST
        }


        public function jsExpandAd():void {
            _ad.expandAd();
        }


        public function jsResizeAd(width:Number, height:Number):void {
            if (_ad && _display) {
                _display.width = width;
                _display.height = height;

                _ad.resizeAd(width, height, "normal");
                // TODO: handle VAST
            }
        }


        public function jsCollapseAd():void {
            _ad.collapseAd();
        }
    }
}
