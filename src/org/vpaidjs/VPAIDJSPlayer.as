package org.vpaidjs {

    import com.hinish.spec.iab.vast.vos.Creative;
    import com.hinish.spec.iab.vast.vos.TrackingEvent;
    import com.hinish.spec.iab.vast.vos.URIIdentifier;

    import flash.display.Loader;
    import flash.display.MovieClip;
    import flash.display.Sprite;
    import flash.display.StageAlign;
    import flash.display.StageScaleMode;
    import flash.events.Event;
    import flash.events.IOErrorEvent;
    import flash.events.MouseEvent;
    import flash.events.NetStatusEvent;
    import flash.events.SecurityErrorEvent;
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
    import flash.utils.clearInterval;
    import flash.utils.setInterval;
    import flash.utils.setTimeout;

    import com.hinish.spec.iab.vast.parsers.VASTParser;
    import com.hinish.spec.iab.vast.vos.Linear;
    import com.hinish.spec.iab.vast.vos.MediaFile;
    import com.hinish.spec.iab.vast.vos.TrackingEventTypes;
    import com.hinish.spec.iab.vast.vos.VAST;
    import com.hinish.spec.iab.vpaid.AdEvent;


    public class VPAIDJSPlayer extends Sprite {

        protected var vastAd:MovieClip;
        protected var vpaidAd:*;           // this will always be a `Loader`
        protected var adSequenceId:Number = 0;
        protected var vastResponse:VAST;
        protected var vastEvents:Object = {};


        public function VPAIDJSPlayer():void {
            stage.root.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, function (event:UncaughtErrorEvent):void {
                var errorType:String = event.error.type || event.error.name;
                var errorText:String = event.error.text || event.error.message;

                log("vpaidjs: [unhandled exception] " + errorType + ": " + errorText);

                event.preventDefault();
                event.stopImmediatePropagation();
            });

            // minimize loader and CORs errors
            Security.allowDomain("*");
            Security.allowInsecureDomain("*");

            // define alignment for child elements of this swf
            stage.align = StageAlign.TOP_LEFT;
            stage.scaleMode = StageScaleMode.NO_SCALE;

            registerExternalInterface();
            triggerEvent("AdReady");
        }

        // set up JS -> Flash bridge
        private function registerExternalInterface():void {
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


        // can be used as a callback for Events *or* called with String of event name
        private function triggerEvent(event:*):void {
            var eventName:String = event.hasOwnProperty("type") ? event.type : event;

            // tack on event data if this method was triggered as a handler
            var eventData:Object = vastEvents;
            if (event.hasOwnProperty("data") && event.data) {
                eventData.data = event.data;
            }

            // trigger Javascript event
            ExternalInterface.call("vpaidjs.util.triggerEvent", ExternalInterface.objectID, eventName, JSON.stringify(vastEvents));

            // transmit event pings over JS to break out of Flash crossdomain sandbox
            if (eventName in vastEvents) {
                for each (var eventUri:String in vastEvents[eventName]) {
                    ExternalInterface.call("vpaidjs.util.ping", eventUri);
                }
            }
        }


        private static function log(message:String):void {
            ExternalInterface.call("vpaidjs.util.log", message);
        }


        private function registerVpaidCallbacks():void {
            vpaidAd.addEventListener(AdEvent.AD_CLICK_THRU, triggerEvent);
            vpaidAd.addEventListener(AdEvent.AD_DURATION_CHANGE, triggerEvent);
            vpaidAd.addEventListener(AdEvent.AD_ERROR, triggerEvent);
            vpaidAd.addEventListener(AdEvent.AD_EXPANDED_CHANGE, triggerEvent);
            vpaidAd.addEventListener(AdEvent.AD_IMPRESSION, triggerEvent);
            vpaidAd.addEventListener(AdEvent.AD_INTERACTION, triggerEvent);
            vpaidAd.addEventListener(AdEvent.AD_LINEAR_CHANGE, triggerEvent);
            vpaidAd.addEventListener(AdEvent.AD_LOADED, triggerEvent);
            vpaidAd.addEventListener(AdEvent.AD_LOG, triggerEvent);
            vpaidAd.addEventListener(AdEvent.AD_PAUSED, triggerEvent);
            vpaidAd.addEventListener(AdEvent.AD_PLAYING, triggerEvent);
            vpaidAd.addEventListener(AdEvent.AD_REMAINING_TIME_CHANGE, triggerEvent);
            vpaidAd.addEventListener(AdEvent.AD_SIZE_CHANGE, triggerEvent);
            vpaidAd.addEventListener(AdEvent.AD_SKIPPABLE_STATE_CHANGED, triggerEvent);
            vpaidAd.addEventListener(AdEvent.AD_SKIPPED, triggerEvent);
            vpaidAd.addEventListener(AdEvent.AD_STARTED, triggerEvent);
            vpaidAd.addEventListener(AdEvent.AD_STOPPED, triggerEvent);
            vpaidAd.addEventListener(AdEvent.AD_USER_ACCEPT_INVITATION, triggerEvent);
            vpaidAd.addEventListener(AdEvent.AD_USER_CLOSE, triggerEvent);
            vpaidAd.addEventListener(AdEvent.AD_USER_MINIMIZE, triggerEvent);
            vpaidAd.addEventListener(AdEvent.AD_VIDEO_COMPLETE, triggerEvent);
            vpaidAd.addEventListener(AdEvent.AD_VIDEO_FIRST_QUARTILE, triggerEvent);
            vpaidAd.addEventListener(AdEvent.AD_VIDEO_MIDPOINT, triggerEvent);
            vpaidAd.addEventListener(AdEvent.AD_VIDEO_START, triggerEvent);
            vpaidAd.addEventListener(AdEvent.AD_VIDEO_THIRD_QUARTILE, triggerEvent);
            vpaidAd.addEventListener(AdEvent.AD_VOLUME_CHANGE, triggerEvent);

            vpaidAd.addEventListener(AdEvent.AD_ERROR, adEnd);
            vpaidAd.addEventListener(AdEvent.AD_STOPPED, adEnd);
        }


        // convert VAST events to VPAID events and add them to the shared
        private function registerVastEvents(trackingEvents:Object, impressionEvents:Object, clickEvents:Object):void {
            var vpaidEvent:String;

            for each (var trackingEvent:TrackingEvent in trackingEvents) {

                switch (trackingEvent.event) {
                    case TrackingEventTypes.START:
                        vpaidEvent = AdEvent.AD_VIDEO_START;
                        break;
                    case TrackingEventTypes.MIDPOINT:
                        vpaidEvent = AdEvent.AD_VIDEO_MIDPOINT;
                        break;
                    case TrackingEventTypes.FIRST_QUARTILE:
                        vpaidEvent = AdEvent.AD_VIDEO_FIRST_QUARTILE;
                        break;
                    case TrackingEventTypes.THIRD_QUARTILE:
                        vpaidEvent = AdEvent.AD_VIDEO_THIRD_QUARTILE;
                        break;
                    case TrackingEventTypes.COMPLETE:
                        vpaidEvent = AdEvent.AD_VIDEO_COMPLETE;
                        break;
                    case TrackingEventTypes.PAUSE:
                        vpaidEvent = AdEvent.AD_PAUSED;
                        break;
                    case TrackingEventTypes.RESUME:
                        vpaidEvent = AdEvent.AD_PLAYING;
                        break;
                    case TrackingEventTypes.FULLSCREEN:
                    case TrackingEventTypes.EXPAND:
                        vpaidEvent = AdEvent.AD_EXPANDED_CHANGE;
                        break;
                    case TrackingEventTypes.COLLAPSE:
                        vpaidEvent = AdEvent.AD_USER_MINIMIZE;
                        break;
                    case TrackingEventTypes.ACCEPT_INVITATION:
                        vpaidEvent = AdEvent.AD_USER_ACCEPT_INVITATION;
                        break;
                    case TrackingEventTypes.CLOSE:
                        vpaidEvent = AdEvent.AD_USER_CLOSE;
                        break;
                    default:
                        continue;
                }

                if (vpaidEvent in vastEvents) {
                    vastEvents[vpaidEvent].push(trackingEvent.uri);
                } else {
                    vastEvents[vpaidEvent] = [ trackingEvent.uri ];
                }
            }

            for each (var impressionEvent:URIIdentifier in impressionEvents) {
                // bug in iab spec library when impression tags are empty
                if (impressionEvent.uri !== "") {
                     if (AdEvent.AD_IMPRESSION in vastEvents) {
                        vastEvents[AdEvent.AD_IMPRESSION].push(impressionEvent.uri);
                    } else {
                        vastEvents[AdEvent.AD_IMPRESSION] = [ impressionEvent.uri ];
                    }
                }
            }

            if (clickEvents) {
                for each (var clickEvent:URIIdentifier in clickEvents.clickTracking) {
                    if (AdEvent.AD_CLICK_THRU in vastEvents) {
                        vastEvents[AdEvent.AD_CLICK_THRU].push(clickEvent.uri);
                    } else {
                        vastEvents[AdEvent.AD_CLICK_THRU] = [ clickEvent.uri ];
                    }
                }
            }
        }


        private function initFlashAd(adParameters:String):void {
            registerVpaidCallbacks();

            if (vpaidAd.hasOwnProperty("initAd")) {
                vpaidAd.handshakeVersion("2.0");

                vpaidAd.initAd(
                        stage.stageWidth,
                        stage.stageHeight,
                        "normal",
                        4800,
                        adParameters,
                        ""
                );
            } else {
                adEnd("Invalid VPAID swf.");
            }
        }


        private function initVideo(mediaFile:MediaFile):void {
            triggerEvent("AdLoading");
            var isPaused:Boolean = false;

            vastAd = new MovieClip();
            addChild(vastAd);

            var connection:NetConnection = new NetConnection();
            connection.connect(null);

            // boilerplate callbacks required to init NetConnection
            var stream:NetStream = new NetStream(connection);
            stream.client = {};
            stream.client.onCuePoint = function():void {};
            stream.client.onMetaData = function(info:Object):void {};

            stream.addEventListener(NetStatusEvent.NET_STATUS, function (event:NetStatusEvent):void {
                if (event.info.code == "NetStream.Play.Start") {
                    triggerEvent(AdEvent.AD_STARTED);
                    triggerEvent(AdEvent.AD_IMPRESSION);
                    triggerEvent(AdEvent.AD_VIDEO_START);

                    // register quartile events
                    stream.client.onMetaData = function (info:Object):void {
                        var oneQuartile:Number = info.duration / 4;
                        var midPoint:Number = oneQuartile * 2;
                        var thirdQuartile:Number = oneQuartile * 3;

                        var progressEventCheck:Number = setInterval(function ():void {
                            if (oneQuartile && stream.time > oneQuartile && stream.time < midPoint) {
                                triggerEvent(AdEvent.AD_VIDEO_FIRST_QUARTILE);
                                oneQuartile = 0;
                            } else if (midPoint && stream.time > midPoint && stream.time < thirdQuartile) {
                                triggerEvent(AdEvent.AD_VIDEO_MIDPOINT);
                                midPoint = 0;
                            } else if (stream.time > thirdQuartile) {
                                triggerEvent(AdEvent.AD_VIDEO_THIRD_QUARTILE);
                                thirdQuartile = 0;
                                clearInterval(progressEventCheck);
                            }
                        }, 500);
                    };
                } else if (event.info.code == "NetStream.Play.Stop") {
                    triggerEvent(AdEvent.AD_VIDEO_COMPLETE);
                    triggerEvent(AdEvent.AD_STOPPED);
                    adEnd();
                } else if (event.info.code == "NetStream.Play.StreamNotFound") {
                    triggerEvent(AdEvent.AD_ERROR);
                    adEnd();
                }
            });

            // pause/play ad on click, plus fire a ClickThru event on unpaused clicks
            vastAd.addEventListener(MouseEvent.CLICK, function (event:MouseEvent):void {
                if (!isPaused) {
                    triggerEvent(AdEvent.AD_CLICK_THRU);

                    stream.togglePause();
                    isPaused = true;

                    triggerEvent(AdEvent.AD_PAUSED);

                    // TODO XXX using the zero index isn't a good idea
                    var clickThru:URLRequest = new URLRequest(vastResponse.ads[adSequenceId].creatives[0].source.videoClicks.clickThrough.uri);
                    navigateToURL(clickThru, "_blank");
                } else {
                    stream.resume();
                    isPaused = false;

                    triggerEvent(AdEvent.AD_PLAYING);
                }
            });

            var adVideo:Video = createVideoObject(mediaFile.width, mediaFile.height);

            // TODO adjust placement to center on x,y axis; will appear top-left until then
            vastAd.addChild(adVideo);

            // start VAST playback
            adVideo.attachNetStream(stream);
            stream.play(mediaFile.uri);

            triggerEvent(AdEvent.AD_LOADED);
        }


        // creates Video object for playback
        // stretches video width to fit stage, stretching height to maintain aspect ratio while staying vertically centered
        function createVideoObject(width:Number, height:Number):Video {
            var videoScale:Number = stage.stageWidth / width;
            var adVideo:Video = new Video(width * videoScale, height * videoScale);

            adVideo.y = (stage.stageHeight - (height * videoScale)) / 2;

            // TODO XXX horizontal scaling if video's aspect ratio doesn't fit vertically

            return adVideo;
        }


        // find MediaFile asset with ideal, not-too-small & not-too-big resolution
        private function getVideoCreative(mediaFiles:*):MediaFile {
            var bestIndex:Number = 0;

            for (var i:* in mediaFiles) {
                if (mediaFiles[i].width > mediaFiles[bestIndex].width) {
                    if (mediaFiles[i].width <= stage.stageWidth && mediaFiles[i].height <= stage.stageHeight) {
                        bestIndex = i;
                    }
                }
            }

            return mediaFiles[bestIndex];
        }


        private function initVPAID(mediaFile:MediaFile, adParameters:String):void {
            triggerEvent("AdLoading");
            var loader:Loader = new Loader();

            var loaderContext:LoaderContext = new LoaderContext();
            loaderContext.applicationDomain = ApplicationDomain.currentDomain;
            loaderContext.securityDomain = SecurityDomain.currentDomain;

            loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, function (event:UncaughtErrorEvent):void {
                var errorType:String = event.error.type || event.error.name;
                var errorText:String = event.error.text || event.error.message;

                log("vpaidjs: [unhandled exception] " + errorType + ": " + errorText);

                event.preventDefault();
                event.stopImmediatePropagation();
            });

            loader.contentLoaderInfo.addEventListener(Event.COMPLETE, function completeHandler(event:Event):void {
                vpaidAd = loader.content;
                addChild(loader);

                initFlashAd(adParameters);
                loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, completeHandler);
            });

            loader.load(
                new URLRequest(mediaFile.uri),
                loaderContext
            );
        }


        private function adInit(adTag:String):void {
            var parser:VASTParser = new VASTParser();
            var adTagRequest:URLRequest = new URLRequest(adTag);
            var adTagRequestLoader:URLLoader = new URLLoader();


            adTagRequestLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, function(e:Event):void {
                adEnd("Cross-domain error requesting ad tag.");
            });

             adTagRequestLoader.addEventListener(IOErrorEvent.IO_ERROR, function(e:Event):void {
                adEnd("IO Error requesting ad tag.");
            });

            adTagRequestLoader.addEventListener(Event.COMPLETE, function (event:Event):void {
                try {
                    parser.setData(XML(event.currentTarget.data));
                    vastResponse = parser.parse();
                } catch (e:Error) {
                    adEnd("Error parsing VAST tag.");
                }

                if (vastResponse.ads.length) {
                    adStart(vastResponse.ads[adSequenceId]);
                } else {
                    adEnd("No ads in VAST tag.");
                }
            });

            adTagRequestLoader.load(adTagRequest);
        }


        private function adStart(ad:*):void {

            // wrapped tags should be redirected but don't forget to register their events too
            if (ad.hasOwnProperty("vastAdTagURI")) {
                registerVastEvents({}, ad.impressions, {});
                return adInit(ad.vastAdTagURI);         // XXX recursion!
            }

            if (!ad.creatives.length) {
                adEnd("No creative or wrapped tag present.");
            }

            stage.addEventListener(MouseEvent.MOUSE_OVER, function (event:MouseEvent):void {
                triggerEvent("MouseOver");
            });

            for each (var creative:Creative in ad.creatives) {
                // no support for Companion or NonLinear ads
                if (creative.source is Linear) {

                    // VAST Linear Video and wrapped VPAID ads provide additional tracking endpoints

                    registerVastEvents(creative.source.trackingEvents, ad.impressions, creative.source.videoClicks);

                    for each (var mediaFile:MediaFile in creative.source.mediaFiles) {
                        // TODO XXX does this work on multiple types?

                        // TODO determine best resolution of available `mediaFile`s
                        if (mediaFile.type.toUpperCase().indexOf("FLASH") > -1) {
                            return initVPAID(mediaFile, creative.source.adParameters);
                        } else if (mediaFile.type.toUpperCase().indexOf("VIDEO") > -1) {
                            var videoCreative:MediaFile = getVideoCreative(creative.source.mediaFiles);
                            return initVideo(videoCreative);
                        } else if (mediaFile.type.toUpperCase().indexOf("SCRIPT") > -1) {
                            // TODO XXX works but not committing to support it
                            /*
                            var vastScript:String = "" +
                                "function vpaidjsInjected_"+ new Date().getTime() +"() { " +
                                    "var jsCreative = document.createElement('script'); " +
                                    "jsCreative.type = 'text/javascript'; " +
                                    "jsCreative.src = '" + mediaFile.uri + "'; " +
                                    "document.getElementsByTagName('head')[0].appendChild(jsCreative); " +
                                "}";

                            ExternalInterface.call(vastScript);
                            */
                        } else {
                            adEnd("Invalid ad type: " + mediaFile.type);
                        }
                    }
                }
            }
        }


        // to be called after ads end *or* error; this is the way out and destroys everything in its path
        private function adEnd(arg:*=null):void {
            if (vpaidAd) {
                removeChild(vpaidAd.parent);
                vpaidAd = null;
            }

            if (vastAd) {
                removeChild(vastAd);
                vastAd = null;
            }

            if (arg is String) {
                log(arg);
            }

            // play next ad in sequence, otherwise we're all done so clean up a bit
            if (vastResponse && adSequenceId < vastResponse.ads.length-1) {
                adSequenceId++;
                vastEvents = {};

                adStart(vastResponse.ads[adSequenceId]);
            } else {
                SoundMixer.soundTransform = new SoundTransform(0);

                // wait a second to notify the js framework, tracking events can be late to fire
                setTimeout(function():void {
                    triggerEvent("AdComplete");
                }, 1000);
            }
        }


        // js bridge
        public function jsVolume(level:Number):void {
            // use AS3's lower-level method of muting sound; safer for VPAID, best way to mute VAST
            if (level == 0) {
                SoundMixer.soundTransform = new SoundTransform(0);
            } else {
                SoundMixer.soundTransform = new SoundTransform(1);
            }

            if (vpaidAd && vpaidAd.hasOwnProperty('adVolume')) {
                vpaidAd.adVolume = level;
            }

            triggerEvent(AdEvent.AD_VOLUME_CHANGE);
        }


        // js bridge
        public function jsInitAd(adTag:*):void {
            adInit(adTag);
        }


        // js bridge
        public function jsStartAd():void {
            if (vpaidAd && vpaidAd.hasOwnProperty("startAd")) {
                vpaidAd.startAd();
            }
        }


        // js bridge
        public function jsStopAd():void {
            if (vpaidAd && vpaidAd.hasOwnProperty("stopAd")) {
                vpaidAd.stopAd();
            }
        }


        // js bridge
        public function jsSkipAd():void {
            if (vpaidAd && vpaidAd.hasOwnProperty("skipAd")) {
                vpaidAd.skipAd();
            }
        }


        // js bridge
        public function jsPauseAd():void {
            if (vpaidAd && vpaidAd.hasOwnProperty("pauseAd")) {
                vpaidAd.pauseAd();
            }
        }


        // js bridge
        public function jsResumeAd():void {
            if (vpaidAd && vpaidAd.hasOwnProperty("resumeAd")) {
                vpaidAd.resumeAd();
            }
        }


        // js bridge
        public function jsExpandAd():void {
            if (vpaidAd && vpaidAd.hasOwnProperty("expandAd")) {
                vpaidAd.expandAd();
            }
        }


        // js bridge
        public function jsResizeAd(width:Number, height:Number):void {
            if (vpaidAd && vpaidAd.hasOwnProperty("resizeAd")) {
                vpaidAd.resizeAd(width, height, "normal");
            }
        }

        // js bridge
        public function jsCollapseAd():void {
            if (vpaidAd && vpaidAd.hasOwnProperty("collapseAd")) {
                vpaidAd.collapseAd();
            }
        }
    }
}
