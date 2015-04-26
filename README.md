## VPAID.js

Interact with methods and events controlling [VPAID 2.0](http://www.iab.net/media/file/VPAID_2.0_Final_04-10-2012.pdf)
video ad placements in pure Javascript. Manage and monitor your web video ads directly in-page,
rather than relying upon an overbuilt Flash video player. The goal of this framework is to provide
as near to IAB compliance as appropriate for external use.
 
### Installation

Grunt is a great tool for gathering build dependencies and putting together a predictable
environment for your builds. The pre-packaged environment from [grunt-air-sdk](https://www.npmjs.com/package/grunt-air-sdk)
makes for a very quick and easy build.

Gather all the dependencies

```
npm install
```

Build vpaidjs.swf using Flex 

```
grunt build
```

### Supported VPAID Events

  * AdLoading
  * AdLoaded
  * AdStarted
  * AdPaused
  * AdStopped
  * AdLinearChange
  * AdExpandedChange
  * AdVolumeChange
  * AdImpression
  * AdVideoStart
  * AdVideoFirstQuartile
  * AdVideoMidpoint
  * AdVideoThirdQuartile
  * AdVideoComplete
  * AdClickThru
  * AdUserAcceptInvitation
  * AdUserMinimize
  * AdUserClose
  * AdPlaying
  * AdLog
  * AdError
  * AdSkipped
  * AdSkippableStateChange
  * AdSizeChange
  * AdDurationChange
  * AdInteraction

Also, the ```AdReady```  event will be triggered when the ad placement has been loaded and is ready to start.

### Supported VPAID methods

  * initAd()
  * startAd()
  * resizeAd()
  * stopAd()
  * pauseAd()
  * resumeAd()
  * skipAd()
  * expandAd()
  * collapseAd()
  * volume()
