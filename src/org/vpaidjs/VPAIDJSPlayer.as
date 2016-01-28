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
    import flash.display.Sprite;
    import flash.display.StageAlign;
    import flash.display.StageScaleMode;
    import flash.events.Event;
    import flash.events.IOErrorEvent;
import flash.events.UncaughtErrorEvent;
import flash.external.ExternalInterface;
    import flash.media.SoundMixer;
    import flash.media.SoundTransform;
    import flash.net.URLLoader;
    import flash.net.URLRequest;
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
        protected var _ad:Object;
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


        private function createFlashLoader(adTag:String):void {
            if (_loader) {
                // TODO: XXX does this actually do anything?
                _loader.unload();
            }
            _loader = new Loader();

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
                }
            }
        }


        private function startVideoPlayback(url:String) {

        }


        private static function triggerExternalEvent(event:Event):void {
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
                _ad.adVolume = level;
            }
        }


        // TODO XXX: any need for a debug flag anymore?
        public function jsInitAd(adTag:String, debug:Boolean):void {
            var parser:VASTParser = new VASTParser();
            var urlRequest:URLRequest = new URLRequest(adTag);
            var urlLoader:URLLoader = new URLLoader();

            urlLoader.addEventListener(Event.COMPLETE, function urlLoader_complete(event:Event):void {
                parser.setData(XML(event.currentTarget.data));
                _vastResponse = parser.parse();

                // TODO XXX: only worry about first ad for now
                if (_vastResponse.ads.length && _vastResponse.ads[0].creatives.length) {
                    // TODO playthrough of multiple ads

                    for (var i in _vastResponse.ads) {
                        var url:String = _vastResponse[i].creatives[0].source.mediaFiles[0].uri;
                        var splitUrl:Array = url.split(".");

                        var creativeType:String = splitUrl[splitUrl.length-1];

                        if (creativeType == "swf") {
                            createFlashLoader(url);
                        } else if (creativeType == "mp4" || creativeType == "flv" || creativeType == "avi") {    // TODO: more types
//                            startVideoPlayback(url);
                            'sdf';
                        } else {
                             // TODO: invalid creative type
                        }

                        // TODO: actually iterate
                        break;
                    }

                }
            });

            urlLoader.load(urlRequest);
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


        // TODO XXX: completely untested
        public function jsResizeAd(width:Number, height:Number):void {
            _display.width = width;
            _display.height = height;

            // TODO: re-align to center if you're really cool
            stage.scaleMode = StageScaleMode.NO_SCALE;
            stage.align = StageAlign.TOP_LEFT;

            _ad.resizeAd(_display);
        }


        public function jsCollapseAd():void {
            _ad.collapseAd();
        }
    }
}
